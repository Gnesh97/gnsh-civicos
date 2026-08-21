CREATE TABLE IF NOT EXISTS civicos_employee_certifications (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    certification_key VARCHAR(120) NOT NULL,
    expires_at DATETIME(3) NULL,
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_employee_certification (employee_id, certification_key),
    CONSTRAINT fk_civicos_certification_employee FOREIGN KEY (employee_id) REFERENCES civicos_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_civicos_certifications_expiry ON civicos_employee_certifications (certification_key, expires_at);
