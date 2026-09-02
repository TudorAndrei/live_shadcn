import { StrictMode, type ComponentType } from "react";
import { createRoot } from "react-dom/client";

import officialExamples, { officialComponents } from "./upstream/shadcn_examples/official";
import { Toaster as ToastToaster } from "./upstream/shadcn/ui/toast";

// The storybook's style sheet, not one of this application's own. Tailwind
// emits only the utilities it finds, so two builds over two source trees would
// emit two sets of rules, and every difference `parity.spec.mjs` reported would
// be a difference between the builds rather than between the components.
//
// `storybook/assets/css/app.css` lists this directory in its `@source`, so the
// one build covers both. Run `npm run build:css` in `storybook/assets` first.
import "../../storybook/priv/static/assets/app.css";

// One file per example, named `<component>.<example>.tsx`. The name is the only
// record of what has been ported: `parity.spec.mjs` reads the same directory
// and compares it against the storybook's own list, so a component nobody
// ported is named rather than quietly skipped.
const modules = import.meta.glob<{ default: ComponentType }>("./examples/*.tsx", { eager: true });

const examples = Object.fromEntries(
  Object.entries(modules).map(([path, module]) => [
    path.replace("./examples/", "").replace(/\.tsx$/, ""),
    module.default,
  ])
);

// The same two path segments the storybook serves, so one Playwright run can
// ask both sides for the same page.
const [, , component, id] = window.location.pathname.split("/");
// A shadcn reference is valid only when the prepared pinned checkout generated
// it. A local fixture is useful for AI Elements, but it must never stand in for
// an official shadcn example that is missing from that checkout.
const exampleId = `${component}.${id}`;
const Example = officialComponents.has(component) ? officialExamples[exampleId] : examples[exampleId];

const root = createRoot(document.getElementById("root")!);

if (Example) {
  const example = <Example />;

  root.render(
    <StrictMode>
      <>
        <h1 className="sr-only">{component}</h1>
        <h2 className="sr-only">{id}</h2>
        <div
          id={`preview-${component}-${id}`}
          data-preview={component}
          data-visual-settle-ms={component === "progress" && id === "default" ? "600" : undefined}
          data-visual-actions={component === "toast" ? "" : undefined}
          data-visual-action-settle-ms={
            component === "toast" && id === "promise" ? "2200" : undefined
          }
        >
          {component === "toast" ? <ToastToaster>{example}</ToastToaster> : example}
        </div>
      </>
    </StrictMode>
  );
} else {
  // A missing example is a hole in the reference, and a blank page would read
  // as a component that renders nothing.
  document.title = "404";
  root.render(
    <pre data-missing={`${component}.${id}`}>
      no {component} example called {id}
    </pre>
  );
}
