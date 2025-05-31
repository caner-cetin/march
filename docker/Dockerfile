# Use a base image with necessary libraries
FROM debian:bullseye-slim

LABEL maintainer="Caner Cetin (hello@cansu.dev)"
LABEL description="Quake 3 (ioquake3) in Docker with Xvfb, TigerVNC, and noVNC"

ENV DEBIAN_FRONTEND=noninteractive

# - tigervnc-standalone-server: For the VNC server itself
# - tigervnc-common: Common files for TigerVNC
# - xvfb: X Virtual FrameBuffer for headless display
# - websockify: To bridge VNC to WebSockets for noVNC
# - novnc: The HTML5 VNC client files
# - ca-certificates: For HTTPS if any tools need it
# - libgl1-mesa-glx: For OpenGL software rendering (Mesa)
#
# TODO: ALSA Drivers for IOQuake3, so we can transmit sound.
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  # VNC and Web Access
  tigervnc-standalone-server \
  tigervnc-common \
  xvfb \
  websockify \
  novnc \
  # General utilities
  ca-certificates \
  x11-utils \
  # Core ioquake3 runtime dependencies
  libgl1-mesa-glx \
  libopenal1 \
  libcurl4 \
  libjpeg62-turbo \
  libopus0 \
  libopusfile0 \
  libsdl2-2.0-0 \
  libvorbisfile3 \
  twm \
  && apt-get clean && \
  rm -rf /var/lib/apt/lists/*
ARG USERNAME=q3user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
  useradd --uid $USER_UID --gid $USER_GID --shell /bin/bash --create-home $USERNAME

WORKDIR /app

COPY Quake_III_Linux/ /app/game/
RUN chmod +x /app/game/ioquake3.x86_64 && \
  chown -R $USERNAME:$USERNAME /app/game

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

COPY q3config_windows.cfg /app/game/baseq3/q3config_windows.cfg

# Switch to the non-root user
USER $USERNAME
ENV HOME=/home/$USERNAME
ARG NOVNC_PORT=6080
EXPOSE $NOVNC_PORT
ENTRYPOINT ["/app/entrypoint.sh"]