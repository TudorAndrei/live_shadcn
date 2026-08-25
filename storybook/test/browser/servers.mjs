// Is the thing listening on that port ours?
//
// Playwright's `reuseExistingServer` takes whatever answers, and it only checks
// that something does. That is the right default for a developer who left a
// server running, and the wrong one when the port belongs to somebody else: an
// unrelated container answering 401 on 4101 was taken for the storybook, and
// every parity test then reported its component as missing rather than as
// different. A harness that cannot tell "did not run" from "passed" is worse
// than no harness.
//
// So before any test runs, each port that is *already occupied* is asked for a
// page only our own server serves. A free port is left alone — Playwright is
// about to start the right thing on it.

const TIMEOUT = 2000;

async function reply(url) {
  const cancel = AbortSignal.timeout(TIMEOUT);

  try {
    const response = await fetch(url, { signal: cancel });
    return { status: response.status, body: await response.text() };
  } catch {
    // Nothing is listening, or it did not answer in time. Either way this is
    // not a foreign server, so Playwright starts ours and the run continues.
    return null;
  }
}

/**
 * Refuses a port held by something that is not ours.
 *
 * @param {Record<string, {port: string, path: string, expect: RegExp}>} servers
 */
export async function ours(servers) {
  const wrong = [];

  for (const [name, { port, path, expect }] of Object.entries(servers)) {
    const url = `http://127.0.0.1:${port}${path}`;
    const answer = await reply(url);

    // Free, so Playwright starts ours on it.
    if (answer === null) continue;

    if (answer.status !== 200 || !expect.test(answer.body)) {
      wrong.push(
        `  ${name} (port ${port}): ${url} answered ${answer.status}, ` +
          `and nothing matching ${expect}`,
      );
    }
  }

  if (wrong.length > 0) {
    const override = { storybook: "STORYBOOK_PORT", parity: "PARITY_PORT" };

    throw new Error(
      [
        "a port this suite needs is held by a server that is not ours:",
        "",
        ...wrong,
        "",
        "Playwright reuses whatever is already listening, so the run would have",
        "measured that server instead — and reported every component as missing",
        "rather than as different.",
        "",
        "Stop it, or choose another port:",
        "",
        ...Object.keys(servers).map((name) => `  ${override[name]}=… npm run verify`),
      ].join("\n"),
    );
  }
}
