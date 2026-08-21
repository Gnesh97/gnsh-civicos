ALTER TABLE civicos_workorder_assignments
    ADD COLUMN reason VARCHAR(255) NULL AFTER assigned_by_identifier;
