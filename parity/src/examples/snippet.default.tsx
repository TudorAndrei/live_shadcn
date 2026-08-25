import {
  Snippet,
  SnippetAddon,
  SnippetCopyButton,
  SnippetInput,
  SnippetText,
} from "@upstream/ai_elements/snippet";

// Ported from `StorybookWeb.Examples.snippet_default/1`.
//
// Neither side gives the copy button an icon, so both draw the default:
// `isCopied ? CheckIcon : CopyIcon`. React draws the branch it is in and
// unmounts the other; the generated component draws both and hides the one the
// browser is not in, which `measure.mjs` skips for exactly this reason.
export default function SnippetDefault() {
  return (
    <Snippet className="max-w-md" code="mix ui.add accordion">
      <SnippetAddon align="inline-start">
        <SnippetText>$</SnippetText>
      </SnippetAddon>
      <SnippetInput aria-label="The command" />
      <SnippetAddon align="inline-end">
        <SnippetCopyButton variant="ghost" />
      </SnippetAddon>
    </Snippet>
  );
}
