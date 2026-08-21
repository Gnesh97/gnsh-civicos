export type ApiError = {
  code: string;
  message: string;
  details?: Record<string, string | number | boolean>;
};

export type Result<T> =
  | { ok: true; data: T }
  | { ok: false; error: ApiError };

export type Pagination<T> = {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
};

export type Identity = {
  displayName: string;
  role: string;
  departmentName?: string;
  departmentId?: number;
};

export type BootstrapPayload = {
  version: string;
  identity: Identity;
  permissions: string[];
  features: Record<string, boolean>;
  catalog: Array<Record<string, unknown>>;
  providerCapabilities: Record<string, unknown>;
};

export type RequestListItem = {
  id: number;
  reference: string;
  category: string;
  subcategory?: string;
  title: string;
  priority: string;
  status: string;
  departmentId?: number;
  location: { x: number; y: number; z: number };
  version: number;
};

export type WorkOrderListItem = {
  id: number;
  requestId?: number;
  reference: string;
  templateKey: string;
  priority: string;
  status: string;
  departmentId?: number;
  assignedEmployeeId?: number;
  version: number;
  location?: { x: number; y: number; z: number };
};
