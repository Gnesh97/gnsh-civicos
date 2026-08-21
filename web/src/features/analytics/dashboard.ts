import { call } from "../../lib/nui";

export type DashboardFilters = { startDate: string; endDate: string };

export function load(filters: DashboardFilters) {
  return call("analytics.dashboard", filters);
}
