import { Sources, SourcesContent, SourcesTrigger } from "@upstream/ai_elements/sources";

// Ported from `StorybookWeb.Examples.sources_default/1`.
//
// The links are written out on both sides rather than composed with `<Source>`:
// that part renders an `<a>` with an icon and a title, and the storybook example
// asks for three plain links. Both sides ask for the same thing.
export default function SourcesDefault() {
  return (
    <Sources className="max-w-80">
      <SourcesTrigger count={3}>3 sources</SourcesTrigger>
      <SourcesContent keepMounted>
        <a className="block underline" href="https://base-ui.com">
          base-ui.com
        </a>
        <a className="block underline" href="https://ui.shadcn.com">
          ui.shadcn.com
        </a>
        <a className="block underline" href="https://hexdocs.pm/phoenix_live_view">
          Phoenix LiveView
        </a>
      </SourcesContent>
    </Sources>
  );
}
