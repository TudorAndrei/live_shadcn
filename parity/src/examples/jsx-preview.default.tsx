import {
  JSXPreview,
  JSXPreviewContent,
} from "@upstream/ai_elements/jsx-preview";

// Ported from `StorybookWeb.Examples.jsx_preview_default/1`.
//
// Upstream compiles a string of JSX at render. A server cannot, and a template
// language that drew markup out of a string would be the injection every other
// decision here is made to avoid — so the port takes the markup itself, and
// what is compared is the two boxes around it.
export default function JsxPreviewDefault() {
  return (
    <JSXPreview className="max-w-md" jsx={'<p className="text-sm">What the model wrote, already markup.</p>'}>
      <JSXPreviewContent />
    </JSXPreview>
  );
}
