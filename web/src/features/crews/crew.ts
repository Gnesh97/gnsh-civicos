import { call } from "../../lib/nui";

export function list(departmentId?: number) {
  return call("crew.list", { departmentId });
}

export function members(crewId: number) {
  return call("crew.members", { crewId });
}

export function assign(crewId: number, workorderId: number, expectedVersion: number, reason?: string) {
  return call("crew.assign", { crewId, workorderId, expectedVersion, reason });
}
