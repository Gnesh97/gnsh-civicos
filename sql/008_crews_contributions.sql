CREATE TABLE IF NOT EXISTS civicos_crews (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    reference VARCHAR(40) NOT NULL,
    name VARCHAR(120) NOT NULL,
    department_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'active',
    leader_employee_id BIGINT UNSIGNED NOT NULL,
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_crews_reference (reference),
    CONSTRAINT fk_civicos_crews_department FOREIGN KEY (department_id) REFERENCES civicos_departments(id),
    CONSTRAINT fk_civicos_crews_leader FOREIGN KEY (leader_employee_id) REFERENCES civicos_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_crew_members (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    crew_id BIGINT UNSIGNED NOT NULL,
    employee_id BIGINT UNSIGNED NOT NULL,
    role VARCHAR(24) NOT NULL DEFAULT 'member',
    status VARCHAR(24) NOT NULL DEFAULT 'active',
    joined_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    left_at DATETIME(3) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_crew_member (crew_id, employee_id),
    CONSTRAINT fk_civicos_crew_members_crew FOREIGN KEY (crew_id) REFERENCES civicos_crews(id),
    CONSTRAINT fk_civicos_crew_members_employee FOREIGN KEY (employee_id) REFERENCES civicos_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS civicos_contributions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    workorder_id BIGINT UNSIGNED NOT NULL,
    employee_id BIGINT UNSIGNED NOT NULL,
    contribution_type VARCHAR(32) NOT NULL,
    action_key VARCHAR(80) NULL,
    duration_seconds INT NOT NULL DEFAULT 0,
    metadata JSON NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uq_civicos_contribution_event (workorder_id, employee_id, contribution_type, action_key),
    CONSTRAINT fk_civicos_contributions_workorder FOREIGN KEY (workorder_id) REFERENCES civicos_workorders(id),
    CONSTRAINT fk_civicos_contributions_employee FOREIGN KEY (employee_id) REFERENCES civicos_employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE civicos_workorders
    ADD CONSTRAINT fk_civicos_workorders_crew FOREIGN KEY (assigned_crew_id) REFERENCES civicos_crews(id);
