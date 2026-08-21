import type { Result } from "../types/api";

const pending = new Map<string, (result: Result<unknown>) => void>();
let sequence = 0;

const isNui = () => typeof window !== "undefined" && typeof (window as any).GetParentResourceName === "function";

export function call<T>(operation: string, payload: Record<string, unknown> = {}): Promise<Result<T>> {
  const requestId = `web-${Date.now()}-${sequence++}`;
  if (!isNui()) {
    return Promise.resolve({ ok: false, error: { code: "NUI_MOCK", message: "NUI mock mode is active." } });
  }
  return new Promise((resolve) => {
    pending.set(requestId, resolve as (result: Result<unknown>) => void);
    fetch(`https://${(window as any).GetParentResourceName()}/civicos:api`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify({ operation, payload, requestId }),
    }).catch(() => {
      pending.delete(requestId);
      resolve({ ok: false, error: { code: "NUI_TRANSPORT_FAILED", message: "NUI request failed." } });
    });
  });
}

window.addEventListener("message", (event) => {
  const message = event.data;
  if (!message || message.type !== "civicos:api:result") return;
  const resolver = pending.get(message.requestId);
  if (!resolver) return;
  pending.delete(message.requestId);
  resolver(message.result);
});

export function close(): void {
  if (!isNui()) return;
  fetch(`https://${(window as any).GetParentResourceName()}/civicos:close`, { method: "POST", body: "{}" }).catch(() => undefined);
}
