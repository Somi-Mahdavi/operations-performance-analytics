-- ============================================================
-- 1. incident workload by contractor:review the number of incidents handled by each
-- contractor before comparing performance metrics.
-- ============================================================
select
    c.contractor_name,
    count(*) as total_incidents
from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'

group by c.contractor_name

order by total_incidents desc;

-- ============================================================
-- 2. average resolution time by contractor: compare the average time required by each contractor
-- to resolve incidents.
-- ============================================================

select
    c.contractor_name,

    count(*) as total_incidents,

    round(
        avg(extract(epoch from (i.resolved_at - i.created_at)) / 60),  2
    ) as avg_resolution_minutes

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'

group by c.contractor_name

order by avg_resolution_minutes desc;


-- ============================================================
-- 3. average and median resolution time by contractor
-- purpose: compare average and median resolution times to reduce
-- the influence of unusually long incident resolution times.
-- ============================================================

select
    c.contractor_name,

    count(*) as total_incidents,

    round(
        avg(extract(epoch from (i.resolved_at - i.created_at)) / 60), 2
    ) as avg_resolution_minutes,

    round(
        percentile_cont(0.5) within group (
            order by extract(epoch from (i.resolved_at - i.created_at)) / 60)::numeric,
        2 ) as median_resolution_minutes

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'

group by c.contractor_name

order by avg_resolution_minutes desc;

-- ============================================================
-- 4. incident priority mix by contractor: examine whether contractors handle different
-- incident priority profiles before comparing resolution times.
-- ============================================================

select
    c.contractor_name,
    i.priority,
    count(*) as incident_count,

    round(
        100.0 * count(*) /
        sum(count(*)) over (partition by c.contractor_name),
        2   ) as percentage_of_contractor_incidents

from analytics.fact_issue as i
join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'

group by
    c.contractor_name,
    i.priority

order by
    c.contractor_name,
    incident_count desc;


-- ============================================================
-- 5. incident location mix by contractor: examine whether contractors handle different
-- proportions of central and regional incidents before
-- comparing their operational performance.
-- ============================================================

select
    c.contractor_name,
    s.location_group,

    count(*) as incident_count,

    round(
        100.0 * count(*) /
        sum(count(*)) over (partition by c.contractor_name),
        2   ) as percentage_of_contractor_incidents

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

join analytics.dim_device as d
    on i.device_id = d.device_id

join analytics.dim_site as s
    on d.site_id = s.site_id

where i.issue_type = 'Incident'

group by
    c.contractor_name,
    s.location_group

order by
    c.contractor_name,
    s.location_group;


-- ============================================================
-- 6. sla performance by contractor: evaluate contractor performance based on sla
-- compliance and breach rates.
-- ============================================================

with contractor_sla as (

    select
        c.contractor_name,

        case
            when extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.dim_contractor as c
        on i.contractor_id = c.contractor_id

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    where i.issue_type = 'Incident'
)

select
    contractor_name,

    count(*) as total_incidents,

    count(*) filter (where sla_status = 'Complied') as sla_complied,

    count(*) filter (where sla_status = 'Breached') as sla_breached,

    round(
        100.0 *
        count(*) filter ( where sla_status = 'Complied') / count(*), 2
    ) as sla_compliance_rate,

    round(
        100.0 *
        count(*) filter (where sla_status = 'Breached') / count(*), 2
    ) as sla_breach_rate

from contractor_sla

group by contractor_name

order by sla_compliance_rate desc;


-- ============================================================
-- 7. monthly sla performance by contractor: evaluate how contractor sla performance changes
-- over time and identify improving or deteriorating trends.
-- ============================================================

with contractor_sla as (

    select
        date_trunc('month',i.created_at)::date as month,

        c.contractor_name,

        case
            when extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.dim_contractor as c
        on i.contractor_id = c.contractor_id

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    where i.issue_type = 'Incident'
)

select
    month,
    contractor_name,

    count(*) as total_incidents,

    count(*) filter (where sla_status = 'Breached') as sla_breached,

    round(
        100.0 *
        count(*) filter (where sla_status = 'Complied') / count(*),
        2   ) as sla_compliance_rate

from contractor_sla

group by
    month,
    contractor_name

order by
    month,
    contractor_name;


-- ============================================================
-- 8. monthly resolution time by contractor: analyze monthly changes in contractor resolution
-- performance and compare them with sla performance trends.
-- ============================================================

select
    date_trunc('month',i.created_at)::date as month,

    c.contractor_name,

    count(*) as total_incidents,

    round(
        avg(extract( epoch from (i.resolved_at - i.created_at)) / 60),
        2
    ) as avg_resolution_minutes,

    round(
        percentile_cont(0.5) within group (
            order by extract(epoch from (i.resolved_at - i.created_at)) / 60)::numeric,
        2    ) as median_resolution_minutes

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'

group by
    month,
    c.contractor_name

order by
    month,
    c.contractor_name;


-- ============================================================
-- 9. resolution time by contractor and priority: compare contractor resolution performance within
-- similar incident priority levels.
-- ============================================================

select
    c.contractor_name,
    i.priority,

    count(*) as total_incidents,

    round(
        avg(extract(epoch from (i.resolved_at - i.created_at)) / 60 ),
        2    ) as avg_resolution_minutes,

    round(
        percentile_cont(0.5) within group (
            order by extract(epoch from (i.resolved_at - i.created_at)) / 60)::numeric,
        2   ) as median_resolution_minutes

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'

group by
    c.contractor_name,
    i.priority

order by
    i.priority,
    avg_resolution_minutes desc;