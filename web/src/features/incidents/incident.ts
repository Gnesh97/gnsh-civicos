import { call } from "../../lib/nui";

export function load(requestId: number) {
  return call("incident.get", { requestId });
}
