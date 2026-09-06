import { createServer, createConnection } from "node:net";
import {
  lstat,
  mkdir,
  readFile,
  readlink,
  readdir,
  rename,
  rm,
  stat,
  symlink,
  writeFile,
} from "node:fs/promises";
import { dirname, join, relative } from "node:path";
import { randomUUID } from "node:crypto";

const POLL_MS = 50;
const OWNER_GRACE_MS = 1_000;
const PROBE_FRAME_MAX = 512;
const PROBE_TIMEOUT_MS = 500;
const WAIT_MS = 120_000;
const HANDOFF_PREFIX = ".source-handoff-";

function pause(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function openProbe(nonce) {
  const sockets = new Set();
  const server = createServer((socket) => {
    let received = "";
    sockets.add(socket);
    socket.once("close", () => sockets.delete(socket));

    socket.on("data", (data) => {
      received += data.toString();

      if (received.length > PROBE_FRAME_MAX) {
        socket.destroy();
        return;
      }

      const newline = received.indexOf("\n");

      if (newline === -1) return;
      if (received.slice(0, newline) === nonce) socket.end(`${nonce}\n`);
      else socket.destroy();
    });
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });

  const address = server.address();

  if (!address || typeof address === "string") {
    server.close();
    throw new Error("cannot open source lease loopback probe");
  }

  let closing;

  return {
    port: address.port,
    close: () => {
      if (closing) return closing;

      closing = new Promise((resolve) => {
        server.close(() => resolve());
        server.closeAllConnections?.();
        for (const socket of sockets) socket.destroy();
      });

      return closing;
    },
  };
}

async function probeOwner(owner) {
  if (
    owner?.host !== "127.0.0.1" ||
    !Number.isInteger(owner.port) ||
    owner.port <= 0 ||
    typeof owner.nonce !== "string"
  ) {
    return false;
  }

  return new Promise((resolve) => {
    let settled = false;
    let received = "";
    const socket = createConnection({ host: owner.host, port: owner.port });

    const finish = (live) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      resolve(live);
    };

    socket.setTimeout(PROBE_TIMEOUT_MS, () => finish(false));
    socket.once("error", () => finish(false));
    socket.once("end", () => finish(false));
    socket.once("close", () => finish(false));
    socket.once("connect", () => socket.write(`${owner.nonce}\n`));
    socket.on("data", (data) => {
      received += data.toString();

      if (received.length > PROBE_FRAME_MAX) {
        finish(false);
        return;
      }

      const newline = received.indexOf("\n");
      if (newline !== -1) finish(received.slice(0, newline) === owner.nonce);
    });
  });
}

async function readOwner(path) {
  try {
    return JSON.parse(await readFile(join(path, "owner.json"), "utf8"));
  } catch {
    return null;
  }
}

function sameOwner(left, right) {
  return (
    left?.host === right?.host &&
    left?.nonce === right?.nonce &&
    left?.port === right?.port &&
    left?.token === right?.token
  );
}

async function oldEnough(path, graceMs) {
  try {
    return Date.now() - (await stat(path)).mtimeMs >= graceMs;
  } catch {
    return false;
  }
}

async function handoffProtectsOwner(path, owner, graceMs) {
  let entries;

  try {
    entries = await readdir(path);
  } catch {
    return false;
  }

  for (const entry of entries) {
    if (!entry.startsWith(HANDOFF_PREFIX)) continue;

    const marker = join(path, entry);
    let handoff;

    try {
      handoff = JSON.parse(await readFile(join(marker, "owner.json"), "utf8"));
    } catch {
      if (!(await oldEnough(marker, graceMs))) return true;
      continue;
    }

    if (sameOwner(handoff?.parent, owner) && (await probeOwner(handoff.child))) return true;
  }

  return false;
}

async function recoverDeadOwner(path, graceMs, hooks = {}) {
  const owner = await readOwner(path);

  if (owner?.host === "127.0.0.1" && Number.isInteger(owner.port) && typeof owner.nonce === "string") {
    if (await probeOwner(owner)) return false;

    if (await handoffProtectsOwner(path, owner, graceMs)) return false;

    return withTransition(path, graceMs, async () => {
      const current = await readOwner(path);

      if (!sameOwner(owner, current) || (await probeOwner(current))) return false;
      if (await handoffProtectsOwner(path, current, graceMs)) return false;

      await hooks.beforeSourceDelete?.();
      await rm(path, { force: true, recursive: true });
      return true;
    }, hooks.waitMs ?? WAIT_MS);
  }

  if (await oldEnough(path, graceMs)) {
    return withTransition(path, graceMs, async () => {
      if (!(await oldEnough(path, graceMs))) return false;
      await hooks.beforeSourceDelete?.();
      await rm(path, { force: true, recursive: true });
      return true;
    }, hooks.waitMs ?? WAIT_MS);
  }

  return false;
}

async function writeOwner(path, owner, { removeLeaseOnFailure = false } = {}) {
  const temporary = join(path, `owner-${owner.token}.json`);

  try {
    await writeFile(temporary, JSON.stringify(owner));
    await rename(temporary, join(path, "owner.json"));
  } catch (error) {
    if (removeLeaseOnFailure) await rm(path, { force: true, recursive: true });
    throw error;
  }
}

function transitionPath(path) {
  return `${path}-transition`;
}

async function recoverDeadTransition(path, graceMs) {
  const owner = await readOwner(path);

  if (owner?.host === "127.0.0.1" && Number.isInteger(owner.port) && typeof owner.nonce === "string") {
    if (await probeOwner(owner)) return false;
    const current = await readOwner(path);

    if (!sameOwner(owner, current) || (await probeOwner(current))) return false;
    await rm(path, { force: true, recursive: true });
    return true;
  }

  if (await oldEnough(path, graceMs)) {
    if (!(await oldEnough(path, graceMs))) return false;
    await rm(path, { force: true, recursive: true });
    return true;
  }

  return false;
}

async function acquireTransition(path, graceMs, waitMs) {
  const token = randomUUID();
  const nonce = randomUUID();
  const probe = await openProbe(nonce);
  const owner = { host: "127.0.0.1", nonce, port: probe.port, token };
  const deadline = Date.now() + waitMs;

  try {
    while (true) {
      try {
        await mkdir(path);
        await writeOwner(path, owner, { removeLeaseOnFailure: true });
        return { ...owner, close: probe.close };
      } catch (error) {
        if (error.code !== "EEXIST") throw error;
        if (await recoverDeadTransition(path, graceMs)) continue;
        if (Date.now() >= deadline) {
          throw new Error(
            `timed out after ${waitMs} ms waiting for source lease transition ${path}; ` +
              "stop the other verifier or remove a dead-owner transition",
          );
        }
        await pause(POLL_MS);
      }
    }
  } catch (error) {
    await probe.close();
    throw error;
  }
}

async function releaseTransition(path, transition) {
  try {
    if (sameOwner(await readOwner(path), transition)) {
      await rm(path, { force: true, recursive: true });
    }
  } finally {
    await transition.close();
  }
}

async function withTransition(path, graceMs, action, waitMs = WAIT_MS) {
  const transition = await acquireTransition(transitionPath(path), graceMs, waitMs);

  try {
    return await action();
  } finally {
    await releaseTransition(transitionPath(path), transition);
  }
}

async function beginHandoff(path, parent, child) {
  const marker = join(path, `${HANDOFF_PREFIX}${child.nonce}`);

  await mkdir(marker);

  try {
    await writeFile(join(marker, "owner.json"), JSON.stringify({ parent, child }));

    if (!sameOwner(parent, await readOwner(path)) || !(await probeOwner(child))) {
      throw new Error("verifier source lease changed before handoff");
    }

    return marker;
  } catch (error) {
    await rm(marker, { force: true, recursive: true });
    throw error;
  }
}

export async function acquireSourceLease(path, options = {}) {
  const waitMs = options.waitMs ?? WAIT_MS;
  const graceMs = options.graceMs ?? OWNER_GRACE_MS;
  const token = options.token ?? randomUUID();
  const nonce = randomUUID();
  const probe = await openProbe(nonce);
  const owner = { host: "127.0.0.1", nonce, port: probe.port, token };
  const deadline = Date.now() + waitMs;

  try {
    while (true) {
      try {
        await mkdir(path);
        await writeOwner(path, owner, { removeLeaseOnFailure: true });
        return { ...owner, close: probe.close };
      } catch (error) {
        if (error.code !== "EEXIST") throw error;
        if (await recoverDeadOwner(path, graceMs, options)) continue;
        if (Date.now() >= deadline) {
          throw new Error(
            `timed out after ${waitMs} ms waiting for source lease ${path}; ` +
              "stop the other verifier or remove a dead-owner lease",
          );
        }
        await pause(POLL_MS);
      }
    }
  } catch (error) {
    await probe.close();
    throw error;
  }
}

export async function releaseSourceLease(path, lease) {
  const token = typeof lease === "string" ? lease : lease.token;

  try {
    if ((await readOwner(path))?.token === token) {
      await rm(path, { force: true, recursive: true });
    }
  } finally {
    if (typeof lease !== "string") await lease.close();
  }
}

export async function useSourceLease(path, token, action, options = {}) {
  if (token) {
    const parent = await readOwner(path);

    if (!parent || parent.token !== token || !(await probeOwner(parent))) {
      throw new Error(`verifier source lease owner is not live for token ${token}`);
    }

    const nonce = randomUUID();
    const probe = await openProbe(nonce);
    const child = { host: "127.0.0.1", nonce, port: probe.port, token };
    let handedOff = false;
    let marker;

    const assertLease = async () => {
      const owner = await readOwner(path);

      if (
        !owner ||
        owner.token !== child.token ||
        owner.nonce !== child.nonce ||
        owner.port !== child.port ||
        !(await probeOwner(child))
      ) {
        throw new Error(`source lease handoff is not live for token ${token}`);
      }
    };

    try {
      await options.beforeHandoff?.({ parent, child });
      await withTransition(path, options.graceMs ?? OWNER_GRACE_MS, async () => {
        marker = await beginHandoff(path, parent, child);
        await options.onHandoffMarker?.({ parent, child });

        if (!sameOwner(parent, await readOwner(path)) || !(await probeOwner(child))) {
          throw new Error("verifier source lease changed before handoff");
        }

        await writeOwner(path, child);
        handedOff = true;
        await rm(marker, { force: true, recursive: true });
        marker = null;
      });
      return await action({ assertLease, signal: undefined });
    } finally {
      const owner = await readOwner(path);

      if (
        handedOff &&
          owner?.token === child.token &&
          owner.nonce === child.nonce &&
          owner.port === child.port
      ) {
        if (await probeOwner(parent)) await writeOwner(path, parent);
        else await rm(path, { force: true, recursive: true });
      }

      if (marker) await rm(marker, { force: true, recursive: true });
      await probe.close();
    }
  }

  const lease = await acquireSourceLease(path, options);

  try {
    return await action({ assertLease: async () => {}, signal: undefined });
  } finally {
    await releaseSourceLease(path, lease);
  }
}

export async function publishRelease(release, target) {
  const targetDirectory = dirname(target);
  const temporaryLink = join(targetDirectory, `.upstream-link-${randomUUID()}`);
  const linkTarget = relative(targetDirectory, release);
  await symlink(linkTarget, temporaryLink);

  try {
    const current = await lstat(target);

    if (current.isSymbolicLink()) {
      await rename(temporaryLink, target);
      return;
    }

    const legacy = join(targetDirectory, `.upstream-release-legacy-${randomUUID()}`);
    await rename(target, legacy);

    try {
      await rename(temporaryLink, target);
    } catch (error) {
      await rename(legacy, target);
      throw error;
    }
  } catch (error) {
    if (error.code === "ENOENT") {
      await rename(temporaryLink, target);
      return;
    }
    throw error;
  } finally {
    await rm(temporaryLink, { force: true });
  }
}

export async function cleanGeneratedSources(sourceDirectory, target) {
  for (const entry of await readdir(sourceDirectory)) {
    if (entry.startsWith(".upstream-staging-")) {
      await rm(join(sourceDirectory, entry), { force: true, recursive: true });
    }
  }

  let current = null;

  try {
    current = await readlink(target);
  } catch {
    // The first publication creates this link after staging is complete.
  }

  const releases =
    await Promise.all(
      (await readdir(sourceDirectory))
        .filter((entry) => entry.startsWith(".upstream-release-"))
        .map(async (entry) => ({ entry, modified: (await stat(join(sourceDirectory, entry))).mtimeMs })),
    );

  const retained = new Set([current]);

  for (const release of releases.sort((left, right) => right.modified - left.modified)) {
    if (retained.size >= 2) break;
    retained.add(release.entry);
  }

  await Promise.all(
    releases
      .filter(({ entry }) => !retained.has(entry))
      .map(({ entry }) => rm(join(sourceDirectory, entry), { force: true, recursive: true })),
  );
}

export function sourceLeasePath(parityRoot) {
  return join(parityRoot, ".source-lease");
}

export function releasePath(sourceDirectory) {
  return join(sourceDirectory, `.upstream-release-${process.pid}-${Date.now()}`);
}

export function stagingPath(sourceDirectory) {
  return join(sourceDirectory, `.upstream-staging-${process.pid}-${Date.now()}`);
}
