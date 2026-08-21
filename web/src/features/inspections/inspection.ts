import { call } from "../../lib/nui";

export function create(workorderId: number, expectedVersion: number, inspectorIdentifier?: string) {
  return call("inspection.create", { workorderId, expectedVersion, inspectorIdentifier });
}

export function pass(id: number, notes?: string, metadata?: Record<string, unknown>) {
  return call("inspection.pass", { id, notes, metadata });
}

export function fail(id: number, notes?: string, metadata?: Record<string, unknown>) {
  return call("inspection.fail", { id, notes, metadata });
}

export function load(id: number) {
  return call("inspection.get", { id });
}
