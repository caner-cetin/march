import RFB from "@novnc/novnc/lib/rfb";
import { VNCUIHandler } from "./ui";

class VNCConnection {
  private rfb: RFB | undefined = undefined;
  private ui: VNCUIHandler;

  constructor(private host: string = "localhost", private port: string = "6080", private password?: string) {
    this.ui = new VNCUIHandler(
      document.getElementById("vnc_screen_container") as HTMLDivElement,
      document.getElementById("status") as HTMLSpanElement,
      document.getElementById("connectButton") as HTMLButtonElement
    );

    this.setupEventListeners();
  }

  private setupEventListeners() {
    const connectButton = document.getElementById("connectButton") as HTMLButtonElement;
    connectButton.addEventListener("click", this.connect);
  }

  private getPassword(): string {
    if (this.password) return this.password;
    return (document.getElementById("password") as HTMLInputElement).value;
  }

  private connect = () => {
    if (this.rfb) {
      this.rfb.disconnect();
      this.rfb = undefined;
    }

    try {
      const url = `ws://${this.host}:${this.port}`;
      const screen = document.getElementById("vnc_screen_container") as HTMLDivElement;

      this.rfb = new RFB(screen, url, {
        credentials: { password: this.getPassword() },
      });

      this.rfb.addEventListener("connect", this.ui.handleConnect);
      this.rfb.addEventListener("disconnect", this.ui.handleDisconnect);
      this.rfb.addEventListener("credentialsrequired", this.ui.handleCredentialsRequired);
      this.rfb.addEventListener("desktopname", this.ui.handleDesktopName);

      this.rfb.scaleViewport = true;
      this.rfb.clipViewport = true;
      this.rfb.focusOnClick = true;
    } catch (exc) {
      this.ui.updateStatus(`cannot connect to game client: ${exc}`);
    }
  };

  disconnect() {
    if (this.rfb) {
      this.rfb.disconnect();
      this.rfb = undefined;
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  const vnc = new VNCConnection();
});
