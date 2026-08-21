# CivicOS S08 Vertical Slice

This is a manual in-game scenario. It is intentionally kept separate from the
automated test suite; the final verification pass should execute it against a
running FiveM server and a disposable database.

1. A citizen opens the CivicOS UI, selects `traffic_signal_failure`, submits a
   title/description, and confirms the returned request reference.
2. A dispatcher opens the queue, triages the request, accepts it, and converts
   it with the `traffic_signal_repair` work-order template.
3. The dispatcher assigns the work order to an on-duty DOT technician. A stale
   `expectedVersion` must return `CORE_VERSION_CONFLICT` without changing the
   assignment.
4. The technician self-views the assignment, travels to the server-observed
   location, and transitions `assigned → acknowledged → en_route → on_scene →
   working`.
5. The technician starts and completes `inspect`, `repair`, and `test` using
   action tokens. A replayed or too-distant completion must be rejected.
6. Required checklist values are submitted. The technician moves the work
   order to `pending_inspection`; a supervisor passes the inspection, and the
   technician completes the work order. The citizen sees the request move to
   `resolved` and then `closed` through the public timeline.
