const coverageType = "verification-state-coverage";

export function beginStateCoverage(testInfo, example, expected) {
  const coverage = { example, expected, completed: [] };
  const annotation = { type: coverageType, description: JSON.stringify(coverage) };
  testInfo.annotations.push(annotation);
  return {
    complete(state) {
      coverage.completed.push(state);
      annotation.description = JSON.stringify(coverage);
    },
  };
}

export function reportTests(report) {
  const tests = [];
  function visit(suite) {
    for (const spec of suite.specs || []) {
      for (const test of spec.tests || []) tests.push({ ...test, title: spec.title });
    }
    for (const child of suite.suites || []) visit(child);
  }
  for (const suite of report.suites || []) visit(suite);
  return tests;
}

export function completedEnvelope(report, envelope, outcome) {
  const tests = reportTests(report);
  const states = {};
  let valid = true;
  for (const test of tests) {
    for (const annotation of test.annotations || []) {
      if (annotation.type !== coverageType) continue;
      try {
        const { example, expected, completed } = JSON.parse(annotation.description);
        if (states[example] || !Array.isArray(expected) || !Array.isArray(completed)) valid = false;
        states[example] = { expected, completed };
      } catch {
        valid = false;
      }
    }
  }

  if (envelope.layer === "behavior") {
    states.__tests__ = {
      expected: tests.map((test) => test.title),
      completed: tests.filter((test) => executed(test)).map((test) => test.title),
    };
  }

  const keys = envelope.layer === "behavior"
    ? ["__tests__"]
    : (envelope.examples || []).map((example) => `${envelope.preview_key}.${example}`);
  const coverageComplete = keys.length > 0 && keys.every((key) => {
    const coverage = states[key];
    return coverage?.expected?.length > 0 &&
      JSON.stringify(coverage.expected) === JSON.stringify(coverage.completed);
  });
  const completed = envelope.completed !== false && valid && coverageComplete &&
    tests.length > 0 && tests.every(executed) && (report.errors || []).length === 0 &&
    !outcome.signal && [0, 1].includes(outcome.code);
  return { ...envelope, states, completed };
}

function executed(test) {
  const result = test.results?.at(-1);
  return result && ["passed", "failed"].includes(result.status);
}
