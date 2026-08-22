import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const ROOT = resolve(import.meta.dirname, "../..");
const read = (relative) => readFileSync(resolve(ROOT, relative), "utf8");

test("CivicOS opens from the player command and closes through NUI", () => {
  const clientNui = read("client/nui.lua");

  assert.match(clientNui, /local NUI = \{/);
  assert.match(clientNui, /open = false/);
  assert.match(clientNui, /RegisterCommand\("civicos"/);
  assert.match(clientNui, /NUI:openView\("home"\)/);
  assert.match(clientNui, /NUI:closeView\(\)/);
  assert.match(clientNui, /CivicOS\.NUI = NUI[\s\S]*NUI:closeView\(\)/);
});

test("NUI stays hidden until an open message arrives", () => {
  const index = read("web/dist/index.html");

  assert.match(index, /:root\s*\{[^}]*background:\s*transparent/);
  assert.match(index, /html\s*\{[^}]*display:\s*none/);
  assert.match(index, /html\.civicos-visible\s*\{[^}]*display:\s*block/);
  assert.match(index, /document\.documentElement\.classList\.toggle\('civicos-visible'/);
  assert.match(index, /body\s*\{[^}]*display:\s*none/);
  assert.match(index, /body\.civicos-visible\s*\{[^}]*display:\s*block/);
  assert.match(index, /message\.type === 'civicos:open'/);
  assert.match(index, /message\.type === 'civicos:close'/);
  assert.match(index, /const renderServices = \(\) =>/);
  assert.match(index, /message\.operation === 'bootstrap'[\s\S]*renderServices\(\)/);
  assert.match(index, /document\.addEventListener\('keydown'/);
});
