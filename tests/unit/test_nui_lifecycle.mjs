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
  assert.match(clientNui, /local operation = type\(data\) == "table" and data\.operation or nil/);
  assert.match(clientNui, /local requestId = NUI\.call\(operation, type\(data\.payload\) == "table"/);
  assert.match(clientNui, /NUI_TIMEOUT/);
  assert.match(clientNui, /SetTimeout/);
  assert.match(clientNui, /type\(operation\) ~= "string"/);
});

test("NUI stays hidden until an open message arrives", () => {
  const index = read("web/dist/index.html");

  assert.match(index, /:root\s*\{[^}]*background:\s*transparent/);
  assert.doesNotMatch(index, /<meta\s+name="color-scheme"/);
  assert.doesNotMatch(index, /color-scheme:\s*dark/);
  assert.match(index, /html\s*\{[^}]*display:\s*none/);
  assert.match(index, /html\.civicos-visible\s*\{[^}]*display:\s*block/);
  assert.match(index, /document\.documentElement\.classList\.toggle\('civicos-visible'/);
  assert.match(index, /NUI_TIMEOUT/);
  assert.match(index, /setTimeout/);
  assert.match(index, /clearTimeout/);
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
  assert.match(index, /result\?\.error \|\| \{\}/);
  assert.match(index, /refreshRequests\(\)/);
  assert.match(index, /document\.getElementById\('request-form'\)\.reset\(\)/);
  assert.match(index, /document\.addEventListener\('keydown'/);
});

test("staff NUI exposes server-authorized request and work-order actions", () => {
  const index = read("web/dist/index.html");

  assert.match(index, /id="operations"/);
  assert.match(index, /request\.transition/);
  assert.match(index, /workorder\.convert/);
  assert.match(index, /workorder\.list/);
  assert.match(index, /workorder\.selfAssign/);
  assert.match(index, /workorder\.transition/);
  assert.match(index, /data-version/);
  assert.match(index, /request\.triage/);
  assert.match(index, /workorder\.update\.assigned/);
});

test("NUI requests fail closed when no server response arrives", () => {
  const nui = read("web/src/lib/nui.ts");

  assert.match(nui, /NUI_TIMEOUT/);
  assert.match(nui, /setTimeout/);
  assert.match(nui, /clearTimeout/);
});
