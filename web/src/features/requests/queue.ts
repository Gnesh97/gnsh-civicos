import { call } from "../../lib/nui";
import type { Pagination, RequestListItem } from "../../types/api";

export function loadQueue(filters: Record<string, unknown> = {}) {
  return call<Pagination<RequestListItem>>("request.list", { page: 1, pageSize: 50, ...filters });
}

export function transition(requestId: number, expectedVersion: number, targetStatus: string, reason?: string) {
  return call("request.transition", { id: requestId, expectedVersion, targetStatus, reason });
}

export function convert(requestId: number, expectedVersion: number, serviceCode?: string, overrides?: Record<string, unknown>) {
  return call("workorder.convert", { requestId, expectedVersion, serviceCode, overrides });
}
