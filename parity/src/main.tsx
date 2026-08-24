import { StrictMode, type ComponentType } from "react";
import { createRoot } from "react-dom/client";

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
const Example = examples[`${component}.${id}`];

const root = createRoot(document.getElementById("root")!);

if (Example) {
  root.render(
    <StrictMode>
      <div id={`preview-${component}-${id}`} data-preview={component}>
        <Example />
      </div>
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
