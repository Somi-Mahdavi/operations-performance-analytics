-- ============================================================
-- 08_create_reporting_views.sql
-- operations performance analytics
--
-- purpose:create clean reporting views for the power bi data model.
--
-- reporting views:
-- 1. analytics.vw_incident_reporting
-- 2. analytics.vw_task_reporting
-- 3. analytics.vw_monthly_contract_compliance
-- ============================================================


-- ============================================================
-- 1. incident reporting view - one row per incident
-- ============================================================

create or replace view analytics.vw_incident_reporting as

select
    i.issue_id,
    i.issue_key,
    i.created_at::date as created_date,
    date_trunc('month', i.created_at)::date as reporting_month,

    i.contractor_id,
    c.contractor_name,

    i.device_id,
    d.device_code,
    d.device_name,
    d.device_type,
    d.device_model,

    s.site_id,
    s.site_code,
    s.site_name,
    s.location_group,
    s.region_code,
    s.site_criticality,

    i.priority,
    i.severity,
    i.category,
    i.subcategory,
    i.root_cause,
    i.status,
    i.summary,

    i.created_at,
    i.resolved_at,
    i.closed_at,

    sla.sla_code,
    sla.sla_name,
    sla.target_minutes as sla_target_minutes,

    fs.sla_start_at,
    fs.sla_stop_at,

    round(extract(epoch from (i.resolved_at - i.created_at)) / 60.0, 2) as resolution_time_minutes,

    round(extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60.0,2) as actual_sla_minutes,

    case
        when fs.sla_stop_at is null
          or fs.sla_start_at is null
          or sla.target_minutes is null
            then null

        when extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60.0 <= sla.target_minutes
            then 'Complied'

        else 'Breached'
    end as sla_status,

    case
        when fs.sla_stop_at is null
          or fs.sla_start_at is null
          or sla.target_minutes is null
            then null

        else round(greatest(extract(epoch from (fs.sla_stop_at - fs.sla_start_at)) / 60.0 
		- sla.target_minutes,0), 2)  
	end as sla_excess_minutes

from analytics.fact_issue i

join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

left join analytics.fact_issue_sla fs
    on i.issue_id = fs.issue_id

left join analytics.dim_sla sla
    on fs.sla_id = sla.sla_id

where i.issue_type = 'Incident';


-- ============================================================
-- 2. planned task reporting view - one row per planned task
-- ============================================================

create or replace view analytics.vw_task_reporting as

select
    i.issue_id,
    i.issue_key,

    i.contractor_id,
    c.contractor_name,

    i.device_id,
    d.device_code,
    d.device_name,
    d.device_type,
    d.device_model,

    s.site_id,
    s.site_code,
    s.site_name,
    s.location_group,
    s.region_code,

    i.priority,
    i.status,
    i.summary,

    i.created_at,
    i.due_date,
    i.resolved_at,
    i.closed_at,

    i.due_date::date as due_date_only,
    date_trunc('month', i.due_date)::date as reporting_month,

    case
        when i.resolved_at is null then 'Open'

        when i.resolved_at <= i.due_date
            then 'On Time'

        else 'Overdue'
    end as task_status,

    case
        when i.resolved_at is null
          or i.resolved_at <= i.due_date
            then 0

        else round(extract(epoch from (i.resolved_at - i.due_date)) / 3600.0, 2 )
    end as delay_hours

from analytics.fact_issue i

join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id

join analytics.dim_device d
    on i.device_id = d.device_id

join analytics.dim_site s
    on d.site_id = s.site_id

where i.issue_type = 'Task';


-- ============================================================
-- 3. monthly contract compliance reporting view
-- one row per contractor and month
-- combines incident sla performance and planned task performance
-- ============================================================

create or replace view analytics.vw_monthly_contract_compliance as

with incident_monthly as (

    select
        reporting_month,
        contractor_id,
        contractor_name,

        count(*) as total_incidents,

        count(*) filter (where sla_status = 'Complied') as sla_complied_incidents,

        count(*) filter (where sla_status = 'Breached') as sla_breaches,

        round(100.0
            * count(*) filter (where sla_status = 'Complied')
            / nullif(count(*) filter (where sla_status in ('Complied', 'Breached')), 0),
            2) as sla_compliance_rate,

        round(sum(sla_excess_minutes) / 60.0,2) as total_sla_excess_hours

    from analytics.vw_incident_reporting

    group by
        reporting_month,
        contractor_id,
        contractor_name
),

task_monthly as (

    select
        reporting_month,
        contractor_id,
        contractor_name,

        count(*) as total_tasks,

        count(*) filter (where task_status = 'On Time') as on_time_tasks,

        count(*) filter (where task_status = 'Overdue') as overdue_tasks,

        round(
            100.0
            * count(*) filter (where task_status = 'On Time')
            / nullif(
                count(*) filter (where task_status in ('On Time', 'Overdue')), 0),2) as on_time_rate,

        round(sum(delay_hours),2) as total_task_delay_hours

    from analytics.vw_task_reporting

    group by
        reporting_month,
        contractor_id,
        contractor_name
)

select
    coalesce(i.reporting_month, t.reporting_month) as reporting_month,
    coalesce(i.contractor_id, t.contractor_id) as contractor_id,
    coalesce(i.contractor_name, t.contractor_name) as contractor_name,

    coalesce(i.total_incidents, 0) as total_incidents,
    coalesce(i.sla_complied_incidents, 0) as sla_complied_incidents,
    coalesce(i.sla_breaches, 0) as sla_breaches,
    i.sla_compliance_rate,
    coalesce(i.total_sla_excess_hours, 0) as total_sla_excess_hours,

    coalesce(t.total_tasks, 0) as total_tasks,
    coalesce(t.on_time_tasks, 0) as on_time_tasks,
    coalesce(t.overdue_tasks, 0) as overdue_tasks,
    t.on_time_rate,
    coalesce(t.total_task_delay_hours, 0) as total_task_delay_hours

from incident_monthly i

full outer join task_monthly t
    on i.reporting_month = t.reporting_month
   and i.contractor_id = t.contractor_id

order by
    reporting_month,
    contractor_name;


-- ============================================================
-- validation
-- ============================================================

select *
from analytics.vw_incident_reporting
limit 10;


select *
from analytics.vw_task_reporting
limit 10;


select *
from analytics.vw_monthly_contract_compliance
order by reporting_month, contractor_name;