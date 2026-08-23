import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as liveBase } from "live_base";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ...liveBase },
});

liveSocket.connect();

// Handy in the console: liveSocket.enableDebug(), liveSocket.enableLatencySim(1000).
window.liveSocket = liveSocket;
