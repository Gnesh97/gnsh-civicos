import { call } from "../../lib/nui";

export function loadCurrentWork(filters: Record<string, unknown> = {}) {
  return call("workorder.list", { page: 1, pageSize: 25, ...filters });
}

export function selfAssign(workorderId: number, expectedVersion: number) {
  return call("workorder.selfAssign", { workorderId, expectedVersion });
}

export function updateChecklist(workorderId: number, expectedVersion: number, key: string, value: unknown) {
  return call("checklist.update", { workorderId, expectedVersion, key, value });
}

export function loadChecklist(workorderId: number) {
  return call("checklist.get", { workorderId });
}

export function loadActions(workorderId: number) {
  return call("field.actions", { workorderId });
}

export function startAction(workorderId: number, expectedVersion: number, actionKey: string) {
  return call("field.start", { workorderId, expectedVersion, actionKey });
}

export function completeAction(workorderId: number, token: string, actionKey: string, expectedVersion: number, result?: unknown) {
  return call("field.complete", { workorderId, token, actionKey, expectedVersion, result });
}
