import { call } from "../../lib/nui";

export type NotificationItem = {
  id: number;
  type: string;
  title: string;
  body: string;
  payload?: Record<string, unknown>;
  readAt?: string;
  createdAt: string;
};

export function loadInbox(unreadOnly = false) {
  return call<{ items: NotificationItem[]; page: number; pageSize: number; total: number }>("notification.list", {
    unreadOnly,
    page: 1,
    pageSize: 50,
  });
}

export function markRead(id: number) {
  return call("notification.read", { id });
}
