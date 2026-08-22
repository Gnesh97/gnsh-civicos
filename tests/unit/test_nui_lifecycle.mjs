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
  assert.match(clientNui, /NUI:openView\("home"/);
  assert.match(clientNui, /NUI:closeView\(\)/);
  assert.match(clientNui, /CivicOS\.NUI = NUI[\s\S]*NUI:closeView\(\)/);
  assert.match(clientNui, /local function jsonSafe\(value\)/);
  assert.match(clientNui, /local function send\(message\)/);
  assert.match(clientNui, /SendNUIMessage\(jsonSafe\(message\)\)/);
  assert.match(clientNui, /local function catalogPayload\(\)/);
  assert.match(clientNui, /NUI:openView\("home", \{ catalog = catalogPayload\(\) \}\)/);
  assert.match(clientNui, /local requestId = NUI\.call\(data and data\.operation, data and data\.payload\)/);
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
  assert.match(index, /const catalogEntries = \(catalog\) =>/);
  assert.match(index, /const humanizeServiceLabel = \(service\) =>/);
  assert.match(index, /option\.textContent = humanizeServiceLabel\(service\)/);
  assert.match(index, /catalogEntries\(bootstrap\.catalog\)/);
  assert.match(index, /catalogEntries\(message\.payload\?\.catalog\)/);
  assert.match(index, /catalog\.length \? catalog : \(state\.bootstrap\?\.catalog \|\| \[\]\)/);
  assert.match(index, /message\.operation === 'bootstrap'[\s\S]*renderServices\(\)/);
  assert.match(index, /message\.operation === 'request\.create'/);
  assert.match(index, /result\?\.error\?\.message/);
  assert.match(index, /refreshRequests\(\)/);
  assert.match(index, /document\.getElementById\('request-form'\)\.reset\(\)/);
  assert.match(index, /document\.addEventListener\('keydown'/);
});
