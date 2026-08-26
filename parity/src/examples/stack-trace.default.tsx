import {
  StackTrace,
  StackTraceActions,
  StackTraceCopyButton,
  StackTraceError,
  StackTraceErrorMessage,
  StackTraceErrorType,
} from "@upstream/ai_elements/stack-trace";

const TRACE = `ArgumentError: no recipe for ai_elements/code-block
    at Mix.Tasks.Ui.Gen.one/2`;

// Ported from `StorybookWeb.Examples.stack_trace_default/1`.
//
// Upstream parses the raw trace once and puts the parts in a context; the error
// type and the message are read back out of it. A HEEx component has no
// ancestor to ask, so each part is given what it draws — and the copy button is
// given the raw trace, which is the same answer `snippet` reached.
export default function StackTraceDefault() {
  return (
    <StackTrace className="max-w-md" trace={TRACE}>
      <StackTraceError>
        <StackTraceErrorType>ArgumentError</StackTraceErrorType>
        <StackTraceErrorMessage>
          no recipe for ai_elements/code-block
        </StackTraceErrorMessage>
      </StackTraceError>
      <StackTraceActions>
        <StackTraceCopyButton aria-label="Copy the trace" />
      </StackTraceActions>
    </StackTrace>
  );
}
