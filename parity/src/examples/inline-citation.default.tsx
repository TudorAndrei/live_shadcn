import {
  InlineCitation,
  InlineCitationSource,
  InlineCitationText,
} from "@upstream/ai_elements/inline-citation";

// Ported from `StorybookWeb.Examples.inline_citation_default/1`.
//
// The citation's badge and its card are a hover card, which draws nothing until
// a reader hovers. Both sides therefore show the citation and the source beside
// each other, so that what is compared is markup rather than a popup neither
// side has opened.
export default function InlineCitationDefault() {
  return (
    <div className="max-w-md space-y-3">
      <InlineCitation>
        <InlineCitationText>
          Base UI renders no element for a popover's root.
        </InlineCitationText>
      </InlineCitation>
      {/* The source's own title is an `<h4>`, and the deepest heading a preview
          page has is the `<h2>` it gives the example. Both sides carry this so
          that the two pages have the same headings, not only the same slots. */}
      <h3 className="sr-only">Source</h3>
      <InlineCitationSource
        description="The root is a state container and draws nothing of its own."
        title="Popover"
        url="https://base-ui.com/react/components/popover"
      />
    </div>
  );
}
