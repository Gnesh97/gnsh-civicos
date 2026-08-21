import { access, readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(fileURLToPath(new URL("..", import.meta.url)));
const index = resolve(root, "web", "dist", "index.html");

await access(index);
const html = await readFile(index, "utf8");
if (!html.includes("<main id=\"root\">")) {
  throw new Error("web/dist/index.html is missing the CivicOS root mount.");
}
if (!html.includes("civicos:api")) {
  throw new Error("web/dist/index.html is missing the NUI API transport.");
}
console.log(`NUI artifact verified: ${index}`);
