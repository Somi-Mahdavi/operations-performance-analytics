-- ============================================================
-- monthly contract compliance and invoice verification
-- ============================================================


-- ------------------------------------------------------------
-- 1. monthly incident workload by contractor and priority
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    c.contractor_name,
    i.priority,
    count(*) as total_incidents
from analytics.fact_issue i
join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id
where i.issue_type = 'Incident'
group by
    date_trunc('month', i.created_at)::date,
    c.contractor_name,
    i.priority
order by
    month,
    c.contractor_name,
    i.priority;


-- ------------------------------------------------------------
-- 2. monthly sla compliance by contractor and priority
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    c.contractor_name,
    i.priority,

    count(*) as total_incidents,

    count(*) filter (
        where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 <= s.target_minutes
    ) as sla_complied,

    count(*) filter (
        where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes
    ) as sla_breached,

    round(100.0 *
        count(*) filter (
            where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60
                  <= s.target_minutes) / nullif(count(*), 0),
        2) as sla_compliance_pct

from analytics.fact_issue i

join analytics.fact_issue_sla isla
    on i.issue_id = isla.issue_id

join analytics.dim_sla s
    on isla.sla_id = s.sla_id

join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'
  and isla.sla_stop_at is not null

group by
    date_trunc('month', i.created_at)::date,
    c.contractor_name,
    i.priority

order by
    month,
    c.contractor_name,
    i.priority;

-- ------------------------------------------------------------
-- 3. monthly sla excess for breached incidents
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    c.contractor_name,
    i.priority,

    count(*) filter (
        where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes
    ) as sla_breached,

    round(
        sum(greatest(
                extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 3600 - s.target_minutes / 60.0,
                0 ))::numeric,
        2 ) as total_sla_excess_hours,

    round(avg(case
                when extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60> s.target_minutes
                then extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 3600
                    - s.target_minutes / 60.0
            end)::numeric,2) as avg_sla_excess_hours

from analytics.fact_issue i

join analytics.fact_issue_sla isla
    on i.issue_id = isla.issue_id

join analytics.dim_sla s
    on isla.sla_id = s.sla_id

join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'
  and isla.sla_stop_at is not null

group by
    date_trunc('month', i.created_at)::date,
    c.contractor_name,
    i.priority

order by
    month,
    c.contractor_name,
    i.priority;


-- ------------------------------------------------------------
-- 4. monthly planned task compliance
-- ------------------------------------------------------------

select
    date_trunc('month', i.due_date)::date as month,
    c.contractor_name,

    count(*) as total_tasks,

    count(*) filter (where i.resolved_at <= i.due_date) as on_time_tasks,

    count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

    round(100.0 * count(*) filter (where i.resolved_at <= i.due_date) / nullif(count(*), 0),
        2) as on_time_rate_pct

from analytics.fact_issue i

join analytics.dim_contractor c
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


-- ------------------------------------------------------------
-- 5. monthly delay for overdue tasks
-- ------------------------------------------------------------

select
    date_trunc('month', i.due_date)::date as month,
    c.contractor_name,

    count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

    round(
        sum(greatest(extract(epoch from (i.resolved_at - i.due_date)) / 3600, 0))::numeric,
        2) as total_delay_hours,

    round(
        avg(case
                when i.resolved_at > i.due_date
                then extract(epoch from (i.resolved_at - i.due_date)) / 3600
            end)::numeric,2) as avg_delay_hours,

    round(
        max(case
                when i.resolved_at > i.due_date
                then extract(epoch from (i.resolved_at - i.due_date)) / 3600
            end)::numeric,2) as max_delay_hours

from analytics.fact_issue i

join analytics.dim_contractor c
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

-- ------------------------------------------------------------
-- 6a. incident sla breach details
-- ------------------------------------------------------------

select
    date_trunc('month', i.created_at)::date as month,
    c.contractor_name,
    i.issue_id,
    i.priority,
    s.target_minutes,

    round((extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60)::numeric,
        2) as actual_sla_minutes,

    round((extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 3600
            - s.target_minutes / 60.0)::numeric,2) as sla_excess_hours

from analytics.fact_issue i

join analytics.fact_issue_sla isla
    on i.issue_id = isla.issue_id

join analytics.dim_sla s
    on isla.sla_id = s.sla_id

join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'
  and isla.sla_stop_at is not null
  and extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes

order by
    month,
    c.contractor_name,
    i.priority,
    sla_excess_hours desc;

-- ------------------------------------------------------------
-- 6b. overdue task details
-- ------------------------------------------------------------

select
    date_trunc('month', i.due_date)::date as month,
    c.contractor_name,
    i.issue_id,
    i.due_date,
    i.resolved_at,

    round((extract(epoch from (i.resolved_at - i.due_date)) / 3600)::numeric,2) as delay_hours

from analytics.fact_issue i

join analytics.dim_contractor c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
  and i.due_date is not null
  and i.resolved_at is not null
  and i.resolved_at > i.due_date

order by
    month,
    c.contractor_name,
    delay_hours desc;


-- ------------------------------------------------------------
-- 7. final monthly contract compliance summary
-- ------------------------------------------------------------

with incident_performance as (

    select
        date_trunc('month', i.created_at)::date as month,
        c.contractor_name,

        count(*) as total_incidents,

        count(*) filter (
            where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60
                  <= s.target_minutes) as sla_complied,

        count(*) filter (where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60
                  > s.target_minutes) as sla_breached,

        round(
            100.0 * count(*) filter (where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60
                      <= s.target_minutes) / nullif(count(*), 0),2) as sla_compliance_pct,

        round(sum(greatest(extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 3600
                    - s.target_minutes / 60.0,0))::numeric,2) as total_sla_excess_hours

    from analytics.fact_issue i

    join analytics.fact_issue_sla isla
        on i.issue_id = isla.issue_id

    join analytics.dim_sla s
        on isla.sla_id = s.sla_id

    join analytics.dim_contractor c
        on i.contractor_id = c.contractor_id

    where i.issue_type = 'Incident'
      and isla.sla_stop_at is not null

    group by
        date_trunc('month', i.created_at)::date,
        c.contractor_name
),

task_performance as (

    select
        date_trunc('month', i.due_date)::date as month,
        c.contractor_name,

        count(*) as total_tasks,

        count(*) filter (where i.resolved_at <= i.due_date) as on_time_tasks,

        count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

        round(100.0 * count(*) filter (where i.resolved_at <= i.due_date) / nullif(count(*), 0),
            2) as on_time_rate_pct,

        round(sum(greatest(
                    extract(epoch from (i.resolved_at - i.due_date)) / 3600,
                    0))::numeric,2) as total_task_delay_hours

    from analytics.fact_issue i

    join analytics.dim_contractor c
        on i.contractor_id = c.contractor_id

    where i.issue_type = 'Task'
      and i.resolved_at is not null
      and i.due_date is not null

    group by
        date_trunc('month', i.due_date)::date,
        c.contractor_name
)

select
    ip.month,
    ip.contractor_name,

    ip.total_incidents,
    ip.sla_complied,
    ip.sla_breached,
    ip.sla_compliance_pct,
    ip.total_sla_excess_hours,

    tp.total_tasks,
    tp.on_time_tasks,
    tp.overdue_tasks,
    tp.on_time_rate_pct,
    tp.total_task_delay_hours

from incident_performance ip

join task_performance tp
    on ip.month = tp.month
   and ip.contractor_name = tp.contractor_name

order by
    ip.month,
    ip.contractor_name;