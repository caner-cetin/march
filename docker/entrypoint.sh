#!/bin/bash

TARGET_WIDTH="${VNC_WIDTH}"
TARGET_HEIGHT="${VNC_HEIGHT}"
VNC_RESOLUTION="${TARGET_WIDTH}x${TARGET_HEIGHT}"
export DISPLAY=:${VNC_DISPLAY_NUM} # Set DISPLAY for all subsequent X applications

VNC_DEPTH="24"
# just to be sure, and for clarification, this is from Docker Compose env values.
VNC_PASSWORD="${VNC_PASSWORD}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
GAME_BASEPATH="/app/game"
CUSTOM_CFG_NAME="q3config_windows.cfg" 

echo "--- Q3 VNC (with TWM) Entrypoint ---"
echo "User: $(whoami)"
echo "DISPLAY for VNC & Apps: ${DISPLAY}"
echo "Target VNC Server Resolution: ${VNC_RESOLUTION}"
echo "Target Quake 3 Resolution: ${TARGET_WIDTH}x${TARGET_HEIGHT}"
echo "noVNC Port: ${NOVNC_PORT}"
echo "Game Base Path: ${GAME_BASEPATH}"
echo "Custom CFG: ${CUSTOM_CFG_NAME}"
echo "------------------------------------"

mkdir -p "$HOME/.vnc"
echo "$VNC_PASSWORD" | tigervncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

# create xstartup file for TigerVNC
# this script is executed when a VNC session starts
cat << EOF > "$HOME/.vnc/xstartup"
#!/bin/sh

# kill any existing X session manager
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# disable screen saver and power management for the X session
xset s off -dpms

# TWM config, pretty self explanatory.
cat << TWMCONFIG > "$HOME/.twmrc"
NoTitle
NoRaiseOnMove
NoRaiseOnResize
NoRaiseOnDeiconify
NoIconifyByUnmapping
DontIconifyByUnmapping { "ioquake3.x86_64" }
ShowIconManager { } # don't show icon manager
DecorateTransients

TWMCONFIG
chmod +x "$HOME/.twmrc"

# start twm in the background to manage quake 3 window
echo "Starting Window Manager (twm)..."
twm &
TWM_PID=\$! # capture twm's PID just in case if we need it later.

echo "Launching Quake 3 via xstartup..."
echo "Target Q3 Width for exec: [${TARGET_WIDTH}]"
echo "Target Q3 Height for exec: [${TARGET_HEIGHT}]"

# this will be the main application of the xstartup script.
# if Quake 3 exits, the xstartup script (and thus the VNC session) will end.
exec ${GAME_BASEPATH}/ioquake3.x86_64 \\
    +set fs_basepath "${GAME_BASEPATH}" \\
    +set cl_renderer "opengl2" \\
    +set com_zoneMegs 128 \\     # Increased for stability
    +set r_fullscreen "0" \\     # Ensure windowed mode
    +set r_mode -1 \\            # Use custom width/height
    +set r_customwidth ${TARGET_WIDTH} \\
    +set r_customheight ${TARGET_HEIGHT} \\
    +set sensitivity 5 \\        # Example sensitivity
    +exec ${CUSTOM_CFG_NAME} \\  # Your custom binds/settings (no resolution settings here!)
    +vid_restart \\              # IMPORTANT: Apply all video settings
    +devmap q3dm17               # Load a map (or comment out to go to main menu)
EOF
chmod +x "$HOME/.vnc/xstartup"

# -geometry will set the Xvfb screen size
echo "Starting TigerVNC server on display ${DISPLAY} with geometry ${VNC_RESOLUTION}..."
tigervncserver "${DISPLAY}" \
    -geometry "${VNC_RESOLUTION}" \
    -depth "${VNC_DEPTH}" \
    -localhost no \
    -SecurityTypes VncAuth \
    -PasswordFile "$HOME/.vnc/passwd" \
    -AlwaysShared \
    -fg &
VNC_SERVER_PID=$!
echo "TigerVNC server started with PID ${VNC_SERVER_PID}."

# wait a few seconds for VNC server to be fully up
# and for xstartup to have launched Quake 3
#
# todo: figure out something better.
sleep 5 

# start websockify to bridge VNC to WebSockets
VNC_INTERNAL_PORT=$((5900 + ${VNC_DISPLAY_NUM})) # e.g., 5901 if DISPLAY=:1
echo "Starting websockify: exposing VNC display ${DISPLAY} (port ${VNC_INTERNAL_PORT}) via WebSockets on port ${NOVNC_PORT}..."
websockify --web /usr/share/novnc/ "${NOVNC_PORT}" "localhost:${VNC_INTERNAL_PORT}" &
WEBSOCKIFY_PID=$!
echo "Websockify started with PID ${WEBSOCKIFY_PID}."

# Graceful shutdown
cleanup() {
    echo "Caught signal, cleaning up..."
    # Order of killing might matter, or just try to kill all
    if kill -0 "$WEBSOCKIFY_PID" 2>/dev/null; then kill -TERM "$WEBSOCKIFY_PID"; fi
    if kill -0 "$VNC_SERVER_PID" 2>/dev/null; then kill -TERM "$VNC_SERVER_PID"; fi
    # Quake 3 and twm are children of the xstartup, which is managed by VNC_SERVER_PID
    # Killing VNC_SERVER_PID should terminate its xstartup and thus Quake3/twm.
    # If not, specific PIDs would be needed, but xstartup's 'exec' makes it simpler.
    
    # Wait for processes to actually terminate
    wait "$VNC_SERVER_PID" # Primary process to wait for
    if pidof websockify > /dev/null && [ -n "$WEBSOCKIFY_PID" ]; then wait "$WEBSOCKIFY_PID" || true; fi

    echo "Cleanup finished."
    exit 0
}

trap cleanup SIGTERM SIGINT

# Wait for the main VNC server process to exit.
# If it exits, the script will proceed to cleanup and then finish.
wait "$VNC_SERVER_PID"
echo "Entrypoint script finished."