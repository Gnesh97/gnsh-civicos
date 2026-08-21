import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const ROOT = resolve(import.meta.dirname, "../..");
const read = (relative) => readFileSync(resolve(ROOT, relative), "utf8");

function tableBody(source, tableName) {
  const start = source.search(new RegExp(`\\b${tableName}\\s*=\\s*\\{`));
  assert.notEqual(start, -1, `missing Lua table: ${tableName}`);
  let index = source.indexOf("{", start) + 1;
  let depth = 1;
  while (depth > 0 && index < source.length) {
    if (source[index] === "{") depth += 1;
    if (source[index] === "}") depth -= 1;
    index += 1;
  }
  return source.slice(source.indexOf("{", start) + 1, index - 1);
}

function enumValues(source, tableName) {
  return new Set(
    [...tableBody(source, tableName).matchAll(/\b[A-Z][A-Z0-9_]*\s*=\s*["']([^"']+)/g)].map(
      ([, value]) => value,
    ),
  );
}

function assertSetEqual(actual, expected, label) {
  assert.deepEqual([...actual].sort(), [...expected].sort(), label);
}

const enums = read("shared/enums.lua");
const constants = read("shared/constants.lua");

test("request and work-order lifecycles are complete", () => {
  assertSetEqual(
    enumValues(enums, "RequestStatus"),
    new Set([
      "draft", "submitted", "triaged", "accepted", "rejected", "duplicate", "on_hold",
      "converted", "in_progress", "resolved", "closed", "reopened", "waiting_external", "cancelled",
    ]),
    "RequestStatus",
  );
  assertSetEqual(
    enumValues(enums, "WorkOrderStatus"),
    new Set([
      "created", "unassigned", "assigned", "acknowledged", "declined", "reassigned", "en_route",
      "on_scene", "working", "blocked", "on_hold", "pending_inspection", "completed", "failed",
      "rework_required", "closed", "cancelled",
    ]),
    "WorkOrderStatus",
  );
});

test("operational enums remain a single source", () => {
  const expected = {
    Priority: ["low", "normal", "high", "urgent", "critical"],
    DutyStatus: ["off_duty", "on_duty", "unavailable"],
    AvailabilityStatus: ["available", "busy", "away", "offline"],
    InspectionStatus: ["not_required", "pending", "passed", "failed", "rework_required"],
    SlaStatus: ["pending", "met", "breached", "paused", "cancelled"],
  };
  for (const [name, values] of Object.entries(expected)) {
    assertSetEqual(enumValues(enums, name), new Set(values), name);
  }
});

test("core constants and coding rules exist", () => {
  assert.match(constants, /CIVICOS_VERSION/);
  assert.match(constants, /REFERENCE_PREFIX/);
  assert.match(constants, /UTC/);
  const rules = read("docs/spec/CODING_RULES.md").toLowerCase();
  assert.match(rules, /magic string/);
  assert.match(rules, /state machine/);
});

test("ADR and permission artifacts exist", () => {
  const adrFiles = readdirSync(resolve(ROOT, "docs/spec")).filter((file) => /^ADR-\d{3}-.+\.md$/.test(file));
  assert.equal(adrFiles.length, 5);
  assert.ok(read("docs/spec/PERMISSION_MATRIX.md"));
  const permissions = read("config/permissions.lua");
  for (const role of ["CITIZEN", "TECHNICIAN", "DISPATCHER", "SUPERVISOR", "DEPARTMENT_ADMIN", "SYSTEM_ADMIN"]) {
    assert.match(permissions, new RegExp(`\\b${role}\\b`));
  }
});

test("result and error contracts exist", () => {
  const result = read("server/core/result.lua");
  const errors = read("shared/errors.lua");
  assert.match(result, /Result\.ok/);
  assert.match(result, /Result\.err/);
  assert.match(errors, /DOMAIN_REASON/);
  assert.match(errors, /INTERNAL_ERROR/);
});
