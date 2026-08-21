ALTER TABLE civicos_sla_events
    ADD COLUMN warning_at DATETIME(3) NULL AFTER due_at,
    ADD COLUMN paused_at DATETIME(3) NULL AFTER breached_at,
    ADD COLUMN accumulated_pause_seconds INT NOT NULL DEFAULT 0 AFTER paused_at,
    ADD COLUMN exempt TINYINT(1) NOT NULL DEFAULT 0 AFTER accumulated_pause_seconds;

CREATE UNIQUE INDEX uq_civicos_sla_entity_milestone
    ON civicos_sla_events (entity_type, entity_id, milestone);
