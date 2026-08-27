import { Image } from "@upstream/ai_elements/image";

// Ported from `StorybookWeb.Examples.image_default/1`.
//
// A one-pixel PNG, so both sides draw the same picture without asking a network
// for it. `alt` is read off the rest object upstream — `props.alt` — and is an
// attribute in the reviewed port, which is what upstream's own type says
// it is.
const PIXEL =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

export default function ImageDefault() {
  return (
    <Image
      alt="A pixel the model drew"
      base64={PIXEL}
      className="size-24"
      mediaType="image/png"
      uint8Array={new Uint8Array()}
    />
  );
}
