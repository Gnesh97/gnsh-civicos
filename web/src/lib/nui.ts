import type { Result } from "../types/api";

type PendingRequest = {
  resolve: (result: Result<unknown>) => void;
  timeoutId: number;
};

const pending = new Map<string, PendingRequest>();
let sequence = 0;
const REQUEST_TIMEOUT_MS = 15_000;

const isNui = () => typeof window !== "undefined" && typeof (window as any).GetParentResourceName === "function";

export function call<T>(operation: string, payload: Record<string, unknown> = {}): Promise<Result<T>> {
  const requestId = `web-${Date.now()}-${sequence++}`;
  if (!isNui()) {
    return Promise.resolve({ ok: false, error: { code: "NUI_MOCK", message: "NUI mock mode is active." } });
  }
  return new Promise((resolve) => {
    const timeoutId = window.setTimeout(() => {
      const request = pending.get(requestId);
      if (!request) return;
      pending.delete(requestId);
      request.resolve({ ok: false, error: { code: "NUI_TIMEOUT", message: "NUI request timed out." } });
    }, REQUEST_TIMEOUT_MS);
    pending.set(requestId, { resolve: resolve as (result: Result<unknown>) => void, timeoutId });
    fetch(`https://${(window as any).GetParentResourceName()}/civicos:api`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ operation, payload, requestId }),
    }).catch(() => {
      const request = pending.get(requestId);
      if (!request) return;
      pending.delete(requestId);
      window.clearTimeout(request.timeoutId);
      resolve({ ok: false, error: { code: "NUI_TRANSPORT_FAILED", message: "NUI request failed." } });
    });
  });
}

window.addEventListener("message", (event) => {
  const message = event.data;
  if (!message || message.type !== "civicos:api:result") return;
  const request = pending.get(message.requestId);
  if (!request) return;
  pending.delete(message.requestId);
  window.clearTimeout(request.timeoutId);
  request.resolve(message.result);
});

export function close(): void {
  if (!isNui()) return;
  fetch(`https://${(window as any).GetParentResourceName()}/civicos:close`, { method: "POST", body: "{}" }).catch(() => undefined);
}
