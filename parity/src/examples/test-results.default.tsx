import {
  TestResults,
  TestResultsContent,
  TestResultsDuration,
  TestResultsHeader,
  TestResultsProgress,
  TestResultsSummary,
} from "@upstream/ai_elements/test-results";

const SUMMARY = { total: 8, passed: 6, failed: 2, skipped: 0, duration: 1240 };

// Ported from `StorybookWeb.Examples.test_results_default/1`.
//
// Upstream puts the summary in a context and every part reads it back; here
// each part is given it, because a HEEx component has no ancestor to ask. The
// two percentages are React arithmetic there and attributes here for the same
// reason: they are computed from the summary the caller already has.
export default function TestResultsDefault() {
  return (
    <TestResults className="max-w-md" summary={SUMMARY}>
      <TestResultsHeader>
        <TestResultsSummary />
        <TestResultsDuration />
      </TestResultsHeader>
      <TestResultsContent>
        <TestResultsProgress />
      </TestResultsContent>
    </TestResults>
  );
}
