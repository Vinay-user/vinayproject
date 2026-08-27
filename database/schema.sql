-- =====================================================================
-- CRM Portal — Database Schema (MySQL 8+ / MariaDB 10.4+, for XAMPP)
-- Converted from the original PostgreSQL schema.
--
-- Notable conversions from the Postgres version:
--   - No CREATE EXTENSION / pgcrypto needed (not used for anything here)
--   - Postgres CREATE TYPE ... AS ENUM  -> inline MySQL ENUM(...) columns
--   - BIGSERIAL                         -> BIGINT AUTO_INCREMENT
--   - TIMESTAMPTZ                       -> DATETIME
--   - now()                             -> CURRENT_TIMESTAMP
--   - JSONB                             -> JSON
--   - The Postgres set_updated_at() trigger loop is replaced by
--     `ON UPDATE CURRENT_TIMESTAMP` on each updated_at column
--   - All tables explicitly use ENGINE=InnoDB (required for foreign keys)
--
-- Run order: schema.sql -> indexes.sql -> seed.sql
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- teams
-- ---------------------------------------------------------------------
CREATE TABLE teams (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    description   TEXT,
    manager_id    BIGINT,                      -- FK to users, added after users table exists
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(80)  NOT NULL,
    last_name       VARCHAR(80)  NOT NULL,
    email           VARCHAR(160) NOT NULL UNIQUE,
    password        VARCHAR(255) NOT NULL,  -- plain text for now (see backend/README.md); will hold a hash later
    role            ENUM('ADMIN','MANAGER','SALES','USER','TRAINER') NOT NULL DEFAULT 'USER',
    phone           VARCHAR(30),
    avatar_url      VARCHAR(255),
    team_id         BIGINT,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at   DATETIME,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_team FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE teams
    ADD CONSTRAINT fk_teams_manager
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------
-- user_permissions (fine-grained permissions on top of role, optional)
-- ---------------------------------------------------------------------
CREATE TABLE user_permissions (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    permission  VARCHAR(100) NOT NULL,
    UNIQUE (user_id, permission),
    CONSTRAINT fk_user_permissions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------
CREATE TABLE companies (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(160) NOT NULL,
    industry       VARCHAR(100),
    website        VARCHAR(255),
    phone          VARCHAR(30),
    email          VARCHAR(160),
    address_line   VARCHAR(255),
    city           VARCHAR(100),
    state          VARCHAR(100),
    country        VARCHAR(100),
    postal_code    VARCHAR(20),
    annual_revenue DECIMAL(14,2),
    employee_count INT,
    owner_id       BIGINT,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_companies_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- contacts
-- ---------------------------------------------------------------------
CREATE TABLE contacts (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(80) NOT NULL,
    last_name     VARCHAR(80) NOT NULL,
    email         VARCHAR(160),
    phone         VARCHAR(30),
    job_title     VARCHAR(120),
    company_id    BIGINT,
    owner_id      BIGINT,
    notes         TEXT,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_contacts_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL,
    CONSTRAINT fk_contacts_owner   FOREIGN KEY (owner_id)   REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- leads
-- ---------------------------------------------------------------------
CREATE TABLE leads (
    id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
    first_name            VARCHAR(80) NOT NULL,
    last_name             VARCHAR(80) NOT NULL,
    email                 VARCHAR(160),
    phone                 VARCHAR(30),
    company               VARCHAR(160),
    source                VARCHAR(100),
    status                ENUM('NEW','CONTACTED','QUALIFIED','CONVERTED','LOST') NOT NULL DEFAULT 'NEW',
    owner_id              BIGINT,
    converted_contact_id  BIGINT,
    converted_at          DATETIME,
    notes                 TEXT,
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_leads_owner     FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_leads_converted FOREIGN KEY (converted_contact_id) REFERENCES contacts(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- deals
-- ---------------------------------------------------------------------
CREATE TABLE deals (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    title               VARCHAR(160) NOT NULL,
    company_id          BIGINT,
    contact_id          BIGINT,
    amount              DECIMAL(14,2) NOT NULL DEFAULT 0,
    currency            VARCHAR(10) NOT NULL DEFAULT 'USD',
    stage               ENUM('NEW','QUALIFICATION','PROPOSAL','NEGOTIATION','WON','LOST') NOT NULL DEFAULT 'NEW',
    probability         SMALLINT,
    expected_close_date DATE,
    closed_at           DATETIME,
    owner_id            BIGINT,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_deals_probability CHECK (probability BETWEEN 0 AND 100),
    CONSTRAINT fk_deals_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL,
    CONSTRAINT fk_deals_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE SET NULL,
    CONSTRAINT fk_deals_owner   FOREIGN KEY (owner_id)   REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- activities  (calls, emails, meetings, notes — polymorphic link)
-- ---------------------------------------------------------------------
CREATE TABLE activities (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    type             ENUM('CALL','EMAIL','MEETING','NOTE','OTHER') NOT NULL DEFAULT 'NOTE',
    subject          VARCHAR(200) NOT NULL,
    description      TEXT,
    related_to_type  ENUM('LEAD','CONTACT','COMPANY','DEAL'),
    related_to_id    BIGINT,
    owner_id         BIGINT,
    activity_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_activities_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
    -- no DB-level FK on related_to_id: it can point at different tables (leads/contacts/companies/deals);
    -- enforce that relationship in the application/service layer
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- tasks
-- ---------------------------------------------------------------------
CREATE TABLE tasks (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    title            VARCHAR(200) NOT NULL,
    description      TEXT,
    status           ENUM('TODO','IN_PROGRESS','COMPLETED','CANCELLED') NOT NULL DEFAULT 'TODO',
    priority         ENUM('LOW','MEDIUM','HIGH','URGENT') NOT NULL DEFAULT 'MEDIUM',
    due_date         DATE,
    completed_at     DATETIME,
    assigned_to      BIGINT,
    related_to_type  ENUM('LEAD','CONTACT','COMPANY','DEAL'),
    related_to_id    BIGINT,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tasks_assignee FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- calendar_events
-- ---------------------------------------------------------------------
CREATE TABLE calendar_events (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    title            VARCHAR(200) NOT NULL,
    description      TEXT,
    start_time       DATETIME NOT NULL,
    end_time         DATETIME NOT NULL,
    location         VARCHAR(255),
    owner_id         BIGINT,
    related_to_type  ENUM('LEAD','CONTACT','COMPANY','DEAL'),
    related_to_id    BIGINT,
    created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_calendar_time CHECK (end_time >= start_time),
    CONSTRAINT fk_calendar_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- calendar_event_attendees (many-to-many: events <-> users)
-- ---------------------------------------------------------------------
CREATE TABLE calendar_event_attendees (
    event_id   BIGINT NOT NULL,
    user_id    BIGINT NOT NULL,
    PRIMARY KEY (event_id, user_id),
    CONSTRAINT fk_attendees_event FOREIGN KEY (event_id) REFERENCES calendar_events(id) ON DELETE CASCADE,
    CONSTRAINT fk_attendees_user  FOREIGN KEY (user_id)  REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- communications  (email/call/sms log tied to a contact or lead)
-- ---------------------------------------------------------------------
CREATE TABLE communications (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    type         ENUM('EMAIL','CALL','SMS','MEETING') NOT NULL,
    direction    ENUM('INBOUND','OUTBOUND') NOT NULL,
    subject      VARCHAR(200),
    content      TEXT,
    contact_id   BIGINT,
    lead_id      BIGINT,
    owner_id     BIGINT,
    occurred_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_comms_target CHECK (contact_id IS NOT NULL OR lead_id IS NOT NULL),
    CONSTRAINT fk_comms_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE SET NULL,
    CONSTRAINT fk_comms_lead    FOREIGN KEY (lead_id)    REFERENCES leads(id) ON DELETE SET NULL,
    CONSTRAINT fk_comms_owner   FOREIGN KEY (owner_id)   REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------
CREATE TABLE notifications (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    title       VARCHAR(160) NOT NULL,
    message     VARCHAR(500) NOT NULL,
    type        ENUM('INFO','SUCCESS','WARNING','ERROR') NOT NULL DEFAULT 'INFO',
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    read_at     DATETIME,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- settings  (per-user application preferences)
-- ---------------------------------------------------------------------
CREATE TABLE user_settings (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id       BIGINT NOT NULL,
    setting_key   VARCHAR(100) NOT NULL,
    setting_value TEXT,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (user_id, setting_key),
    CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- system_settings  (org-wide / global preferences, e.g. admin Settings page)
-- ---------------------------------------------------------------------
CREATE TABLE system_settings (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    setting_key   VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    updated_by    BIGINT,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_system_settings_user FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- refresh_tokens  (for JWT refresh-token auth flow)
-- ---------------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token       VARCHAR(500) NOT NULL UNIQUE,
    expires_at  DATETIME NOT NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- courses  (IT training module: catalog of courses offered)
-- ---------------------------------------------------------------------
CREATE TABLE courses (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(160) NOT NULL,
    code           VARCHAR(30) NOT NULL UNIQUE,
    category       VARCHAR(100),           -- e.g. 'Cloud', 'DevOps', 'Full Stack', 'Data Science'
    description    TEXT,
    duration_hours INT,
    fee            DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency       VARCHAR(10) NOT NULL DEFAULT 'USD',
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- batches  (a scheduled run of a course, assigned to a trainer)
-- ---------------------------------------------------------------------
CREATE TABLE batches (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_id    BIGINT NOT NULL,
    batch_code   VARCHAR(40) NOT NULL UNIQUE,
    trainer_id   BIGINT,                  -- FK to users (a user with role TRAINER, enforced in the app layer)
    mode         ENUM('ONLINE','OFFLINE','HYBRID') NOT NULL DEFAULT 'ONLINE',
    status       ENUM('UPCOMING','ONGOING','COMPLETED','CANCELLED') NOT NULL DEFAULT 'UPCOMING',
    start_date   DATE NOT NULL,
    end_date     DATE,
    capacity     INT,
    location     VARCHAR(255),            -- venue name or meeting link
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_batches_course  FOREIGN KEY (course_id)  REFERENCES courses(id) ON DELETE CASCADE,
    CONSTRAINT fk_batches_trainer FOREIGN KEY (trainer_id) REFERENCES users(id)   ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- enrollments  (a trainee's enrollment in a batch - trainee can be an
-- existing CRM contact; if sponsored by a client IT company, company_id
-- links back to companies)
-- ---------------------------------------------------------------------
CREATE TABLE enrollments (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    batch_id            BIGINT NOT NULL,
    contact_id          BIGINT NOT NULL,
    company_id          BIGINT,           -- sponsoring/client IT company, if any
    status              ENUM('ENROLLED','IN_PROGRESS','COMPLETED','DROPPED') NOT NULL DEFAULT 'ENROLLED',
    payment_status      ENUM('PENDING','PARTIAL','PAID','REFUNDED') NOT NULL DEFAULT 'PENDING',
    fee_amount          DECIMAL(12,2),
    enrolled_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at        DATETIME,
    certificate_number  VARCHAR(60),
    notes               TEXT,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_enrollment_batch_contact UNIQUE (batch_id, contact_id),
    CONSTRAINT fk_enrollments_batch   FOREIGN KEY (batch_id)   REFERENCES batches(id)  ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- audit_logs  (optional but useful for an admin/RBAC-heavy CRM)
-- ---------------------------------------------------------------------
CREATE TABLE audit_logs (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT,
    action       VARCHAR(100) NOT NULL,      -- e.g. 'LEAD_CREATED', 'DEAL_STAGE_CHANGED'
    entity_type  VARCHAR(50),
    entity_id    BIGINT,
    metadata     JSON,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- Note: `updated_at` columns already auto-update via
-- `ON UPDATE CURRENT_TIMESTAMP` above, so no separate trigger is needed
-- (this replaces the Postgres set_updated_at() trigger + DO $$ loop).
