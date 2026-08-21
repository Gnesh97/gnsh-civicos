CREATE INDEX idx_civicos_outbox_retention
    ON civicos_outbox (delivered_at, dead_lettered_at, created_at);

CREATE INDEX idx_civicos_idempotency_expiry
    ON civicos_idempotency (expires_at, created_at);

CREATE INDEX idx_civicos_audit_retention
    ON civicos_audit_logs (created_at, entity_type, entity_id);

CREATE INDEX idx_civicos_evidence_retention
    ON civicos_evidence (deleted_at, created_at);
