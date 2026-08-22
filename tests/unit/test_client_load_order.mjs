import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const ROOT = resolve(import.meta.dirname, "../..");
const read = (relative) => readFileSync(resolve(ROOT, relative), "utf8");

function manifestBlock(source, name) {
  const match = source.match(new RegExp(`${name}\\s*\\{([\\s\\S]*?)\\n\\}`));
  assert.ok(match, `missing ${name} block`);
  return match[1];
}

test("client target adapters receive the shared Result contract", () => {
  const manifest = read("fxmanifest.lua");
  const sharedScripts = manifestBlock(manifest, "shared_scripts");
  const serverScripts = manifestBlock(manifest, "server_scripts");

  assert.match(sharedScripts, /"server\/core\/result\.lua"/);
  assert.match(serverScripts, /"config\/workorder_templates\.lua"/);
  assert.doesNotMatch(serverScripts, /"server\/core\/result\.lua"/);
  assert.ok(manifest.indexOf('"server/core/result.lua"') < manifest.indexOf("client_scripts"));
  assert.ok(manifest.indexOf('"config/workorder_templates.lua"') < manifest.indexOf('"server/services/workorder_template_service.lua"'));
});
