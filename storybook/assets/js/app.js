import "phoenix_html";
// `audio_player` writes media-chrome's tags — `<media-controller>`,
// `<media-play-button>` — and a custom element draws nothing until the browser
// upgrades it. Which media library an application loads is the application's
// choice; this one loads the same version `parity/` compares against.
import "media-chrome";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import "live_base";
import "live_ai_elements";
import { hooks as liveBase } from "phoenix-colocated/live_base";
import { hooks as liveAiElements } from "phoenix-colocated/live_ai_elements";
import { Nav } from "./nav";
import { OpeningPosition } from "./opening_position";
import { CheckboxTable } from "./checkbox_table";
import { ChartDemoTooltip, ChartTooltip } from "./chart_tooltip";
import { DatePickerInput } from "./date_picker_input";
import { DataTableFilter } from "./data_table";
import { SidebarPopupPlacement } from "./sidebar_popup_placement";
import { NestedDrawerMedia } from "./nested_drawer_media";
import { ShadcnCodeStreaming } from "./shadcn_code_streaming";

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    ...liveBase,
    ...liveAiElements,
    ChartDemoTooltip,
    ChartTooltip,
    CheckboxTable,
    DatePickerInput,
    DataTableFilter,
    Nav,
    NestedDrawerMedia,
    OpeningPosition,
    SidebarPopupPlacement,
    ShadcnCodeStreaming,
  },
});

liveSocket.connect();

// Handy in the console: liveSocket.enableDebug(), liveSocket.enableLatencySim(1000).
window.liveSocket = liveSocket;
