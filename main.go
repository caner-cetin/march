package main

import (
	"bytes"
	"fmt"
	"log/slog"
	"net"
	"os"
	"time"
)

func main() {
	slog.SetLogLoggerLevel(slog.LevelDebug)
	conn, err := net.Dial("udp", "192.168.56.11:27960")
	if err != nil {
		slog.Error("cannot dial rcon", "error", err)
		return
	}
	slog.Info("dialed RCON...")
	conn.SetDeadline(time.Now().Add(5 * time.Second))

	rconPassword := os.Getenv("RCON_PASSWORD")
	commandString := fmt.Sprintf("rcon %s status", rconPassword)
	var packet bytes.Buffer
	packet.Write([]byte{0xFF, 0xFF, 0xFF, 0xFF}) // RCON prefix
	packet.WriteString(commandString)

	fmt.Printf(">> %s \n", commandString)
	_, err = conn.Write(packet.Bytes())
	if err != nil {
		slog.Error("failed to write command", "error", err)
		return
	}

	buffer := make([]byte, 4096)
	n, err := conn.Read(buffer)
	if err != nil {
		slog.Error("failed to read response", "error", err)
		if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
			slog.Error("read timeout: server did not respond. check RCON password and server RCON settings.")
		}
		return
	}
	responsePayload := buffer[:n]
	if bytes.HasPrefix(responsePayload, []byte{0xFF, 0xFF, 0xFF, 0xFF, 'p', 'r', 'i', 'n', 't', '\n'}) {
		response := string(responsePayload[10:])
		fmt.Printf("<< %s\n", response)
	} else {
		fmt.Printf("<< Raw response (hex): %x\n", responsePayload)
		fmt.Printf("<< Raw response (string): %s\n", string(responsePayload))
	}
}
