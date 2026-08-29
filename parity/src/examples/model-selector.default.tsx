import {
  ModelSelectorLogoGroup,
  ModelSelectorName,
} from "@upstream/ai_elements/model-selector";

// Ported from `StorybookWeb.Examples.model_selector_default/1`.
//
// Nine of this component's parts wrap a command dialog, and the generated
// package writes none of them: the application composes `<.dialog>` and
// `<.command>` itself. These two are its own.
//
// The logo is left out on both sides on purpose. It loads an SVG from
// models.dev, and a comparison that waits on a network is a comparison that
// reports the network.
export default function ModelSelectorDefault() {
  return (
    <div className="flex max-w-sm items-center gap-2">
      <ModelSelectorLogoGroup />
      <ModelSelectorName>Claude Opus 4.5</ModelSelectorName>
    </div>
  );
}
