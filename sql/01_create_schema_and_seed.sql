/* ============================================================
   TELECOM CONTRACTOR OPERATIONS ANALYTICS
   Synthetic Portfolio Database

   All companies, people, contacts, sites, assets, contracts
   and SLA values in this script are fictional.
   ============================================================ */


/* ============================================================
   1. DROP EXISTING TABLES
   Child tables first because of foreign-key dependencies
   ============================================================ */

DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS task_templates;
DROP TABLE IF EXISTS ticket_comments;
DROP TABLE IF EXISTS ticket_events;
DROP TABLE IF EXISTS ticket_assignments;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS sla_rules;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS sites;
DROP TABLE IF EXISTS contracts;
DROP TABLE IF EXISTS contractors;
DROP TABLE IF EXISTS ticket_statuses;
DROP TABLE IF EXISTS priorities;


/* ============================================================
   2. CONTRACTORS
   ============================================================ */

CREATE TABLE contractors (
    contractor_id SERIAL PRIMARY KEY,
    contractor_code VARCHAR(30) UNIQUE NOT NULL,
    contractor_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(120),
    contact_email VARCHAR(150),
    contact_phone VARCHAR(50),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/* ============================================================
   3. CONTRACTS
   ============================================================ */

CREATE TABLE contracts (
    contract_id SERIAL PRIMARY KEY,
    contractor_id INT NOT NULL,
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    contract_name VARCHAR(150) NOT NULL,
    contract_type VARCHAR(80),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    contract_status VARCHAR(30) NOT NULL,

    FOREIGN KEY (contractor_id)
        REFERENCES contractors(contractor_id)
);


/* ============================================================
   4. SITES
   ============================================================ */

CREATE TABLE sites (
    site_id SERIAL PRIMARY KEY,
    site_code VARCHAR(30) UNIQUE NOT NULL,
    site_name VARCHAR(120) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    location_class VARCHAR(30) NOT NULL,
    active BOOLEAN DEFAULT TRUE
);


/* ============================================================
   5. ASSETS
   ============================================================ */

CREATE TABLE assets (
    asset_id SERIAL PRIMARY KEY,
    asset_code VARCHAR(50) UNIQUE NOT NULL,
    asset_name VARCHAR(150) NOT NULL,
    asset_type VARCHAR(100) NOT NULL,

    site_id INT NOT NULL,
    contract_id INT NOT NULL,

    operational_status VARCHAR(30) DEFAULT 'Active',

    FOREIGN KEY (site_id)
        REFERENCES sites(site_id),

    FOREIGN KEY (contract_id)
        REFERENCES contracts(contract_id)
);


/* ============================================================
   6. PRIORITIES
   ============================================================ */

CREATE TABLE priorities (
    priority_id SERIAL PRIMARY KEY,
    priority_name VARCHAR(20) UNIQUE NOT NULL,
    priority_rank INT UNIQUE NOT NULL
);


/* ============================================================
   7. TICKET STATUSES
   ============================================================ */

CREATE TABLE ticket_statuses (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(30) UNIQUE NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE
);


/* ============================================================
   8. SLA RULES
   ============================================================ */

CREATE TABLE sla_rules (
    sla_rule_id SERIAL PRIMARY KEY,
    contract_id INT NOT NULL,
    priority_id INT NOT NULL,
    location_class VARCHAR(30) NOT NULL,

    response_target_minutes INT NOT NULL,
    resolution_target_minutes INT NOT NULL,

    FOREIGN KEY (contract_id)
        REFERENCES contracts(contract_id),

    FOREIGN KEY (priority_id)
        REFERENCES priorities(priority_id),

    UNIQUE (
        contract_id,
        priority_id,
        location_class
    )
);


/* ============================================================
   9. TICKETS
   Current state of each ticket
   ============================================================ */

CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(30) UNIQUE NOT NULL,

    title VARCHAR(200) NOT NULL,
    description TEXT,

    category VARCHAR(100),
    source VARCHAR(50),

    status_id INT NOT NULL,
    priority_id INT NOT NULL,

    site_id INT,
    asset_id INT,
    contract_id INT,
    current_contractor_id INT,

    created_at TIMESTAMP NOT NULL,
    first_response_at TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,

    FOREIGN KEY (status_id)
        REFERENCES ticket_statuses(status_id),

    FOREIGN KEY (priority_id)
        REFERENCES priorities(priority_id),

    FOREIGN KEY (site_id)
        REFERENCES sites(site_id),

    FOREIGN KEY (asset_id)
        REFERENCES assets(asset_id),

    FOREIGN KEY (contract_id)
        REFERENCES contracts(contract_id),

    FOREIGN KEY (current_contractor_id)
        REFERENCES contractors(contractor_id)
);


/* ============================================================
   10. TICKET ASSIGNMENTS
   Assignment and reassignment history
   ============================================================ */

CREATE TABLE ticket_assignments (
    assignment_id SERIAL PRIMARY KEY,

    ticket_id INT NOT NULL,
    contractor_id INT NOT NULL,

    assigned_at TIMESTAMP NOT NULL,
    accepted_at TIMESTAMP,
    ended_at TIMESTAMP,

    assignment_status VARCHAR(30) NOT NULL,
    assignment_reason VARCHAR(200),
    reassignment_reason VARCHAR(200),

    FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id),

    FOREIGN KEY (contractor_id)
        REFERENCES contractors(contractor_id)
);


/* ============================================================
   11. TICKET EVENTS
   ============================================================ */

CREATE TABLE ticket_events (
    event_id SERIAL PRIMARY KEY,

    ticket_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,

    old_value TEXT,
    new_value TEXT,

    event_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    performed_by VARCHAR(100),

    FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id)
);


/* ============================================================
   12. TICKET COMMENTS
   ============================================================ */

CREATE TABLE ticket_comments (
    comment_id SERIAL PRIMARY KEY,

    ticket_id INT NOT NULL,
    author_type VARCHAR(30),
    author_name VARCHAR(120),

    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id)
);


/* ============================================================
   13. TASK TEMPLATES
   Recurring contractual obligations
   ============================================================ */

CREATE TABLE task_templates (
    template_id SERIAL PRIMARY KEY,

    contract_id INT NOT NULL,

    task_name VARCHAR(150) NOT NULL,
    task_type VARCHAR(80),

    frequency VARCHAR(30) NOT NULL,
    due_days INT NOT NULL,

    active BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (contract_id)
        REFERENCES contracts(contract_id)
);


/* ============================================================
   14. TASKS
   Actual task instances
   ============================================================ */

CREATE TABLE tasks (
    task_id SERIAL PRIMARY KEY,

    template_id INT,
    contract_id INT NOT NULL,
    contractor_id INT NOT NULL,

    task_period VARCHAR(20),

    created_at TIMESTAMP NOT NULL,
    due_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,

    task_status VARCHAR(30) NOT NULL,
    completion_notes TEXT,

    FOREIGN KEY (template_id)
        REFERENCES task_templates(template_id),

    FOREIGN KEY (contract_id)
        REFERENCES contracts(contract_id),

    FOREIGN KEY (contractor_id)
        REFERENCES contractors(contractor_id)
);


/* ============================================================
   15. INSERT CONTRACTORS
   Fictional data
   ============================================================ */

INSERT INTO contractors (
    contractor_code,
    contractor_name,
    contact_person,
    contact_email,
    contact_phone
)
VALUES
(
    'VEN-A',
    'Northstar Network Services',
    'Daniel Brooks',
    'daniel.brooks@example.com',
    '+1-202-555-0101'
),
(
    'VEN-B',
    'BluePeak Systems',
    'Laura Mitchell',
    'laura.mitchell@example.com',
    '+1-202-555-0102'
),
(
    'VEN-C',
    'Vertex Security Operations',
    'Michael Turner',
    'michael.turner@example.com',
    '+1-202-555-0103'
),
(
    'VEN-D',
    'Atlas Infrastructure Support',
    'Emma Collins',
    'emma.collins@example.com',
    '+1-202-555-0104'
);


/* ============================================================
   16. INSERT CONTRACTS
   ============================================================ */

INSERT INTO contracts (
    contractor_id,
    contract_number,
    contract_name,
    contract_type,
    start_date,
    end_date,
    contract_status
)
VALUES
(
    1,
    'CTR-2026-001',
    'Security Gateway Support',
    'Support & Maintenance',
    '2026-01-01',
    '2026-12-31',
    'Active'
),
(
    2,
    'CTR-2026-002',
    'Server Platform Support',
    'Support & Maintenance',
    '2026-01-01',
    '2026-12-31',
    'Active'
),
(
    3,
    'CTR-2026-003',
    'Security Operations Support',
    'Managed Services',
    '2026-01-01',
    '2026-12-31',
    'Active'
),
(
    4,
    'CTR-2026-004',
    'Infrastructure Systems Support',
    'Support & Maintenance',
    '2026-01-01',
    '2026-12-31',
    'Active'
);


/* ============================================================
   17. INSERT SITES
   Fictional locations
   ============================================================ */

INSERT INTO sites (
    site_code,
    site_name,
    city,
    region,
    location_class
)
VALUES
(
    'NBR-01',
    'Northbridge Core Facility',
    'Northbridge',
    'Central District',
    'Central'
),
(
    'NBR-02',
    'Northbridge Data Center',
    'Northbridge',
    'Central District',
    'Central'
),
(
    'WST-01',
    'Westport Operations Facility',
    'Westport',
    'Western Region',
    'Regional'
),
(
    'LKS-01',
    'Lakeside Operations Facility',
    'Lakeside',
    'Northern Region',
    'Regional'
),
(
    'GRV-01',
    'Greenfield Network Facility',
    'Greenfield',
    'Southern Region',
    'Regional'
),
(
    'RVD-01',
    'Riverdale Operations Facility',
    'Riverdale',
    'Eastern Region',
    'Regional'
);


/* ============================================================
   18. INSERT PRIORITIES
   ============================================================ */

INSERT INTO priorities (
    priority_name,
    priority_rank
)
VALUES
('Critical', 1),
('High', 2),
('Medium', 3),
('Low', 4);


/* ============================================================
   19. INSERT TICKET STATUSES
   ============================================================ */

INSERT INTO ticket_statuses (
    status_name,
    is_closed
)
VALUES
('New', FALSE),
('Assigned', FALSE),
('In Progress', FALSE),
('Pending', FALSE),
('Resolved', TRUE),
('Closed', TRUE),
('Cancelled', TRUE);


/* ============================================================
   20. INSERT ASSETS
   Generic fictional technology names
   ============================================================ */

INSERT INTO assets (
    asset_code,
    asset_name,
    asset_type,
    site_id,
    contract_id
)
VALUES

-- Contract 1
(
    'FW-001',
    'Firewall 01',
    'Firewall',
    1,
    1
),
(
    'FW-002',
    'Firewall 02',
    'Firewall',
    4,
    1
),
(
    'SGW-001',
    'Security Gateway 01',
    'Security Gateway',
    2,
    1
),

-- Contract 2
(
    'MGT-001',
    'Management Server 01',
    'Management Server',
    1,
    2
),
(
    'MGT-002',
    'Management Server 02',
    'Management Server',
    3,
    2
),
(
    'APP-001',
    'Application Server 01',
    'Application Server',
    5,
    2
),

-- Contract 3
(
    'IDS-001',
    'IDS IPS Node 01',
    'IDS/IPS',
    2,
    3
),
(
    'IDS-002',
    'IDS IPS Node 02',
    'IDS/IPS',
    5,
    3
),
(
    'LOG-001',
    'Log Server 01',
    'Log Server',
    3,
    3
),

-- Contract 4
(
    'MGT-003',
    'Management Server 03',
    'Management Server',
    6,
    4
),
(
    'LOG-002',
    'Log Server 02',
    'Log Server',
    1,
    4
),
(
    'APP-002',
    'Application Server 02',
    'Application Server',
    6,
    4
);


/* ============================================================
   21. INSERT SLA RULES
   Synthetic SLA matrix
   ============================================================ */

INSERT INTO sla_rules (
    contract_id,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
)
VALUES
(1, 1, 'Central',   15,  120),
(1, 1, 'Regional',  30,  240),

(1, 2, 'Central',   30,  240),
(1, 2, 'Regional',  60,  480),

(1, 3, 'Central',  120,  720),
(1, 3, 'Regional', 180, 1440),

(1, 4, 'Central',  240, 1440),
(1, 4, 'Regional', 480, 2880);


/* Copy same SLA structure to Contract 2 */

INSERT INTO sla_rules (
    contract_id,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
)
SELECT
    2,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
FROM sla_rules
WHERE contract_id = 1;


/* Contract 3 */

INSERT INTO sla_rules (
    contract_id,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
)
SELECT
    3,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
FROM sla_rules
WHERE contract_id = 1;


/* Contract 4 */

INSERT INTO sla_rules (
    contract_id,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
)
SELECT
    4,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes
FROM sla_rules
WHERE contract_id = 1;


/* ============================================================
   22. INSERT TASK TEMPLATES
   ============================================================ */

INSERT INTO task_templates (
    contract_id,
    task_name,
    task_type,
    frequency,
    due_days
)
VALUES

(
    1,
    'Monthly Security Gateway Health Check',
    'Health Check',
    'Monthly',
    14
),
(
    1,
    'Quarterly Preventive Maintenance',
    'Maintenance',
    'Quarterly',
    21
),

(
    2,
    'Monthly Server Health Check',
    'Health Check',
    'Monthly',
    14
),
(
    2,
    'Quarterly Platform Maintenance Review',
    'Maintenance Review',
    'Quarterly',
    21
),

(
    3,
    'Monthly Security Incident Summary',
    'Reporting',
    'Monthly',
    10
),
(
    3,
    'Quarterly Security Platform Update Review',
    'Update Review',
    'Quarterly',
    21
),

(
    4,
    'Monthly System Availability Report',
    'Reporting',
    'Monthly',
    14
),
(
    4,
    'Quarterly Configuration Review',
    'Configuration Review',
    'Quarterly',
    30
);


/* ============================================================
   23. VALIDATION
   ============================================================ */

SELECT * FROM contractors;
SELECT * FROM contracts;
SELECT * FROM sites;
SELECT * FROM priorities;
SELECT * FROM ticket_statuses;
SELECT * FROM assets;
SELECT * FROM sla_rules;
SELECT * FROM task_templates;