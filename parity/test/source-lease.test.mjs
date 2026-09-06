import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, readdir, readlink, rm, writeFile } from "node:fs/promises";
import { createConnection } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  acquireSourceLease,
  cleanGeneratedSources,
  publishRelease,
  releaseSourceLease,
  useSourceLease,
} from "../source-lease.mjs";

async function temporaryDirectory() {
  return mkdtemp(join(tmpdir(), "live-shadcn-source-lease-"));
}

function pause(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function splitProbe(owner) {
  return new Promise((resolve, reject) => {
    let received = "";
    const socket = createConnection({ host: owner.host, port: owner.port });

    socket.once("error", reject);
    socket.once("connect", () => {
      socket.write(owner.nonce.slice(0, 5));
      setTimeout(() => socket.write(`${owner.nonce.slice(5)}\n`), 1);
    });
    socket.on("data", (data) => {
      received += data.toString();
      if (received.includes("\n")) {
        socket.end();
        resolve(received.slice(0, received.indexOf("\n")) === owner.nonce);
      }
    });
  });
}

test("a second source lease waits for the live owner", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const first = await acquireSourceLease(lease);
  let acquired = false;

  const second = acquireSourceLease(lease, { waitMs: 1_000 }).then((owner) => {
    acquired = true;
    return owner;
  });

  await new Promise((resolve) => setTimeout(resolve, 100));
  assert.equal(acquired, false);
  await releaseSourceLease(lease, first);
  const secondOwner = await second;
  assert.equal(acquired, true);
  await releaseSourceLease(lease, secondOwner);
});

test("dead, stale, and corrupt owners are recovered", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  await mkdir(lease);
  await writeFile(
    join(lease, "owner.json"),
    JSON.stringify({ host: "127.0.0.1", nonce: "dead", port: 1, token: "dead" }),
  );

  const dead = await acquireSourceLease(lease, { graceMs: 0 });
  await releaseSourceLease(lease, dead);

  await mkdir(lease);
  await writeFile(
    join(lease, "owner.json"),
    JSON.stringify({ host: "127.0.0.1", pid: process.pid, start: "reused", token: "reused" }),
  );

  const stale = await acquireSourceLease(lease, { graceMs: 0 });
  await releaseSourceLease(lease, stale);

  await mkdir(lease);
  const missing = await acquireSourceLease(lease, { graceMs: 0 });
  await releaseSourceLease(lease, missing);
});

test("a wrong token cannot release a source lease", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const owner = await acquireSourceLease(lease);
  await releaseSourceLease(lease, "wrong-token");
  const blocked = acquireSourceLease(lease, { waitMs: 100 });
  await assert.rejects(blocked, /timed out/);
  await releaseSourceLease(lease, owner);
});

test("the verifier token must match a live nonce probe", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const owner = await acquireSourceLease(lease);
  let prepared = false;

  assert.equal(await splitProbe(owner), true);

  await useSourceLease(lease, owner.token, async () => {
    prepared = true;
  });

  assert.equal(prepared, true);

  await writeFile(
    join(lease, "owner.json"),
    JSON.stringify({ ...owner, nonce: "wrong-nonce" }),
  );

  await assert.rejects(
    useSourceLease(lease, owner.token, async () => {}),
    /owner is not live/,
  );

  await releaseSourceLease(lease, owner);
});

test("a token handoff keeps the lease through a parent death and blocked action", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const owner = await acquireSourceLease(lease);
  let releaseAction;
  const blocked = new Promise((resolve) => {
    releaseAction = resolve;
  });
  let actionReady;
  const ready = new Promise((resolve) => {
    actionReady = resolve;
  });

  const action = useSourceLease(lease, owner.token, async ({ assertLease, signal }) => {
    await assertLease();
    assert.equal(signal, undefined);
    actionReady();
    await blocked;
    await assertLease();
  });

  await ready;
  await owner.close();
  let secondAcquired = false;

  const second = acquireSourceLease(lease, { waitMs: 1_000 }).then((lease) => {
    secondAcquired = true;
    return lease;
  });

  await new Promise((resolve) => setTimeout(resolve, 100));
  assert.equal(secondAcquired, false);
  releaseAction();
  await action;
  const secondOwner = await second;
  assert.equal(secondAcquired, true);
  await releaseSourceLease(lease, secondOwner);
  await releaseSourceLease(lease, owner);
});

test("a live handoff marker blocks recovery after the parent dies", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const parent = await acquireSourceLease(lease);
  let second;
  let secondAcquired = false;
  const published = [];

  await useSourceLease(
    lease,
    parent.token,
    async () => {
      published.push("child");
    },
    {
      onHandoffMarker: async () => {
        await parent.close();
        second = acquireSourceLease(lease, { waitMs: 1_000 }).then((owner) => {
          secondAcquired = true;
          return owner;
        });
        await pause(100);
        assert.equal(secondAcquired, false);
      },
    },
  );

  const secondOwner = await second;
  published.push("waiter");
  assert.deepEqual(published, ["child", "waiter"]);
  await releaseSourceLease(lease, secondOwner);
  await releaseSourceLease(lease, parent);
});

test("a delayed handoff cannot overwrite a recovered waiter", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const parent = await acquireSourceLease(lease);
  const published = [];
  let waiter;

  await assert.rejects(
    useSourceLease(
      lease,
      parent.token,
      async () => published.push("child"),
      {
        beforeHandoff: async () => {
          await parent.close();
          waiter = await acquireSourceLease(lease, { waitMs: 1_000 });
        },
      },
    ),
    /changed before handoff/,
  );

  published.push("waiter");
  assert.deepEqual(published, ["waiter"]);
  await releaseSourceLease(lease, waiter);
  await releaseSourceLease(lease, parent);
});

test("the transition mutex prevents recovery from deleting a delayed child handoff", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const parent = await acquireSourceLease(lease);
  let continueChild;
  const childMayContinue = new Promise((resolve) => {
    continueChild = resolve;
  });
  let childValidated;
  const childIsValidated = new Promise((resolve) => {
    childValidated = resolve;
  });
  let published = false;

  const child = useSourceLease(
    lease,
    parent.token,
    async () => {
      published = true;
    },
    {
      beforeHandoff: async () => {
        childValidated();
        await childMayContinue;
      },
    },
  );

  await childIsValidated;
  await parent.close();

  let allowDelete;
  const deletionMayContinue = new Promise((resolve) => {
    allowDelete = resolve;
  });
  let recoveryReady;
  const recoveryHasTransition = new Promise((resolve) => {
    recoveryReady = resolve;
  });

  const waiter = acquireSourceLease(lease, {
    waitMs: 1_000,
    beforeSourceDelete: async () => {
      recoveryReady();
      await deletionMayContinue;
    },
  });

  await recoveryHasTransition;
  continueChild();
  await pause(100);
  assert.equal(published, false);
  allowDelete();

  const waiterOwner = await waiter;
  await assert.rejects(child, /changed before handoff/);
  assert.equal(published, false);
  await releaseSourceLease(lease, waiterOwner);
  await releaseSourceLease(lease, parent);
});

test("a token handoff restores a live parent owner", async (t) => {
  const root = await temporaryDirectory();
  const lease = join(root, ".source-lease");
  t.after(() => rm(root, { force: true, recursive: true }));

  const owner = await acquireSourceLease(lease);

  await useSourceLease(lease, owner.token, async ({ assertLease }) => {
    await assertLease();
  });

  const restored = JSON.parse(await readFile(join(lease, "owner.json"), "utf8"));
  assert.equal(restored.nonce, owner.nonce);
  assert.equal(restored.port, owner.port);
  await releaseSourceLease(lease, owner);
});

test("publication keeps a live upstream path and cleans abandoned staging", async (t) => {
  const root = await temporaryDirectory();
  const source = join(root, "src");
  const target = join(source, "upstream");
  const first = join(source, ".upstream-release-first");
  const second = join(source, ".upstream-release-second");
  const abandoned = join(source, ".upstream-staging-crashed");
  const third = join(source, ".upstream-release-third");
  t.after(() => rm(root, { force: true, recursive: true }));

  await mkdir(target, { recursive: true });
  await writeFile(join(target, "version"), "legacy");
  await mkdir(first, { recursive: true });
  await writeFile(join(first, "version"), "first");
  await publishRelease(first, target);
  assert.equal(await readlink(target), ".upstream-release-first");

  await mkdir(second);
  await writeFile(join(second, "version"), "second");
  await publishRelease(second, target);
  assert.equal(await readlink(target), ".upstream-release-second");

  await mkdir(third);
  await writeFile(join(third, "version"), "third");
  await publishRelease(third, target);
  assert.equal(await readlink(target), ".upstream-release-third");

  await mkdir(abandoned);
  await cleanGeneratedSources(source, target);
  await assert.rejects(() => readlink(abandoned), /ENOENT/);

  const releases = (await readdir(source)).filter((entry) => entry.startsWith(".upstream-release-"));
  assert.equal(releases.length, 2);
  assert.ok(releases.includes(".upstream-release-third"));
});
