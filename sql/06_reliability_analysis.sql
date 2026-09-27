-- ============================================================
-- 06. reliability analysis
-- ============================================================

-- business question:
-- incident volumes have increased over time.
-- where is this increase occurring, which parts of the infrastructure
-- are most affected, and are specific devices experiencing recurring incidents?

-- analysis approach:
-- 1. analyze the monthly incident trend
-- 2. identify affected location groups and sites
-- 3. analyze device types and models
-- 4. normalize incident counts by the number of devices
-- 5. identify individual devices with recurring incidents
-- 6. analyze whether high-incident devices show persistent patterns
-- ============================================================


-- ------------------------------------------------------------
-- 1. monthly incident trend
-- ------------------------------------------------------------

select
    date_trunc('month', created_at)::date as month,
    count(*) as total_incidents
from analytics.fact_issue
where issue_type = 'Incident'
group by date_trunc('month', created_at)::date
order by month;


-- ------------------------------------------------------------
-- 2. monthly incident trend by location group
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    s.location_group,
    count(*) as total_incidents
from analytics.fact_issue i

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

group by  date_trunc('month', i.created_at)::date, s.location_group

order by  month, s.location_group;


-- ------------------------------------------------------------
-- 3. monthly incident trend by site
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    s.site_code,
    s.location_group,
    count(*) as total_incidents
from analytics.fact_issue i

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

group by
    date_trunc('month', i.created_at)::date,
    s.site_code,
    s.location_group

order by   month, total_incidents desc;


-- ------------------------------------------------------------
-- 4. monthly incident trend by device type
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    d.device_type,
    count(*) as total_incidents
from analytics.fact_issue i

join analytics.dim_device d
    on i.device_id = d.device_id

where i.issue_type = 'Incident'

group by   date_trunc('month', i.created_at)::date, d.device_type

order by  month, total_incidents desc;


-- ------------------------------------------------------------
-- 5. incident analysis by device model
-- ------------------------------------------------------------

select
    d.device_type,
    d.device_model,
    count(*) as total_incidents
from analytics.fact_issue i

join analytics.dim_device d
    on i.device_id = d.device_id

where i.issue_type = 'Incident'

group by d.device_type, d.device_model

order by  total_incidents desc;


-- ------------------------------------------------------------
-- 6. normalized incident rate by device model
-- ------------------------------------------------------------

select
    d.device_type,
    d.device_model,
    count(distinct d.device_id) as total_devices,
    count(i.issue_id) as total_incidents,
    round(
        count(i.issue_id)::numeric  / nullif(count(distinct d.device_id), 0), 2 ) as incidents_per_device
from analytics.dim_device d

left join analytics.fact_issue i
    on d.device_id = i.device_id
   and i.issue_type = 'Incident'

group by  d.device_type, d.device_model

order by  incidents_per_device desc;


-- ------------------------------------------------------------
-- 7. recurring incidents by individual device
-- ------------------------------------------------------------

select
    d.device_id,
    d.device_name,
    d.device_type,
    d.device_model,
    s.site_code,
    s.location_group,
    count(*) as total_incidents
from analytics.fact_issue i

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

group by
    d.device_id,
    d.device_name,
    d.device_type,
    d.device_model,
    s.site_code,
    s.location_group

order by  total_incidents desc;


-- ------------------------------------------------------------
-- 8. monthly trend of high-incident devices
-- ------------------------------------------------------------
-- a threshold of 15 incidents is used only to identify high-incident devices for further investigation.

with device_incidents as (

    select
        i.device_id,
        count(*) as total_incidents
    from analytics.fact_issue i
    where i.issue_type = 'Incident'
    group by  i.device_id

),

high_incident_devices as (

    select   device_id
    from device_incidents
    where total_incidents >= 15

)

select
    d.device_name,
    d.device_type,
    d.device_model,
    s.site_code,
    date_trunc('month', i.created_at)::date as month,
    count(*) as total_incidents
from analytics.fact_issue i

join high_incident_devices h
    on i.device_id = h.device_id

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

group by
    d.device_name,
    d.device_type,
    d.device_model,
    s.site_code,
    date_trunc('month', i.created_at)::date

order by   d.device_name, month;