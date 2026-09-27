-- ============================================================
-- 07. root cause analysis
-- ============================================================

-- business question:
-- what are the main causes of network incidents, which causes 
-- contribute most to the overall incident volume, and are specific 
-- causes concentrated in particular devices, sites, or time periods?

-- analysis approach:
-- 1. analyze incident categories
-- 2. analyze root causes within each category
-- 3. identify the causes contributing most to total incidents
-- 4. investigate root causes by device and site
-- 5. analyze root-cause patterns over time
-- 6. identify recurring device and root-cause combinations
-- ============================================================

-- ------------------------------------------------------------
-- 1. incident distribution by category
-- ------------------------------------------------------------

select
    category,
    count(*) as total_incidents,
    round(100.0 * count(*) / sum(count(*)) over (), 2) as percentage_of_incidents
from analytics.fact_issue
where issue_type = 'Incident'
group by  category
order by  total_incidents desc;

-- ------------------------------------------------------------
-- 2. root cause distribution by incident category
-- ------------------------------------------------------------

select
    category,
    root_cause,
    count(*) as total_incidents,
    round(100.0 * count(*)/ sum(count(*)) over (partition by category),2) as percentage_within_category
from analytics.fact_issue
where issue_type = 'Incident'
group by  category,root_cause
order by  category,total_incidents desc;


-- ------------------------------------------------------------
-- 3. overall root cause contribution
-- ------------------------------------------------------------

select
    root_cause, category,
	count(*) as total_incidents,
    round(100.0 * count(*) / sum(count(*)) over (),2) as percentage_of_incidents
from analytics.fact_issue
where issue_type = 'Incident'
group by  root_cause,category
order by  total_incidents desc;

-- ------------------------------------------------------------
-- 4. pareto analysis of root causes
-- ------------------------------------------------------------

with root_cause_summary as (

    select
        root_cause,
        category,
        count(*) as total_incidents
    from analytics.fact_issue
    where issue_type = 'Incident'
    group by  root_cause,category

)

select
    root_cause,
    category,
    total_incidents,

    round(100.0 * total_incidents / sum(total_incidents) over (), 2 ) as percentage_of_incidents,

    round(100.0 * sum(total_incidents) over (
            order by total_incidents desc  rows between unbounded preceding and current row
        )/ sum(total_incidents) over (), 2) as cumulative_percentage

from root_cause_summary
order by  total_incidents desc;

-- ------------------------------------------------------------
-- 5. root cause distribution by site
-- ------------------------------------------------------------

select
    s.site_code,
    s.location_group,
    i.root_cause,
    count(*) as total_incidents
from analytics.fact_issue i

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

group by
    s.site_code,
    s.location_group,
    i.root_cause

order by   total_incidents desc, s.site_code;

-- ------------------------------------------------------------
-- 6. recurring root causes by individual device
-- ------------------------------------------------------------

select
    d.device_name,
    d.device_type,
    d.device_model,
    s.site_code,
    i.root_cause,
    count(*) as total_incidents
from analytics.fact_issue i

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
    i.root_cause

order by  total_incidents desc, d.device_name;


-- ------------------------------------------------------------
-- 7. monthly root cause trend
-- ------------------------------------------------------------

select
    date_trunc('month', created_at)::date as month,
    root_cause,
    count(*) as total_incidents
from analytics.fact_issue
where issue_type = 'Incident'

group by   date_trunc('month', created_at)::date, root_cause

order by   month, total_incidents desc;

