-- ============================================================
-- 04 - task performance analysis: analyze planned task performance by contractor,
-- including workload, on-time completion, overdue tasks, completion delay and monthly performance trends.


-- ============================================================
-- 1. task workload by contractor
-- ============================================================
select
    c.contractor_name,
    count(*) as total_tasks

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'

group by
    c.contractor_name

order by
    total_tasks desc;

-- ============================================================
-- 2. classify tasks as on time or overdue: compare the completion time with the due date
-- for each completed planned task.

select
    i.issue_id,
    c.contractor_name,
    i.created_at,
    i.due_date,
    i.resolved_at,

    case
        when i.resolved_at <= i.due_date then 'On Time'
        when i.resolved_at > i.due_date then 'Overdue'
    end as task_status

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
    and i.resolved_at is not null
    and i.due_date is not null

order by
    c.contractor_name,
    i.due_date;

-- ============================================================
-- 3. task performance by contractor:  calculate on-time and overdue task rates for each contractor.
-- ============================================================

select
    c.contractor_name,

    count(*) as total_completed_tasks,

    count(*) filter (where i.resolved_at <= i.due_date) as on_time_tasks,

    count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

    round(
        100.0 * count(*) filter (where i.resolved_at <= i.due_date) / count(*),  2
    ) as on_time_rate_pct,

    round(
        100.0 * count(*) filter (where i.resolved_at > i.due_date) / count(*),  2
    ) as overdue_rate_pct

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
    and i.resolved_at is not null
    and i.due_date is not null

group by
    c.contractor_name

order by
    on_time_rate_pct desc;

-- ============================================================
-- 4. overdue task delay by contractor: analyze how long overdue tasks were delayed.
-- ============================================================


select
    c.contractor_name,

    count(*) as overdue_tasks,

    round(avg(extract(epoch from (i.resolved_at - i.due_date)) / 3600),2) as avg_delay_hours,

    round(
        percentile_cont(0.5) within group (
            order by extract(epoch from (i.resolved_at - i.due_date)) / 3600)::numeric,2) as median_delay_hours,

    round(
        max(extract(epoch from (i.resolved_at - i.due_date)) / 3600)::numeric,2) as max_delay_hours

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
    and i.resolved_at is not null
    and i.due_date is not null
    and i.resolved_at > i.due_date

group by
    c.contractor_name

order by
    avg_delay_hours desc;


-- ============================================================
-- 5. monthly task performance by contractor: analyze how on-time and overdue task rates change over time
-- for each contractor.
-- ============================================================

select
    date_trunc('month', i.due_date)::date as month,
    c.contractor_name,

    count(*) as total_completed_tasks,

    count(*) filter (where i.resolved_at <= i.due_date) as on_time_tasks,

    count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

    round(100.0 * count(*) filter (where i.resolved_at <= i.due_date) / count(*),2) as on_time_rate_pct,

    round(100.0 * count(*) filter (where i.resolved_at > i.due_date) / count(*),2) as overdue_rate_pct

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
    and i.resolved_at is not null
    and i.due_date is not null

group by
    date_trunc('month', i.due_date)::date,
    c.contractor_name

order by
    month,
    c.contractor_name;

-- ============================================================
-- 6. drill-down into contractor D overdue tasks
-- ============================================================

select
    i.issue_id,
    i.created_at,
    i.due_date,
    i.resolved_at,

    round((extract(epoch from (i.resolved_at - i.due_date)) / 3600)::numeric,2) as delay_hours

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
    and c.contractor_name = 'Contractor D'
    and i.resolved_at > i.due_date

order by
    i.due_date;


-- ============================================================
-- 7. task performance summary by contractor
-- ============================================================

select
    c.contractor_name,

    count(*) as total_completed_tasks,

    round(100.0 * count(*) filter (where i.resolved_at <= i.due_date) / count(*),2) as on_time_rate_pct,

    round(100.0 * count(*) filter (where i.resolved_at > i.due_date) / count(*),2) as overdue_rate_pct,

    round(
        avg(extract(epoch from (i.resolved_at - i.due_date)) / 3600) filter (where i.resolved_at > i.due_date)
		,2) as avg_overdue_delay_hours,

    round(
        percentile_cont(0.5) within group (
            order by extract(epoch from (i.resolved_at - i.due_date)) / 3600
        ) filter (where i.resolved_at > i.due_date)::numeric,
        2) as median_overdue_delay_hours

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
    and i.resolved_at is not null
    and i.due_date is not null

group by
    c.contractor_name

order by
    on_time_rate_pct desc;