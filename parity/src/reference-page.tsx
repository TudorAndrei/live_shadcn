import { StrictMode, useEffect, type ComponentType } from "react";

import officialExamples, {
  officialComponents,
  sonnerToastExamples,
} from "./upstream/shadcn_examples/official";
import { loadReferenceExample } from "./reference-loader.mjs";

const modules = import.meta.glob<{ default: ComponentType }>("./examples/*.tsx");

const examples = Object.fromEntries(
  Object.entries(modules).map(([path, load]) => [
    path.replace("./examples/", "").replace(/\.tsx$/, ""),
    () => load().then((module) => module.default),
  ])
);

export async function loadReferencePage(pathname: string) {
  const Example = await loadReferenceExample(pathname, {
    officialComponents,
    officialExamples,
    examples,
  });
  const [, , component, id] = pathname.split("/");
  // Highlighting is part of the official example's first complete paint.
  // Load its lazy grammars before reporting that the reference is ready.
  if (component === "shadcn-code-block") {
    const { loadHighlighter } = await import("../.upstream/shadcn-ui/apps/v4/registry/bases/base/lib/highlighter");
    await Promise.all(["ts", "tsx", "json", "css", "python", "text", "ansi", "bash"].map(loadHighlighter));
  }

  const ToastToaster = Example && component === "toast"
    ? (await import("./upstream/shadcn/ui/toast")).Toaster
    : undefined;
  const sonner = sonnerToastExamples.has(`${component}.${id}`)
    ? await Promise.all([import("./upstream/shadcn/ui/sonner"), import("next-themes")])
    : undefined;

  return {
    pathname,
    Example,
    ToastToaster,
    SonnerToaster: sonner?.[0].Toaster,
    ThemeProvider: sonner?.[1].ThemeProvider,
  };
}

export function ReferencePage({
  pathname,
  Example,
  ToastToaster,
  SonnerToaster,
  ThemeProvider,
}: Awaited<ReturnType<typeof loadReferencePage>>) {
  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      document.documentElement.dataset.referenceReady = "true";
    });
    return () => { cancelAnimationFrame(frame); delete document.documentElement.dataset.referenceReady; };
  }, []);
  const [, , component, id] = pathname.split("/");

  if (!Example) {
    return (
      <pre data-missing={`${component}.${id}`}>
        no {component} example called {id}
      </pre>
    );
  }

  const example = <Example />;

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
          {ToastToaster ? <ToastToaster>{example}</ToastToaster> : example}
          {SonnerToaster && ThemeProvider ? (
            <ThemeProvider defaultTheme="light">
              <SonnerToaster />
            </ThemeProvider>
          ) : null}
        </div>
      </>
    </StrictMode>
  );
}
