import { CopyIcon } from "lucide-react";

import {
  Snippet,
  SnippetAddon,
  SnippetCopyButton,
  SnippetInput,
  SnippetText,
} from "@upstream/ai_elements/snippet";

// Ported from `StorybookWeb.Examples.snippet_default/1`.
//
// The copy button is given its icon rather than left to its default, because
// the storybook example gives it one. Upstream's default is
// `isCopied ? CheckIcon : CopyIcon`, an icon chosen at render, and the two
// examples have to ask for the same thing or the difference is theirs.
export default function SnippetDefault() {
  return (
    <Snippet className="max-w-md" code="mix ui.add accordion">
      <SnippetAddon align="inline-start">
        <SnippetText>$</SnippetText>
      </SnippetAddon>
      <SnippetInput aria-label="The command" />
      <SnippetAddon align="inline-end">
        <SnippetCopyButton variant="ghost">
          <CopyIcon className="size-4" />
        </SnippetCopyButton>
      </SnippetAddon>
    </Snippet>
  );
}
