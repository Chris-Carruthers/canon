/**
 * vault.mjs — locating, gating and safely reading a canon vault.
 *
 * DEPENDENCY-FREE ON PURPOSE. Nothing here imports the Agent SDK, so:
 *   * the MCP server can use it without pulling in a model client at all, and
 *   * the security boundary below is unit-testable with plain `node`, no install.
 *
 * A security check you cannot run in CI without a network fetch is a security
 * check that eventually stops being run.
 */

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execFileSync } from "node:child_process";

export function die(msg) {
  console.error(`canon: ${msg}`);
  process.exit(1);
}

export function list(v) {
  return (v || "").split(/[,\s]+/).map((s) => s.trim()).filter(Boolean);
}

/**
 * Find the vault. Uses the same resolution order as the rest of canon, by
 * shelling out to canon-path where possible, so there is one definition of
 * "where is the vault" across the whole kit rather than a JS reimplementation
 * that can disagree with the shell one.
 */
export function resolveVault() {
  if (process.env.CANON_HOME) {
    const p = process.env.CANON_HOME.replace(/^~(?=$|\/)/, os.homedir());
    if (!fs.existsSync(p)) die(`CANON_HOME is set to '${p}' but that does not exist`);
    return fs.realpathSync(p);
  }
  const here = import.meta.dirname;
  for (const candidate of [
    path.resolve(here, "../../bin/canon-path"),
    path.resolve(here, "../../.canon/canon-path"),
    "canon-path",
  ]) {
    try {
      const out = execFileSync(candidate, { encoding: "utf8" }).trim();
      if (out && fs.existsSync(out)) return fs.realpathSync(out);
    } catch { /* try the next */ }
  }
  const cfg = path.join(os.homedir(), ".config/canon/path");
  if (fs.existsSync(cfg)) {
    const line = fs.readFileSync(cfg, "utf8").split("\n")
      .find((l) => l.trim() && !l.startsWith("#"));
    if (line && fs.existsSync(line.trim())) return fs.realpathSync(line.trim());
  }
  die("cannot find the vault. Set CANON_HOME, or write the path into ~/.config/canon/path");
}

/**
 * Fail-closed access control.
 *
 * These connectors BYPASS git permissions: git decides who can clone the vault,
 * the chat platform decides who is in the channel. Where those sets differ, an
 * open bot hands notes to people who were never granted access. So an empty
 * allowlist is a hard error at startup, not a permissive default.
 */
export function makeGate({ channels = [], users = [], roles = [], platform = "chat" }) {
  if (!channels.length && !users.length && !roles.length) {
    die(
      `refusing to start with no allowlist.\n` +
      `  This bot can read the whole vault, and ${platform} membership is not the same\n` +
      `  as git access. Allow specific channels, users, or roles.\n` +
      `  Use '*' for channels only if everyone who can reach this bot may read every note.`
    );
  }
  const open = channels.includes("*");
  return function allowed({ channel, user, userRoles = [] } = {}) {
    if (open) return true;
    if (channel && channels.includes(channel)) return true;
    if (user && users.includes(user)) return true;
    if (roles.length && userRoles.some((r) => roles.includes(r))) return true;
    return false;
  };
}

/** Chat platforms cap message length; truncate visibly rather than getting cut off. */
export function clip(s, limit) {
  if (!s) return "";
  return s.length > limit ? `${s.slice(0, limit - 20)}\n\n_…truncated._` : s;
}

/** A tiny JSON thread→session store. Losing it costs conversation continuity, nothing more. */
export function makeStore(file) {
  let data = {};
  try { data = JSON.parse(fs.readFileSync(file, "utf8")); } catch { /* first run */ }
  return {
    get: (k) => data[k],
    set(k, v) {
      data[k] = { ...(data[k] || {}), ...v };
      try { fs.writeFileSync(file, JSON.stringify(data, null, 2)); } catch { /* non-fatal */ }
    },
    has: (k) => Object.prototype.hasOwnProperty.call(data, k),
  };
}

/**
 * Resolve a caller-supplied relative path against the vault, refusing anything
 * that escapes it.
 *
 * This is the whole security boundary for the MCP server. An MCP client can pass
 * any string it likes, and a naive path.join happily produces
 * `../../.ssh/id_rsa`. Symlinks are the subtler version of the same hole, so we
 * resolve them before comparing — a note symlinked to /etc/passwd must not read
 * as "inside the vault".
 *
 * Returns an absolute path, or throws. Pure and dependency-free, so it is unit
 * testable without installing anything.
 */
export function safeResolve(vault, relPath) {
  if (typeof relPath !== "string" || !relPath.trim()) {
    throw new Error("path is required");
  }
  if (relPath.includes("\0")) throw new Error("invalid path");

  const root = fs.realpathSync(vault);
  const candidate = path.resolve(root, relPath);

  // Resolve symlinks on the deepest existing ancestor, then re-append the rest,
  // so a symlinked directory in the middle of the path cannot smuggle us out.
  let probe = candidate;
  const tail = [];
  for (;;) {
    if (fs.existsSync(probe)) break;
    const parent = path.dirname(probe);
    if (parent === probe) break;
    tail.unshift(path.basename(probe));
    probe = parent;
  }
  const real = path.join(fs.realpathSync(probe), ...tail);

  const rel = path.relative(root, real);
  if (rel === "" || rel.startsWith("..") || path.isAbsolute(rel)) {
    throw new Error(`path escapes the vault: ${relPath}`);
  }
  return real;
}
