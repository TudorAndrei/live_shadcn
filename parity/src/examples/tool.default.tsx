import { Tool, ToolContent, ToolHeader } from "@upstream/ai_elements/tool";

// Ported from `StorybookWeb.Examples.tool_default/1`.
//
// The disclosure recipe folds a whole collapsible into one function, so what is
// three components here is one call there: the header is `title`, the panel is
// the children, and `id` is what the trigger and the panel agree about.
//
// `type` is upstream's `tool-<name>` and the header derives the name from it.
// Passing `title` says the same thing without the prefix, which is what the
// generated component takes.
export default function ToolDefault() {
  return (
    <Tool className="max-w-md" defaultOpen>
      <ToolHeader
        state="output-available"
        title="read_spec"
        type="tool-read_spec"
      />
      <ToolContent>Read `registry/spec/ai_elements/tool.json`.</ToolContent>
    </Tool>
  );
}
