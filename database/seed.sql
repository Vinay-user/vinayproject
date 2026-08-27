-- =====================================================================
-- CRM Portal — Seed Data (MySQL / MariaDB)
-- Run after schema.sql and indexes.sql
-- Passwords below are bcrypt hashes of "Password123!" — replace before
-- using in anything beyond local development.
-- =====================================================================

-- ---------------------------------------------------------------------
-- teams
-- ---------------------------------------------------------------------
INSERT INTO teams (id, name, description) VALUES
    (1, 'Sales - East',  'East region sales team'),
    (2, 'Sales - West',  'West region sales team'),
    (3, 'Customer Success', 'Post-sale support and retention');

-- ---------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------
-- Passwords are plain text for now (matches the backend's current
-- no-hashing stage - see backend/README.md). All five seed accounts use
-- the password: Password123!
INSERT INTO users (id, first_name, last_name, email, password, role, phone, team_id, is_active) VALUES
    (1, 'Admin',   'User',     'admin@crmportal.com',        'Password123!', 'ADMIN',   '+1-202-555-0100', NULL, TRUE),
    (2, 'John',    'Doe',      'john.doe@crmportal.com',     'Password123!', 'MANAGER', '+1-202-555-0101', 1,    TRUE),
    (3, 'Sarah',   'Adams',    'sarah.adams@crmportal.com',  'Password123!', 'SALES',   '+1-202-555-0102', 1,    TRUE),
    (4, 'Mike',    'King',     'mike.king@crmportal.com',    'Password123!', 'SALES',   '+1-202-555-0103', 2,    TRUE),
    (5, 'Rachel',  'Brooks',   'rachel.brooks@crmportal.com','Password123!', 'USER',    '+1-202-555-0104', 3,    TRUE);

-- back-fill team managers now that users exist
UPDATE teams SET manager_id = 2 WHERE id = 1;
UPDATE teams SET manager_id = 4 WHERE id = 2;
UPDATE teams SET manager_id = 5 WHERE id = 3;

-- ---------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------
INSERT INTO companies (id, name, industry, website, phone, city, state, country, owner_id) VALUES
    (1, 'Acme Corporation',   'Manufacturing', 'https://acme.example.com',   '+1-415-555-0110', 'San Francisco', 'CA', 'USA', 2),
    (2, 'Global Industries',  'Logistics',     'https://globalind.example.com', '+1-312-555-0111', 'Chicago', 'IL', 'USA', 4),
    (3, 'Bluepeak Technologies', 'Software',   'https://bluepeak.example.com', '+1-646-555-0112', 'New York', 'NY', 'USA', 3);

-- ---------------------------------------------------------------------
-- contacts
-- ---------------------------------------------------------------------
INSERT INTO contacts (id, first_name, last_name, email, phone, job_title, company_id, owner_id) VALUES
    (1, 'Michael', 'Johnson', 'michael.johnson@acme.example.com', '+1-415-555-0120', 'VP of Operations', 1, 2),
    (2, 'Emma',    'Williams', 'emma.williams@globalind.example.com', '+1-312-555-0121', 'Procurement Lead', 2, 4),
    (3, 'Daniel',  'Lee',      'daniel.lee@bluepeak.example.com', '+1-646-555-0122', 'CTO', 3, 3);

-- ---------------------------------------------------------------------
-- leads
-- ---------------------------------------------------------------------
INSERT INTO leads (id, first_name, last_name, email, phone, company, source, status, owner_id) VALUES
    (1, 'Olivia', 'Martinez', 'olivia.martinez@example.com', '+1-702-555-0130', 'Nova Retail', 'Website',   'NEW',       3),
    (2, 'Ethan',  'Clark',    'ethan.clark@example.com',     '+1-702-555-0131', 'Clarkson LLC', 'Referral',  'CONTACTED', 4),
    (3, 'Ava',    'Rodriguez','ava.rodriguez@example.com',   '+1-702-555-0132', 'Rodriguez & Co', 'LinkedIn','QUALIFIED', 3);

-- ---------------------------------------------------------------------
-- deals
-- ---------------------------------------------------------------------
INSERT INTO deals (id, title, company_id, contact_id, amount, currency, stage, probability, expected_close_date, owner_id) VALUES
    (1, 'Acme — Annual Supply Contract', 1, 1, 45000, 'USD', 'NEGOTIATION', 70, CURRENT_DATE + INTERVAL 21 DAY, 2),
    (2, 'Global Industries — Logistics Platform', 2, 2, 32000, 'USD', 'PROPOSAL', 45, CURRENT_DATE + INTERVAL 35 DAY, 4),
    (3, 'Bluepeak — Enterprise License', 3, 3, 58000, 'USD', 'QUALIFICATION', 25, CURRENT_DATE + INTERVAL 60 DAY, 3);

-- ---------------------------------------------------------------------
-- activities  (matches the "Recent Activity" feed on the Dashboard page)
-- ---------------------------------------------------------------------
INSERT INTO activities (id, type, subject, description, related_to_type, related_to_id, owner_id, activity_date) VALUES
    (1, 'NOTE',    'John created a new deal',   'New deal opened for Acme Corporation.', 'DEAL',    1, 2, NOW() - INTERVAL 10 MINUTE),
    (2, 'NOTE',    'Sarah converted a lead',    'Lead converted for Michael Johnson.',   'CONTACT', 1, 3, NOW() - INTERVAL 35 MINUTE),
    (3, 'CALL',    'Mike completed a task',     'Follow up with client call completed.', 'DEAL',    2, 4, NOW() - INTERVAL 1 HOUR),
    (4, 'NOTE',    'Rachel added a contact',    'New contact added for Global Industries.', 'COMPANY', 2, 5, NOW() - INTERVAL 2 HOUR);

-- ---------------------------------------------------------------------
-- tasks
-- ---------------------------------------------------------------------
INSERT INTO tasks (id, title, description, status, priority, due_date, assigned_to, related_to_type, related_to_id) VALUES
    (1, 'Follow up with Acme on contract terms', 'Confirm pricing and renewal clauses.', 'IN_PROGRESS', 'HIGH',   CURRENT_DATE + INTERVAL 2 DAY, 2, 'DEAL', 1),
    (2, 'Send proposal to Global Industries',     'Include updated SLA documentation.',  'TODO',         'MEDIUM', CURRENT_DATE + INTERVAL 5 DAY, 4, 'DEAL', 2),
    (3, 'Qualify Ava Rodriguez lead',             'Schedule discovery call.',             'TODO',         'MEDIUM', CURRENT_DATE + INTERVAL 1 DAY, 3, 'LEAD', 3);

-- ---------------------------------------------------------------------
-- calendar_events
-- ---------------------------------------------------------------------
INSERT INTO calendar_events (id, title, description, start_time, end_time, location, owner_id, related_to_type, related_to_id) VALUES
    (1, 'Acme Contract Review', 'Walk through final contract terms.',
        NOW() + INTERVAL 1 DAY, NOW() + INTERVAL 1 DAY + INTERVAL 1 HOUR, 'Zoom', 2, 'DEAL', 1),
    (2, 'Discovery Call — Ava Rodriguez', 'Initial qualification call.',
        NOW() + INTERVAL 2 DAY, NOW() + INTERVAL 2 DAY + INTERVAL 30 MINUTE, 'Phone', 3, 'LEAD', 3);

INSERT INTO calendar_event_attendees (event_id, user_id) VALUES
    (1, 2), (1, 1),
    (2, 3);

-- ---------------------------------------------------------------------
-- communications
-- ---------------------------------------------------------------------
INSERT INTO communications (id, type, direction, subject, content, contact_id, owner_id, occurred_at) VALUES
    (1, 'EMAIL', 'OUTBOUND', 'Contract draft attached', 'Please review the attached draft and share feedback.', 1, 2, NOW() - INTERVAL 3 HOUR),
    (2, 'CALL',  'INBOUND',  'Pricing question', 'Client called asking about volume discounts.', 2, 4, NOW() - INTERVAL 6 HOUR);

-- ---------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------
INSERT INTO notifications (id, user_id, title, message, type, is_read) VALUES
    (1, 2, 'Deal moving stages', 'Acme — Annual Supply Contract moved to Negotiation.', 'INFO', FALSE),
    (2, 3, 'New lead assigned', 'Ava Rodriguez was assigned to you.', 'SUCCESS', FALSE),
    (3, 4, 'Task due soon', 'Send proposal to Global Industries is due in 5 days.', 'WARNING', TRUE);

-- ---------------------------------------------------------------------
-- system_settings  (defaults surfaced on the admin Settings page)
-- ---------------------------------------------------------------------
INSERT INTO system_settings (setting_key, setting_value, updated_by) VALUES
    ('company_name',        'CRM Portal Inc.', 1),
    ('default_currency',    'USD', 1),
    ('fiscal_year_start',   'January', 1),
    ('lead_auto_assignment','round_robin', 1);

-- ---------------------------------------------------------------------
-- IT Training module (courses / batches / enrollments)
-- ---------------------------------------------------------------------

-- an extra trainer user (role TRAINER)
INSERT INTO users (id, first_name, last_name, email, password, role, phone, team_id, is_active) VALUES
    (6, 'David', 'Kumar', 'david.kumar@crmportal.com', 'Password123!', 'TRAINER', '+1-202-555-0105', NULL, TRUE);

-- an extra client IT company + its contacts, alongside the existing
-- Bluepeak Technologies (id 3) which already fits "client IT company"
INSERT INTO companies (id, name, industry, website, phone, city, state, country, owner_id) VALUES
    (4, 'TechNova Solutions', 'Information Technology', 'https://technova.example.com', '+1-512-555-0140', 'Austin', 'TX', 'USA', 2);

INSERT INTO contacts (id, first_name, last_name, email, phone, job_title, company_id, owner_id) VALUES
    (4, 'Priya', 'Sharma', 'priya.sharma@example.com', '+1-737-555-0150', NULL, NULL, 3),
    (5, 'Kevin', 'Chen', 'kevin.chen@technova.example.com', '+1-512-555-0141', 'Software Engineer', 4, 2);

INSERT INTO courses (id, name, code, category, description, duration_hours, fee, currency, is_active) VALUES
    (1, 'AWS Cloud Practitioner', 'CLD-101', 'Cloud', 'Foundational AWS cloud concepts, services, and certification prep.', 40, 299.00, 'USD', TRUE),
    (2, 'Full Stack Java Development', 'FSJ-201', 'Full Stack', 'Java, Spring Boot, React, and MySQL - end to end web development.', 120, 899.00, 'USD', TRUE),
    (3, 'DevOps Engineering with Kubernetes', 'DEVOPS-301', 'DevOps', 'CI/CD pipelines, Docker, and Kubernetes for production deployments.', 80, 699.00, 'USD', TRUE);

INSERT INTO batches (id, course_id, batch_code, trainer_id, mode, status, start_date, end_date, capacity, location) VALUES
    (1, 1, 'CLD-101-JAN', 6, 'ONLINE', 'ONGOING', CURRENT_DATE - INTERVAL 10 DAY, CURRENT_DATE + INTERVAL 20 DAY, 30, 'Zoom'),
    (2, 2, 'FSJ-201-FEB', 6, 'HYBRID', 'UPCOMING', CURRENT_DATE + INTERVAL 25 DAY, CURRENT_DATE + INTERVAL 55 DAY, 25, 'Austin Training Center');

INSERT INTO enrollments (id, batch_id, contact_id, company_id, status, payment_status, fee_amount, enrolled_at) VALUES
    (1, 1, 3, 3, 'IN_PROGRESS', 'PAID',    299.00, NOW() - INTERVAL 10 DAY),
    (2, 1, 4, NULL, 'ENROLLED', 'PENDING', 299.00, NOW() - INTERVAL 8 DAY),
    (3, 2, 5, 4, 'ENROLLED',    'PARTIAL', 899.00, NOW() - INTERVAL 2 DAY);

-- Note: unlike Postgres, MySQL's InnoDB AUTO_INCREMENT counter advances
-- automatically to MAX(id)+1 whenever a row is inserted with an explicit
-- id, so no equivalent of `setval(pg_get_serial_sequence(...))` is needed.
