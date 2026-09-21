/*
Project: Telecom Operations Analytics
File: 01_data_exploration.sql

Purpose:
Initial exploration and validation of the analytical dataset before
performing contractor performance, SLA, task, and reliability analysis.

Note:
The dataset used in this portfolio project is fully synthetic and
contains no confidential production data.
*/

-- ============================================================
-- 1. available tables : review the tables available in the analytics schema.
-- ============================================================
select
    table_schema,
    table_name
from information_schema.tables
where table_schema = 'analytics'
order by table_name;


-- ============================================================
-- 2. fact table row counts: check the number of records available in each fact table.
-- ============================================================
select
    'fact_issue' as table_name,
    count(*) as row_count
from analytics.fact_issue

union all

select
    'fact_issue_sla',
    count(*)
from analytics.fact_issue_sla

union all

select
    'fact_issue_history',
    count(*)
from analytics.fact_issue_history;

-- ============================================================
-- 3.  issue data preview: the structure and sample records of the main issue table.
-- ============================================================

select *
from analytics.fact_issue
limit 20;

-- ============================================================
-- 4. issue type distribution: the number of records by issue type.
-- ============================================================
select
    issue_type,
    count(*) as issue_count
from analytics.fact_issue
group by issue_type
order by issue_count desc;

-- ============================================================
-- 5. dataset date range: verify the time period covered by the dataset.
-- ============================================================

select
    min(created_at) as first_record,
    max(created_at) as last_record
from analytics.fact_issue;

-- ============================================================
-- 6. monthly record distribution: check whether issue data is available across all analysis months.
-- ============================================================
select
    date_trunc('month', created_at)::date as month,
    count(*) as issue_count
from analytics.fact_issue
group by date_trunc('month', created_at)::date
order by month;

-- ============================================================
-- 7. contractor dimension review
-- ============================================================
select *
from analytics.dim_contractor
order by contractor_id;


-- ============================================================
-- 8. site and location review: review sites and their central/regional classification.
-- ============================================================

select *
from analytics.dim_site
order by site_id;


-- ============================================================
-- 9. device dimension review: inspect device types, models, site assignments and contractors.
-- ============================================================
select
    device_id,
    device_name,
    device_type,
    device_model,
    site_id,
    contractor_id,
    criticality
from analytics.dim_device
order by device_id
limit 30;

-- ============================================================
-- 10. device type distribution
-- ============================================================
select
    device_type,
    count(*) as device_count
from analytics.dim_device
group by device_type
order by device_count desc;

-- ============================================================
-- 11. device model distribution
-- ============================================================
select
    device_type,
    device_model,
    count(*) as device_count
from analytics.dim_device
group by
    device_type,
    device_model
order by
    device_type,
    device_model;


-- ============================================================
-- 12. sla rule review: sla targets by priority and location group.
-- ============================================================
select
    sla_id,
    sla_type,
    priority,
    location_group,
    target_minutes
from analytics.dim_sla
order by
    location_group,
    target_minutes;

-- ============================================================
-- 13. incident category distribution
-- ============================================================
select
    category,
    count(*) as incident_count
from analytics.fact_issue
where issue_type = 'Incident'
group by category
order by incident_count desc;

-- ============================================================
-- 14. root cause distribution: explore incident root causes within each category.
-- ============================================================

select
    category,
    root_cause,
    count(*) as incident_count
from analytics.fact_issue
where issue_type = 'Incident'
group by   category, root_cause
order by   category, incident_count desc;

-- ============================================================
-- 15. missing value check: identify missing values in fields required for the analysis.
-- ============================================================
select
    count(*) as total_issues,

    count(*) filter (where contractor_id is null) as missing_contractor,

    count(*) filter ( where created_at is null ) as missing_created_at,

    count(*) filter ( where resolved_at is null ) as missing_resolved_at,

    count(*) filter ( where issue_type = 'Incident'  and device_id is null) as incident_missing_device,

    count(*) filter (where issue_type = 'Incident'  and root_cause is null) as incident_missing_root_cause

from analytics.fact_issue;

-- ============================================================
-- 16. date consistency check: identify records where resolution occurs before issue creation.
-- ============================================================

select
    count(*) as invalid_records
from analytics.fact_issue
where resolved_at < created_at;

-- ============================================================
-- 17. task due-date validation: check whether planned tasks have a defined due date.
-- ============================================================
select
    count(*) as tasks_without_due_date
from analytics.fact_issue
where issue_type = 'Task'
  and due_date is null;

-- ============================================================
-- 18. incident data model join: combine issue, contractor, device and site information
-- to validate the relationships required for further analysis.
-- ============================================================
select
    i.issue_key,
    i.issue_type,

    c.contractor_name,

    d.device_name,
    d.device_type,
    d.device_model,

    s.site_name,
    s.location_group,

    i.priority,
    i.category,
    i.root_cause,
    i.created_at,
    i.resolved_at

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

left join analytics.dim_device as d
    on i.device_id = d.device_id

left join analytics.dim_site as s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

order by i.created_at

limit 30;