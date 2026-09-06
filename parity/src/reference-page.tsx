import { StrictMode, type ComponentType } from "react";

import officialExamples, {
  officialComponents,
  sonnerToastExamples,
} from "./upstream/shadcn_examples/official";
import { Toaster as ToastToaster } from "./upstream/shadcn/ui/toast";
import { Toaster as SonnerToaster } from "./upstream/shadcn/ui/sonner";
import { ThemeProvider } from "next-themes";

const modules = import.meta.glob<{ default: ComponentType }>("./examples/*.tsx", { eager: true });

const examples = Object.fromEntries(
  Object.entries(modules).map(([path, module]) => [
    path.replace("./examples/", "").replace(/\.tsx$/, ""),
    module.default,
  ])
);

export function ReferencePage({ pathname }: { pathname: string }) {
  const [, , component, id] = pathname.split("/");
  const exampleId = `${component}.${id}`;
  const Example = officialComponents.has(component) ? officialExamples[exampleId] : examples[exampleId];

  if (!Example) {
    return (
      <pre data-missing={`${component}.${id}`}>
        no {component} example called {id}
      </pre>
    );
  }

  const example = <Example />;
  const hasSonnerToaster = sonnerToastExamples.has(exampleId);

  return (
    <StrictMode>
      <>
        <h1 className="sr-only">{component}</h1>
        <h2 className="sr-only">{id}</h2>
        <div
          id={`preview-${component}-${id}`}
          data-preview={component}
          data-visual-settle-ms={component === "progress" && id === "default" ? "600" : undefined}
          data-visual-actions={
            component === "toast"
              ? ""
              : component === "message-scroller"
                ? "message-scroller"
                : component === "data-table"
                  ? "data-table"
                  : component === "date-picker"
                    ? "date-picker"
                    : undefined
          }
          data-visual-action-settle-ms={
            component === "toast" && id === "promise" ? "2200" : undefined
          }
        >
          {component === "toast" ? <ToastToaster>{example}</ToastToaster> : example}
          {hasSonnerToaster ? (
            <ThemeProvider defaultTheme="light">
              <SonnerToaster />
            </ThemeProvider>
          ) : null}
        </div>
      </>
    </StrictMode>
  );
}
