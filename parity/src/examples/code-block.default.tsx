import {
  CodeBlockActions,
  CodeBlockContainer,
  CodeBlockCopyButton,
  CodeBlockFilename,
  CodeBlockHeader,
} from "@upstream/ai_elements/code-block";

// Ported from `StorybookWeb.Examples.code_block_default/1`.
//
// The body is left out on both sides. Upstream tokenises with shiki in the
// browser and draws one token per line until it has loaded — so a screenshot of
// it is a race, and what a server can draw is the state before the race starts.
// The generated component takes those tokens as data; this example compares the
// chrome, which is the part both sides own.
export default function CodeBlockDefault() {
  return (
    <CodeBlockContainer className="max-w-md" language="shell">
      <CodeBlockHeader>
        <CodeBlockFilename>Makefile</CodeBlockFilename>
        <CodeBlockActions>
          <CodeBlockCopyButton aria-label="Copy the code" />
        </CodeBlockActions>
      </CodeBlockHeader>
    </CodeBlockContainer>
  );
}
