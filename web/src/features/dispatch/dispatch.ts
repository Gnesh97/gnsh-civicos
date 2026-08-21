import { call } from "../../lib/nui";

export function assign(workorderId: number, expectedVersion: number, employeeId: number, reason?: string) {
  return call("workorder.assign", { workorderId, expectedVersion, employeeId, reason });
}

export function loadWorkOrders(filters: Record<string, unknown> = {}) {
  return call("workorder.list", { page: 1, pageSize: 50, ...filters });
}
