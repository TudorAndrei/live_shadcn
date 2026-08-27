import {
  StackTrace,
  StackTraceActions,
  StackTraceCopyButton,
  StackTraceError,
  StackTraceErrorMessage,
  StackTraceErrorType,
  StackTraceExpandButton,
  StackTraceFrames,
  StackTraceHeader,
} from "@upstream/ai_elements/stack-trace";

const TRACE = `TypeError: Cannot read properties of undefined (reading 'slots')
    at divergence (storybook/test/browser/parity.spec.mjs:142:31)
    at compare (storybook/test/browser/measure.mjs:88:14)
    at TestFunction (node_modules/@playwright/test/lib/worker.js:184:9)
    at node:internal/process/task_queues:95:5`;

// Ported from `StorybookWeb.Examples.stack_trace_default/1`.
//
// Upstream parses the raw trace once and puts the parts in a context; the error
// type, the message and every frame are read back out of it. A HEEx component
// has no ancestor to ask, so each part is given what it draws — and this side
// is given the same string to parse, so the frames the two draw are the same
// frames or the check says which one is wrong.
//
// `onFilePathClick` is passed because the reviewed port draws the file
// path as a button that can be clicked. Without it upstream disables that
// button, which is a difference in the example rather than in the port.
//
// `defaultOpen` for the same reason: the chevron points the way the panel is,
// and the generated one is told which way to point.
export default function StackTraceDefault() {
  return (
    <StackTrace className="max-w-md" defaultOpen onFilePathClick={() => undefined} trace={TRACE}>
      <StackTraceHeader>
        <StackTraceError>
          <StackTraceErrorType>TypeError</StackTraceErrorType>
          <StackTraceErrorMessage>
            Cannot read properties of undefined (reading 'slots')
          </StackTraceErrorMessage>
        </StackTraceError>
        <StackTraceActions>
          <StackTraceCopyButton aria-label="Copy the trace" />
          <StackTraceExpandButton />
        </StackTraceActions>
      </StackTraceHeader>
      <StackTraceFrames />
    </StackTrace>
  );
}
