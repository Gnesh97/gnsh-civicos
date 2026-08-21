CREATE TABLE IF NOT EXISTS civicos_escalations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entity_type VARCHAR(32) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    severity VARCHAR(24) NOT NULL DEFAULT 'warning',
    reason VARCHAR(160) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'open',
    acknowledged_by VARCHAR(160) NULL,
    acknowledged_at DATETIME(3) NULL,
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_escalation_open (entity_type, entity_id, reason, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
