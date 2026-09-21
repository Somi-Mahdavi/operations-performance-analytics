/*
purpose:
analyze incident resolution times and sla performance by comparing
actual sla duration with contractual sla targets.

the analysis includes:
- incident resolution time
- actual sla duration
- sla compliance and breach identification
- sla performance by priority
- sla performance by location
- sla performance by contractor
- monthly sla trends
*/

-- ============================================================
-- 1. incident sla data preview: the relationship between incidents, sla execution records, and sla definitions.
-- ============================================================

select
    i.issue_key,
    i.priority,
    i.created_at,
    i.resolved_at,
    fs.sla_start_at,
    fs.sla_stop_at,
    s.sla_type,
    s.location_group,
    s.target_minutes
from analytics.fact_issue as i

join analytics.fact_issue_sla as fs
    on i.issue_id = fs.issue_id

join analytics.dim_sla as s
    on fs.sla_id = s.sla_id

where i.issue_type = 'Incident'

order by i.created_at

limit 20;

-- ============================================================
-- 2. calculate the total resolution time for each incident from issue creation until resolution.
-- ============================================================

select
    issue_key,
    priority,
    created_at,
    resolved_at,

    round(extract(epoch from (resolved_at - created_at)) / 60) as resolution_minutes

from analytics.fact_issue

where issue_type = 'Incident'

order by created_at

limit 20;

-- ============================================================
-- 3. calculate the actual sla duration using the sla start and stop timestamps.
-- ============================================================

select
    i.issue_key,
    i.priority,

    fs.sla_start_at,
    fs.sla_stop_at,

    round(extract( epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60) as actual_sla_minutes

from analytics.fact_issue as i

join analytics.fact_issue_sla as fs
    on i.issue_id = fs.issue_id

where i.issue_type = 'Incident'

order by i.created_at

limit 20;

-- ============================================================
-- 4. actual vs target sla : compare the actual sla duration of each incident
-- with its contractual sla target.
-- ============================================================

select
    i.issue_key,
    i.priority,
    s.location_group,

    s.target_minutes,

    round(extract( epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60
    ) as actual_sla_minutes

from analytics.fact_issue as i

join analytics.fact_issue_sla as fs
    on i.issue_id = fs.issue_id

join analytics.dim_sla as s
    on fs.sla_id = s.sla_id

where i.issue_type = 'Incident'

order by i.created_at

limit 30;

-- ============================================================
-- 5. sla compliance classification: classify each incident as complied or breached
-- by comparing actual sla duration with the sla target.
-- ============================================================

select
    i.issue_key,
    i.priority,
    s.location_group,

    s.target_minutes,

    round(
        extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60
    ) as actual_sla_minutes,

    case

        when extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes

        then 'Breached'

        else 'Complied'

    end as sla_status

from analytics.fact_issue as i

join analytics.fact_issue_sla as fs
    on i.issue_id = fs.issue_id

join analytics.dim_sla as s
    on fs.sla_id = s.sla_id

where i.issue_type = 'Incident'

order by i.created_at

limit 30;

-- ============================================================
-- 6. overall sla performance: calculate the overall sla compliance and breach rate.
-- ============================================================

with sla_analysis as (

    select
        i.issue_id,
        i.issue_key,

        case

            when extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes

            then 'Breached'

            else 'Complied'

        end as sla_status

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    where i.issue_type = 'Incident'

)

select
    count(*) as total_incidents,

    count(*) filter (where sla_status = 'Complied') as complied_incidents,

    count(*) filter (where sla_status = 'Breached' ) as breached_incidents,

    round( 100.0 *
        count(*) filter (where sla_status = 'Complied') / count(*), 2 ) as sla_compliance_rate,

    round( 100.0 *
        count(*) filter (where sla_status = 'Breached') / count(*),2  ) as sla_breach_rate

from sla_analysis;
-- ============================================================
-- 7. sla performance by priority: compare sla compliance across incident priorities.
-- ============================================================

with sla_analysis as (

    select
        i.issue_id,
        i.priority,

        case
            when extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    where i.issue_type = 'Incident'

)

select
    priority,

    count(*) as total_incidents,

    count(*) filter (where sla_status = 'Breached') as breached_incidents,

    round( 100.0 *
        count(*) filter ( where sla_status = 'Breached') / count(*),  2
    ) as sla_breach_rate

from sla_analysis

group by priority

order by sla_breach_rate desc;

-- ============================================================
-- 8. sla performance by location: compare sla performance between central
-- and regional locations.
-- ============================================================

with sla_analysis as (

    select
        i.issue_id,
        s.location_group,

        case
            when extract(
                epoch from (fs.sla_stop_at - fs.sla_start_at)
            ) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    where i.issue_type = 'Incident'

)

select
    location_group,

    count(*) as total_incidents,

    count(*) filter (
        where sla_status = 'Breached'
    ) as breached_incidents,

    round(
        100.0 *
        count(*) filter (
            where sla_status = 'Breached'
        ) / count(*),
        2
    ) as sla_breach_rate

from sla_analysis

group by location_group

order by sla_breach_rate desc;

-- ============================================================
-- 9. sla performance by contractor
-- ============================================================

with sla_analysis as (

    select
        i.issue_id,
        c.contractor_name,

        case
            when extract(
                epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    join analytics.dim_contractor as c
        on i.contractor_id = c.contractor_id

    where i.issue_type = 'Incident'

)

select
    contractor_name,

    count(*) as total_incidents,

    count(*) filter ( where sla_status = 'Complied') as complied_incidents,

    count(*) filter ( where sla_status = 'Breached') as breached_incidents,

    round( 100.0 *
        count(*) filter (where sla_status = 'Complied' ) / count(*),  2    ) as sla_compliance_rate,

    round( 100.0 *
        count(*) filter (where sla_status = 'Breached' ) / count(*), 2 ) as sla_breach_rate

from sla_analysis

group by contractor_name

order by sla_breach_rate desc;

-- ============================================================
-- 10. monthly sla trend: analyze how sla performance changes over time.
-- ============================================================

with sla_analysis as (

    select
        i.issue_id,
        date_trunc('month',i.created_at)::date as month,

        case
            when extract(
                epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    where i.issue_type = 'Incident'

)

select
    month,

    count(*) as total_incidents,

    count(*) filter (where sla_status = 'Breached') as breached_incidents,

    round(100.0 *
		count(*) filter ( where sla_status = 'Breached') / count(*), 2) as sla_breach_rate

from sla_analysis

group by month

order by month;

-- ============================================================
-- 11. monthly sla performance by contractor: identify changes in contractor sla performance
-- over the six-month analysis period.
-- ============================================================

with sla_analysis as (

    select
        i.issue_id,

        date_trunc('month',i.created_at)::date as month,

        c.contractor_name,

        case
            when extract(
                epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60 > s.target_minutes
            then 'Breached'
            else 'Complied'
        end as sla_status

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as fs
        on i.issue_id = fs.issue_id

    join analytics.dim_sla as s
        on fs.sla_id = s.sla_id

    join analytics.dim_contractor as c
        on i.contractor_id = c.contractor_id

    where i.issue_type = 'Incident'

)

select
    month,
    contractor_name,

    count(*) as total_incidents,

    count(*) filter (where sla_status = 'Breached') as breached_incidents,

    round(100.0 *
        count(*) filter (where sla_status = 'Breached') / count(*), 2 ) as sla_breach_rate

from sla_analysis

group by  month,contractor_name

order by  month,contractor_name;
