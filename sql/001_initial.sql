CREATE TABLE IF NOT EXISTS civicos_requests (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    reference VARCHAR(40) NOT NULL,
    source VARCHAR(32) NOT NULL,
    source_resource VARCHAR(80) NULL,
    external_ref VARCHAR(160) NULL,
    requester_identifier VARCHAR(160) NULL,
    category VARCHAR(80) NOT NULL,
    subcategory VARCHAR(80) NULL,
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(24) NOT NULL DEFAULT 'normal',
    status VARCHAR(32) NOT NULL DEFAULT 'draft',
    department_id BIGINT UNSIGNED NULL,
    location_json JSON NOT NULL,
    metadata JSON NULL,
    version INT NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_requests_reference (reference)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_request_comments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_id BIGINT UNSIGNED NOT NULL,
    author_identifier VARCHAR(160) NOT NULL,
    visibility VARCHAR(24) NOT NULL DEFAULT 'public',
    body TEXT NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_civicos_request_comments_request FOREIGN KEY (request_id) REFERENCES civicos_requests(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_request_activity (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_id BIGINT UNSIGNED NOT NULL,
    actor_identifier VARCHAR(160) NULL,
    activity_type VARCHAR(48) NOT NULL,
    public_data JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_civicos_request_activity_request FOREIGN KEY (request_id) REFERENCES civicos_requests(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_departments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(80) NOT NULL,
    label VARCHAR(120) NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_departments_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_employees (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    persistent_identifier VARCHAR(160) NOT NULL,
    character_id VARCHAR(160) NULL,
    display_name VARCHAR(160) NOT NULL,
    framework VARCHAR(32) NOT NULL,
    department_id BIGINT UNSIGNED NULL,
    job_name VARCHAR(80) NULL,
    job_grade INT NOT NULL DEFAULT 0,
    job_grade_name VARCHAR(80) NULL,
    duty_status VARCHAR(24) NOT NULL DEFAULT 'off_duty',
    availability_status VARCHAR(24) NOT NULL DEFAULT 'offline',
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_employees_identifier (persistent_identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_workorders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    request_id BIGINT UNSIGNED NULL,
    reference VARCHAR(40) NOT NULL,
    department_id BIGINT UNSIGNED NULL,
    template_key VARCHAR(120) NOT NULL,
    priority VARCHAR(24) NOT NULL DEFAULT 'normal',
    status VARCHAR(32) NOT NULL DEFAULT 'created',
    assigned_employee_id BIGINT UNSIGNED NULL,
    assigned_crew_id BIGINT UNSIGNED NULL,
    location_json JSON NOT NULL,
    checklist_json JSON NULL,
    metadata JSON NULL,
    version INT NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_workorders_reference (reference),
    CONSTRAINT fk_civicos_workorders_request FOREIGN KEY (request_id) REFERENCES civicos_requests(id),
    CONSTRAINT fk_civicos_workorders_employee FOREIGN KEY (assigned_employee_id) REFERENCES civicos_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_workorder_assignments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    workorder_id BIGINT UNSIGNED NOT NULL,
    employee_id BIGINT UNSIGNED NULL,
    crew_id BIGINT UNSIGNED NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    assigned_by_identifier VARCHAR(160) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    released_at DATETIME(3) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_civicos_assignments_workorder FOREIGN KEY (workorder_id) REFERENCES civicos_workorders(id),
    CONSTRAINT fk_civicos_assignments_employee FOREIGN KEY (employee_id) REFERENCES civicos_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_workorder_dependencies (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    workorder_id BIGINT UNSIGNED NOT NULL,
    depends_on_workorder_id BIGINT UNSIGNED NOT NULL,
    dependency_type VARCHAR(32) NOT NULL DEFAULT 'blocks',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_workorder_dependency (workorder_id, depends_on_workorder_id),
    CONSTRAINT fk_civicos_dependency_workorder FOREIGN KEY (workorder_id) REFERENCES civicos_workorders(id),
    CONSTRAINT fk_civicos_dependency_parent FOREIGN KEY (depends_on_workorder_id) REFERENCES civicos_workorders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_notifications (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    recipient_identifier VARCHAR(160) NOT NULL,
    notification_type VARCHAR(48) NOT NULL,
    title_key VARCHAR(160) NOT NULL,
    body_key VARCHAR(160) NOT NULL,
    payload JSON NULL,
    read_at DATETIME(3) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_sla_events (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entity_type VARCHAR(32) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    milestone VARCHAR(48) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'pending',
    due_at DATETIME(3) NOT NULL,
    met_at DATETIME(3) NULL,
    breached_at DATETIME(3) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_inspections (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    workorder_id BIGINT UNSIGNED NOT NULL,
    inspector_identifier VARCHAR(160) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    notes TEXT NULL,
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT fk_civicos_inspections_workorder FOREIGN KEY (workorder_id) REFERENCES civicos_workorders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_evidence (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    entity_type VARCHAR(32) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    evidence_type VARCHAR(32) NOT NULL,
    provider VARCHAR(80) NOT NULL,
    url TEXT NOT NULL,
    metadata JSON NULL,
    created_by_identifier VARCHAR(160) NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_audit_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    actor_identifier VARCHAR(160) NULL,
    actor_type VARCHAR(32) NOT NULL DEFAULT 'player',
    entity_type VARCHAR(32) NOT NULL,
    entity_id BIGINT UNSIGNED NULL,
    action VARCHAR(48) NOT NULL,
    before_json JSON NULL,
    after_json JSON NULL,
    correlation_id VARCHAR(120) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_outbox (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_name VARCHAR(160) NOT NULL,
    event_version INT NOT NULL DEFAULT 1,
    payload JSON NOT NULL,
    correlation_id VARCHAR(120) NULL,
    attempts INT NOT NULL DEFAULT 0,
    next_attempt_at DATETIME(3) NULL,
    delivered_at DATETIME(3) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_idempotency (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    scope_key VARCHAR(160) NOT NULL,
    idempotency_key VARCHAR(160) NOT NULL,
    request_hash VARCHAR(128) NOT NULL,
    response_json JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expires_at DATETIME(3) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_idempotency (scope_key, idempotency_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
