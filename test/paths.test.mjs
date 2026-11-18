/**
 * Unit tests for the MCP server's security boundary.
 *
 * An MCP client can pass any string it likes as a note path. This is the only
 * thing standing between "read a note" and "read ~/.ssh/id_rsa". Runs with plain
 * node — no install — so CI always executes it.
 */
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { safeResolve, safeNotePath, confineTools } from "../connectors/shared/vault.mjs";

const vault = fs.mkdtempSync(path.join(os.tmpdir(), "canon-sec-"));
const outside = fs.mkdtempSync(path.join(os.tmpdir(), "canon-out-"));
fs.mkdirSync(path.join(vault, "Decisions"));
fs.writeFileSync(path.join(vault, "Decisions/ok.md"), "fine");
fs.writeFileSync(path.join(outside, "secret.txt"), "SECRET");
fs.symlinkSync(outside, path.join(vault, "escape"));
fs.symlinkSync(path.join(outside, "secret.txt"), path.join(vault, "link.md"));
fs.symlinkSync(path.join(outside, "not-yet"), path.join(vault, "dangling.md"));
fs.mkdirSync(path.join(vault, ".git"));
fs.writeFileSync(path.join(vault, ".git/config"), "url = https://token@host/x");

let pass = 0, fail = 0;
const ok = (n) => { pass++; console.log(`  \x1b[32m✓\x1b[0m ${n}`); };
const bad = (n, d) => { fail++; console.log(`  \x1b[31m✗\x1b[0m ${n}${d ? ` — ${d}` : ""}`); };
const allows = (p, n) => { try { safeResolve(vault, p); ok(n); } catch (e) { bad(n, e.message); } };
const blocks = (p, n) => { try { const r = safeResolve(vault, p); bad(n, `ALLOWED → ${r}`); } catch { ok(n); } };

console.log("\n\x1b[1mMCP path safety\x1b[0m");
allows("Decisions/ok.md",               "allows a normal note");
allows("Decisions/not-yet-written.md",  "allows a path that does not exist yet");
blocks("../../etc/passwd",              "blocks ../ traversal");
blocks("/etc/passwd",                   "blocks an absolute path");
blocks("Decisions/../../../etc/hosts",  "blocks traversal mid-path");
blocks("escape/secret.txt",             "blocks a symlinked directory pointing out");
blocks("link.md",                       "blocks a symlinked file pointing out");
blocks("",                              "blocks an empty path");
blocks(".",                             "blocks the vault root itself");
blocks("a\0b",                          "blocks a null byte");
blocks("dangling.md",                   "blocks a dangling symlink");

const noteBlocks = (p, n) => { try { safeNotePath(vault, p); bad(n, "ALLOWED"); } catch { ok(n); } };
noteBlocks(".git/config",               "note reads refuse .git/config");
noteBlocks(".obsidian/plugins/x/data.json", "note reads refuse dot-directories");

console.log("\n\x1b[1mChat bot tool confinement\x1b[0m");
const hook = confineTools(vault, ["Read", "Grep", "Glob"]);
const denied = async (tool_name, tool_input, n) =>
  ((await hook({ tool_name, tool_input }))?.hookSpecificOutput?.permissionDecision === "deny" ? ok : bad)(n);
const allowed = async (tool_name, tool_input, n) =>
  ((await hook({ tool_name, tool_input }))?.hookSpecificOutput ? bad : ok)(n);
await denied("Bash", { command: "cat ~/.ssh/id_rsa" },        "denies Bash");
await denied("WebFetch", { url: "https://example.com" },      "denies any unlisted tool");
await denied("Read", { file_path: "/etc/passwd" },            "denies Read outside the vault");
await denied("Read", { file_path: path.join(vault, ".git/config") }, "denies Read of .git/config");
await denied("Grep", { pattern: "x", path: outside },         "denies Grep outside the vault");
await denied("Glob", { pattern: "/etc/**" },                  "denies an absolute Glob pattern");
await denied("Glob", { pattern: "../**/*.md" },               "denies a Glob pattern that climbs out");
await allowed("Read", { file_path: path.join(vault, "Decisions/ok.md") }, "allows Read of a note");
await allowed("Grep", { pattern: "x" },                       "allows Grep with no path (vault root)");
await allowed("Glob", { pattern: "**/*.md", path: vault },    "allows Glob at the vault root");

fs.rmSync(vault, { recursive: true, force: true });
fs.rmSync(outside, { recursive: true, force: true });
console.log(`\n  ${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
