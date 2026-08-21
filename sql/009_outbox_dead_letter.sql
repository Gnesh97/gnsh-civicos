ALTER TABLE civicos_outbox
    ADD COLUMN dead_lettered_at DATETIME(3) NULL AFTER delivered_at;

CREATE INDEX idx_civicos_outbox_dead_letter
    ON civicos_outbox (dead_lettered_at, delivered_at, next_attempt_at);
