import {
  Terminal,
  TerminalActions,
  TerminalClearButton,
  TerminalContent,
  TerminalCopyButton,
  TerminalHeader,
  TerminalStatus,
  TerminalTitle,
} from "@upstream/ai_elements/terminal";

const OUTPUT = "Compiling 4 files (.ex)";

// Ported from `StorybookWeb.Examples.terminal_default/1`.
//
// The output carries the escape codes a program writes for colour. Upstream
// turns them into spans with `ansi-to-react`; the reviewed port names the
// job — `LiveAiElements.Ansi` — and the application chooses what sits behind it,
// which is the same seam the markdown renderer gets.
//
// Composed rather than left to draw itself, on both sides. Upstream's two
// header buttons are an icon each and no words, and the example names them.
export default function TerminalDefault() {
  return (
    <Terminal className="max-w-md" onClear={() => undefined} output={OUTPUT}>
      <TerminalHeader>
        <TerminalTitle />
        <div className="flex items-center gap-1">
          <TerminalStatus />
          <TerminalActions>
            <TerminalCopyButton aria-label="Copy the output" />
            <TerminalClearButton aria-label="Clear the output" />
          </TerminalActions>
        </div>
      </TerminalHeader>
      <TerminalContent />
    </Terminal>
  );
}
