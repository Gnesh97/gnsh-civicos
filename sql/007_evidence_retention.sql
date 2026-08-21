ALTER TABLE civicos_evidence
    ADD COLUMN deleted_at DATETIME(3) NULL AFTER created_at,
    ADD COLUMN deleted_by_identifier VARCHAR(160) NULL AFTER deleted_at;

CREATE INDEX idx_civicos_evidence_entity_active
    ON civicos_evidence (entity_type, entity_id, deleted_at, created_at);
