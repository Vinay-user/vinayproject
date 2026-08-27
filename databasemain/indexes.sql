-- =====================================================================
-- CRM Portal — Indexes (MySQL / MariaDB)
-- Run after schema.sql
-- (DESC index ordering dropped for broad MariaDB compatibility — it's
-- an optimizer hint in Postgres and not needed for correctness here.)
-- =====================================================================

-- users
CREATE INDEX idx_users_team_id        ON users(team_id);
CREATE INDEX idx_users_role           ON users(role);
CREATE INDEX idx_users_is_active      ON users(is_active);

-- teams
CREATE INDEX idx_teams_manager_id     ON teams(manager_id);

-- companies
CREATE INDEX idx_companies_owner_id   ON companies(owner_id);
CREATE INDEX idx_companies_name       ON companies(name);
CREATE INDEX idx_companies_industry   ON companies(industry);

-- contacts
CREATE INDEX idx_contacts_owner_id    ON contacts(owner_id);
CREATE INDEX idx_contacts_company_id  ON contacts(company_id);
CREATE INDEX idx_contacts_email       ON contacts(email);
CREATE INDEX idx_contacts_name        ON contacts(last_name, first_name);

-- leads
CREATE INDEX idx_leads_owner_id       ON leads(owner_id);
CREATE INDEX idx_leads_status         ON leads(status);
CREATE INDEX idx_leads_email          ON leads(email);
CREATE INDEX idx_leads_created_at     ON leads(created_at);

-- deals
CREATE INDEX idx_deals_owner_id       ON deals(owner_id);
CREATE INDEX idx_deals_company_id     ON deals(company_id);
CREATE INDEX idx_deals_contact_id     ON deals(contact_id);
CREATE INDEX idx_deals_stage          ON deals(stage);
CREATE INDEX idx_deals_expected_close ON deals(expected_close_date);

-- activities (polymorphic lookups are the hot path)
CREATE INDEX idx_activities_related   ON activities(related_to_type, related_to_id);
CREATE INDEX idx_activities_owner_id  ON activities(owner_id);
CREATE INDEX idx_activities_date      ON activities(activity_date);

-- tasks
CREATE INDEX idx_tasks_assigned_to    ON tasks(assigned_to);
CREATE INDEX idx_tasks_status         ON tasks(status);
CREATE INDEX idx_tasks_priority       ON tasks(priority);
CREATE INDEX idx_tasks_due_date       ON tasks(due_date);
CREATE INDEX idx_tasks_related        ON tasks(related_to_type, related_to_id);

-- calendar_events
CREATE INDEX idx_calendar_owner_id    ON calendar_events(owner_id);
CREATE INDEX idx_calendar_start_time  ON calendar_events(start_time);
CREATE INDEX idx_calendar_related     ON calendar_events(related_to_type, related_to_id);

-- communications
CREATE INDEX idx_comms_contact_id     ON communications(contact_id);
CREATE INDEX idx_comms_lead_id        ON communications(lead_id);
CREATE INDEX idx_comms_owner_id       ON communications(owner_id);
CREATE INDEX idx_comms_occurred_at    ON communications(occurred_at);

-- notifications
CREATE INDEX idx_notifications_user_unread
    ON notifications(user_id, is_read, created_at);

-- audit_logs
CREATE INDEX idx_audit_user_id        ON audit_logs(user_id);
CREATE INDEX idx_audit_entity         ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created_at     ON audit_logs(created_at);

-- refresh_tokens
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);

-- courses
CREATE INDEX idx_courses_category    ON courses(category);
CREATE INDEX idx_courses_is_active   ON courses(is_active);

-- batches
CREATE INDEX idx_batches_course_id   ON batches(course_id);
CREATE INDEX idx_batches_trainer_id  ON batches(trainer_id);
CREATE INDEX idx_batches_status      ON batches(status);
CREATE INDEX idx_batches_start_date  ON batches(start_date);

-- enrollments
CREATE INDEX idx_enrollments_batch_id     ON enrollments(batch_id);
CREATE INDEX idx_enrollments_contact_id   ON enrollments(contact_id);
CREATE INDEX idx_enrollments_company_id   ON enrollments(company_id);
CREATE INDEX idx_enrollments_status       ON enrollments(status);
CREATE INDEX idx_enrollments_payment      ON enrollments(payment_status);
