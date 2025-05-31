import type { DesktopNameEvent, DisconnectEvent } from "@novnc/novnc";

export class VNCUIHandler {
  constructor(private screen: HTMLDivElement, private status: HTMLSpanElement, private connectButton: HTMLButtonElement) {}

  updateStatus(message: string) {
    this.status.textContent = message;
  }

  handleConnect = () => {
    this.status.textContent = "connected";
    this.status.style.color = "#00FFFF";
    this.screen.addEventListener("click", this.requestPointerLock);
  };

  handleDisconnect = (e: DisconnectEvent) => {
    const detail = e.detail || {};
    this.status.textContent = `disconnected: ${detail.clean ? detail.reason : " (unexpected)"}`;
    this.status.style.color = "#f554be";
    this.screen.removeEventListener("click", this.requestPointerLock);
  };

  handleCredentialsRequired = () => {
    this.status.textContent = "password required for connecting to game client.";
    this.status.style.color = "#f48585";
  };

  handleDesktopName = (e: DesktopNameEvent) => {
    this.status.textContent = `connected to: ${e.detail.name}`;
    this.status.style.color = "#fff";
  };

  private requestPointerLock = () => {
    this.screen
      .requestPointerLock()
      .then(() => console.log("requesting pointer lock..."))
      .catch(() => console.log("oh fuck"));
  };
}
