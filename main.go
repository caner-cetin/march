package main

import (
	"bytes"
	"fmt"
	"log/slog"
	"net"
	"os"
	"strings"
	"time"
)

var Q3Colors = map[byte]string{
	'0': "\x1b[30m", // Black
	'1': "\x1b[31m", // Red
	'2': "\x1b[32m", // Green
	'3': "\x1b[33m", // Yellow
	'4': "\x1b[34m", // Blue
	'5': "\x1b[36m", // Cyan (ANSI Magenta is \x1b[35m, which is more purple)
	'6': "\x1b[35m", // Magenta (ANSI Magenta)
	'7': "\x1b[37m", // White
}

func PrettyPrintQ3Output(input string) string {
	var result strings.Builder
	i := 0
	n := len(input)

	currentColorApplied := false

	for i < n {
		if input[i] == '^' && i+1 < n && Q3Colors[input[i+1]] != "" {
			colorCode := input[i+1]
			ansiCode, found := Q3Colors[colorCode]
			if found {
				if currentColorApplied { // Reset before applying new color if a color was already active
					result.WriteString("\x1b[0m")
				}
				result.WriteString(ansiCode)
				currentColorApplied = true
			} else {
				// If ^ followed by an unknown character, just append them literally
				// or treat as default/reset. For now, append literally.
				result.WriteByte(input[i])
				result.WriteByte(input[i+1])
			}
			i += 2 // Skip '^' and the color digit
		} else {
			result.WriteByte(input[i])
			i++
		}
	}
	if currentColorApplied {
		result.WriteString("\x1b[0m")
	}
	return result.String()
}

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

	buffer := make([]byte, 8192)
	n, err := conn.Read(buffer)
	if err != nil {
		slog.Error("failed to read response", "error", err)
		if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
			slog.Error("read timeout: server did not respond. check RCON password and server RCON settings.")
		}
		return
	}
	responsePayload := buffer[:n]
	var serverResponse string

	printPrefix := []byte{0xFF, 0xFF, 0xFF, 0xFF, 'p', 'r', 'i', 'n', 't', '\n'}
	if bytes.HasPrefix(responsePayload, printPrefix) {
		serverResponse = string(responsePayload[len(printPrefix):])
	} else {
		genericPrefix := []byte{0xFF, 0xFF, 0xFF, 0xFF}
		if bytes.HasPrefix(responsePayload, genericPrefix) {
			serverResponse = string(responsePayload[len(genericPrefix):])
		} else {
			serverResponse = string(responsePayload)
		}
	}
	lines := strings.Split(strings.TrimSpace(serverResponse), "\n")
	fmt.Println("<<")
	for _, line := range lines {
		if strings.TrimSpace(line) != "" {
			fmt.Println(PrettyPrintQ3Output(line))
		}
	}

}
