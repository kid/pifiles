#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const file = path.resolve("node_modules/pi-memory/index.ts");

if (!fs.existsSync(file)) {
  console.warn(`[patch-pi-memory] Skipping: ${file} not found`);
  process.exit(0);
}

let text = fs.readFileSync(file, "utf8");
const replacements = new Map([
  ["@mariozechner/pi-ai", "@earendil-works/pi-ai"],
  ["@mariozechner/pi-coding-agent", "@earendil-works/pi-coding-agent"],
  ["@sinclair/typebox", "typebox"],
]);

let changed = false;
for (const [from, to] of replacements) {
  if (text.includes(from)) {
    text = text.split(from).join(to);
    changed = true;
  }
}

if (changed) {
  fs.writeFileSync(file, text);
  console.log(`[patch-pi-memory] Patched ${file}`);
} else {
  console.log(`[patch-pi-memory] No changes needed for ${file}`);
}
