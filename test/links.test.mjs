/**
 * Every internal anchor and relative link in the markdown must resolve.
 *
 * A broken anchor is invisible until a reader clicks it, and the one this caught was
 * in the first paragraph of the front page. Uses GitHub's slug rule: lowercase, drop
 * anything that is not word/space/hyphen, then replace each space with a hyphen —
 * runs are NOT collapsed, which is exactly where the second bug hid.
 */
import fs from "node:fs";
import path from "node:path";

const files = [];
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    if (["node_modules", ".git", "assets"].includes(e.name)) continue;
    const p = path.join(d, e.name);
    e.isDirectory() ? walk(p) : e.name.endsWith(".md") && files.push(p);
  }
})(".");

const slug = (h) => h.trim().toLowerCase().replace(/[^\w\s-]/g, "").replace(/ /g, "-");
let fail = 0, checked = 0;

for (const f of files) {
  const src = fs.readFileSync(f, "utf8");
  const heads = new Set([...src.matchAll(/^#{1,6}\s+(.*)$/gm)].map((m) => slug(m[1])));
  for (const [, target] of src.matchAll(/\]\(#([^)]+)\)/g)) {
    checked++;
    if (!heads.has(target)) { console.log(`  ✗ ${f} → #${target}`); fail++; }
  }
  for (const [, link] of src.matchAll(/\]\((?!https?:\/\/|#|mailto:)([^)]+)\)/g)) {
    checked++;
    const target = path.resolve(path.dirname(f), link.split("#")[0]);
    if (!fs.existsSync(target)) { console.log(`  ✗ ${f} → ${link}`); fail++; }
  }
}
console.log(`  ${checked} link(s) checked, ${fail} broken`);
process.exit(fail ? 1 : 0);
