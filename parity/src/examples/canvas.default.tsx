import { Canvas } from "@upstream/ai_elements/canvas";

// Ported from `StorybookWeb.Examples.canvas_default/1`.
//
// React Flow pans and zooms the board and draws the pattern behind it; what the
// component is, is that box and that background. An application that wants the
// panning loads the library, the way one that wants an audio player loads
// media-chrome.
export default function CanvasDefault() {
  return <Canvas className="h-40 max-w-md border" />;
}
