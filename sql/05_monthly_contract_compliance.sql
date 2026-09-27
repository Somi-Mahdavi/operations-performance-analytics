-- ============================================================
-- 05. monthly contract compliance and invoice verification
-- ============================================================

-- business scenario:
-- before approving a contractor's monthly invoice, contractual performance is reviewed for the billing month.

-- incident sla requirements depend on priority and location group.
-- for every breached incident, the time exceeding the contractual
-- sla target is calculated.
--
-- planned contractual tasks are also reviewed against their due dates.
-- for overdue tasks, the delay beyond the contractual deadline is
-- calculated.
--
-- this analysis uses june 2026 as an example billing month.
--
-- the results provide the operational basis for monthly invoice
-- verification and possible contractual deductions according to
-- the applicable contract rules.
-- ============================================================


-- ============================================================
-- 1. incident sla performance by contractor, priority and location
-- review the contractual sla performance for the billing month.
-- ============================================================

select
    c.contractor_name,
    i.priority,
    s.location_group,

    s.target_minutes,
    round(s.target_minutes / 60.0, 2) as target_hours,

    count(*) as total_incidents,

    count(*) filter (
        where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 <= s.target_minutes
    ) as sla_complied,

    count(*) filter (
        where extract(epoch from  (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes
    ) as sla_breached,

    round(
        100.0 * count(*) filter (where extract(epoch from
                (isla.sla_stop_at - isla.sla_start_at)) / 60 <= s.target_minutes) / nullif(count(*), 0),
        2) as sla_compliance_pct

from analytics.fact_issue as i

join analytics.fact_issue_sla as isla
    on i.issue_id = isla.issue_id

join analytics.dim_sla as s
    on isla.sla_id = s.sla_id

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'
  and isla.sla_stop_at is not null
  and i.created_at >= timestamp '2026-06-01'
  and i.created_at < timestamp '2026-07-01'

group by
    c.contractor_name,
    i.priority,
    s.location_group,
    s.target_minutes

order by
    c.contractor_name,
    i.priority,
    s.location_group;


-- ============================================================
-- 2. sla breach summary for invoice verification
-- calculate the total contractual sla excess for breached incidents by contractor, priority and location group.
-- ============================================================

select
    c.contractor_name,
    i.priority,
    s.location_group,

    s.target_minutes,
    round(s.target_minutes / 60.0, 2) as target_hours,

    count(*) filter (
		where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes) 
		as sla_breached,

    round(
        sum(
            greatest(
              extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 - s.target_minutes, 0))::numeric
			  , 2) as total_sla_excess_minutes,

    round(
        sum(
            greatest(
                extract(epoch from
                    (isla.sla_stop_at - isla.sla_start_at)) / 3600 - s.target_minutes / 60.0, 0)
        )::numeric,2) as total_sla_excess_hours

from analytics.fact_issue as i

join analytics.fact_issue_sla as isla
    on i.issue_id = isla.issue_id

join analytics.dim_sla as s
    on isla.sla_id = s.sla_id

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'
  and isla.sla_stop_at is not null
  and i.created_at >= timestamp '2026-06-01'
  and i.created_at < timestamp '2026-07-01'

group by
    c.contractor_name,
    i.priority,
    s.location_group,
    s.target_minutes

having count(*) filter (
    where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes) > 0

order by
    c.contractor_name,
    i.priority,
    s.location_group;


-- ============================================================
-- 3. sla breach details: list every breached incident used as evidence for the
-- monthly invoice verification.
-- ============================================================

select
    c.contractor_name,

    i.issue_key,
    i.priority,
    s.location_group,

    s.target_minutes,
    round(s.target_minutes / 60.0, 2) as target_hours,

    isla.sla_start_at,
    isla.sla_stop_at,

    round((extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60)::numeric, 2) as actual_sla_minutes,

    round((
            extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 - s.target_minutes
        )::numeric,2) as sla_excess_minutes,

    round((
            extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 3600 - s.target_minutes / 60.0
        )::numeric, 2) as sla_excess_hours

from analytics.fact_issue as i

join analytics.fact_issue_sla as isla
    on i.issue_id = isla.issue_id

join analytics.dim_sla as s
    on isla.sla_id = s.sla_id

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Incident'
  and isla.sla_stop_at is not null

  and i.created_at >= timestamp '2026-06-01'
  and i.created_at < timestamp '2026-07-01'

  and extract(epoch from  (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes

order by
    c.contractor_name,
    i.priority,
    s.location_group,
    sla_excess_minutes desc;


-- ============================================================
-- 4. planned task compliance for the billing month
-- review whether contractual planned tasks were completed within their defined deadlines.
-- ============================================================

select
    c.contractor_name,

    count(*) as total_tasks,

    count(*) filter (where i.resolved_at <= i.due_date) as on_time_tasks,

    count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

    round(100.0 * count(*) filter (where i.resolved_at <= i.due_date) / nullif(count(*), 0), 2) as on_time_rate_pct,

    round(sum(greatest(extract(epoch from (i.resolved_at - i.due_date)) / 3600, 0))::numeric,2) 
		as total_task_delay_hours

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
  and i.resolved_at is not null
  and i.due_date is not null

  and i.due_date >= timestamp '2026-06-01'
  and i.due_date < timestamp '2026-07-01'

group by  c.contractor_name

order by  c.contractor_name;


-- ============================================================
-- 5. overdue task details: list every overdue contractual task and calculate the delay
-- beyond the contractual due date.
-- ============================================================

select
    c.contractor_name,

    i.issue_key,
    i.category,

    i.created_at,
    i.due_date,
    i.resolved_at,

    round((extract(epoch from (i.resolved_at - i.due_date)) / 60)::numeric,2) as delay_minutes,

    round((extract(epoch from (i.resolved_at - i.due_date)) / 3600)::numeric,2 ) as delay_hours

from analytics.fact_issue as i

join analytics.dim_contractor as c
    on i.contractor_id = c.contractor_id

where i.issue_type = 'Task'
  and i.due_date is not null
  and i.resolved_at is not null
  and i.resolved_at > i.due_date

  and i.due_date >= timestamp '2026-06-01'
  and i.due_date < timestamp '2026-07-01'

order by   c.contractor_name, delay_hours desc;


-- ============================================================
-- 6. final monthly invoice verification summary
-- combine incident sla deviations and overdue planned-task delays into one contractor-level summary.

-- these values provide the operational basis for applying
-- contractual deductions. monetary deductions are not calculated
-- because penalty rates are defined separately in the contract.
-- ============================================================

with incident_performance as (

    select
        c.contractor_name,

        count(*) as total_incidents,

        count(*) filter (
            where extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 > s.target_minutes) as sla_breached,

        round(sum(greatest(
                    extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 60 - s.target_minutes,
                    0))::numeric,2 ) as total_sla_excess_minutes,

        round( sum(greatest(
                    extract(epoch from (isla.sla_stop_at - isla.sla_start_at)) / 3600
                        - s.target_minutes / 60.0, 0 ))::numeric,2) as total_sla_excess_hours

    from analytics.fact_issue as i

    join analytics.fact_issue_sla as isla
        on i.issue_id = isla.issue_id

    join analytics.dim_sla as s
        on isla.sla_id = s.sla_id

    join analytics.dim_contractor as c
        on i.contractor_id = c.contractor_id

    where i.issue_type = 'Incident'
      and isla.sla_stop_at is not null
      and i.created_at >= timestamp '2026-06-01'
      and i.created_at < timestamp '2026-07-01'

    group by  c.contractor_name
),

task_performance as (

    select
        c.contractor_name,

        count(*) as total_tasks,

        count(*) filter (where i.resolved_at > i.due_date) as overdue_tasks,

        round(sum(greatest(
                    extract(epoch from (i.resolved_at - i.due_date)) / 3600,
                    0))::numeric,2) as total_task_delay_hours

    from analytics.fact_issue as i

    join analytics.dim_contractor as c
        on i.contractor_id = c.contractor_id

    where i.issue_type = 'Task'
      and i.resolved_at is not null
      and i.due_date is not null
      and i.due_date >= timestamp '2026-06-01'
      and i.due_date < timestamp '2026-07-01'

    group by c.contractor_name
)

select
    date '2026-06-01' as billing_month,

    ip.contractor_name,

    ip.total_incidents,
    ip.sla_breached,
    ip.total_sla_excess_minutes,
    ip.total_sla_excess_hours,

    tp.total_tasks,
    tp.overdue_tasks,
    tp.total_task_delay_hours

from incident_performance as ip

join task_performance as tp
    on ip.contractor_name = tp.contractor_name

order by  ip.contractor_name;