import { hydrateRoot } from "react-dom/client";

import { ReferencePage } from "./reference-page";

// The storybook's style sheet, not one of this application's own. Tailwind
// emits only the utilities it finds, so two builds over two source trees would
// emit two sets of rules, and every difference `parity.spec.mjs` reported would
// be a difference between the builds rather than between the components.
//
// `storybook/assets/css/app.css` lists this directory in its `@source`, so the
// one build covers both. Run `npm run build:css` in `storybook/assets` first.
import "../../storybook/priv/static/assets/app.css";

hydrateRoot(
  document.getElementById("root")!,
  <ReferencePage pathname={window.location.pathname} />
);
