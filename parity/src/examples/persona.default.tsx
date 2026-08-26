import { Persona } from "@upstream/ai_elements/persona";

// Ported from `StorybookWeb.Examples.persona_default/1`.
//
// One `<canvas>`, and the Rive runtime that paints into it is the
// application's — the same arrangement media-chrome gets, and the reason the
// markup is still markup.
export default function PersonaDefault() {
  return <Persona state="idle" />;
}
