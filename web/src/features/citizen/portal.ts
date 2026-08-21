import { call } from "../../lib/nui";
import type { BootstrapPayload, Pagination, RequestListItem, Result } from "../../types/api";

export function loadServices(): Promise<Result<Array<Record<string, unknown>>>> {
  return call<BootstrapPayload>("bootstrap").then((result): Result<Array<Record<string, unknown>>> => result.ok
    ? { ok: true, data: result.data.catalog }
    : result as Result<Array<Record<string, unknown>>>);
}

export function submitRequest(payload: Record<string, unknown>) {
  return call<{ id: number; duplicateSuggestion?: RequestListItem }>("request.create", payload);
}

export function loadOwnRequests(page = 1, pageSize = 25) {
  return call<Pagination<RequestListItem>>("request.list", { page, pageSize });
}
