-- ============================================================
-- Exploratory Data Analysis
-- ============================================================
-- This analysis looks at ticket volume, operational performance,
-- SLA compliance, contractor performance, and assignment behavior.
-- The analysis starts with overall distributions and then looks
-- more closely at factors associated with slower resolution or
-- higher SLA breach rates.


-- ------------------------------------------------------------
-- Ticket volume over time
-- ------------------------------------------------------------
-- Build a complete monthly timeline so that months with no tickets would still appear in the result.

with months as (
    select generate_series(
        date_trunc('month', min(created_at)),
        date_trunc('month', max(created_at)),
        interval '1 month'
    ) as month
    from vw_ticket_analysis
),

monthly_tickets as (
    select
        date_trunc('month', created_at) as month,
        count(*) as ticket_count
    from vw_ticket_analysis
    group by date_trunc('month', created_at)
)

select
    m.month,
    coalesce(mt.ticket_count, 0) as ticket_count
from months m
left join monthly_tickets mt
    on m.month = mt.month
order by m.month;


-- ------------------------------------------------------------
-- Ticket distribution by priority
-- ------------------------------------------------------------
-- Check how the workload is distributed across priority levels.

select
    priority_name,
    count(*) as ticket_count,
    round( 100.0 * count(*) / sum(count(*)) over (), 2 ) as percentage
from vw_ticket_analysis
group by priority_name, priority_rank
order by priority_rank;


-- ------------------------------------------------------------
-- Ticket distribution by category
-- ------------------------------------------------------------
-- Identify the categories responsible for the largest share of tickets.

select
    category,
    count(*) as ticket_count,
    round( 100.0 * count(*) / sum(count(*)) over (),  2 ) as percentage
from vw_ticket_analysis
group by category
order by ticket_count desc;


-- ------------------------------------------------------------
-- Ticket distribution by asset type
-- ------------------------------------------------------------
-- Check which types of assets generate the most tickets.

select
    asset_type,
    count(*) as ticket_count,
    round( 100.0 * count(*) / sum(count(*)) over (),  2 ) as percentage
from vw_ticket_analysis
group by asset_type
order by ticket_count desc;


-- ------------------------------------------------------------
-- Ticket volume by site
-- ------------------------------------------------------------
-- Compare ticket volume across sites and location classes.

select
    site_name,
    location_class,
    count(*) as ticket_count
from vw_ticket_analysis
group by site_name, location_class
order by ticket_count desc;


-- ------------------------------------------------------------
-- Ticket volume by contractor
-- ------------------------------------------------------------
-- Check how the ticket workload is distributed across contractors.

select
    contractor_name,
    count(*) as ticket_count,
    round( 100.0 * count(*) / sum(count(*)) over (),  2 ) as percentage
from vw_ticket_analysis
group by contractor_name
order by ticket_count desc;


-- ------------------------------------------------------------
-- Reassignment distribution
-- ------------------------------------------------------------
-- Measure how often tickets require more than one assignment.

select
    is_reassigned,
    count(*) as ticket_count,
    round( 100.0 * count(*) / sum(count(*)) over (),  2  ) as percentage
from vw_ticket_analysis
group by is_reassigned
order by is_reassigned;


-- ------------------------------------------------------------
-- Response and resolution time distribution
-- ------------------------------------------------------------
-- Compare average and median times to check for unusually slow tickets.
select
    round(avg(response_time_minutes), 2) as avg_response_time,

    round(
        percentile_cont(0.5) within group (order by response_time_minutes)::numeric,
        2 ) as median_response_time,

    round(min(response_time_minutes), 2) as min_response_time,
    round(max(response_time_minutes), 2) as max_response_time,

    round(avg(resolution_time_minutes), 2) as avg_resolution_time,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time,

    round(min(resolution_time_minutes), 2) as min_resolution_time,
    round(max(resolution_time_minutes), 2) as max_resolution_time

from vw_ticket_analysis;


-- ------------------------------------------------------------
-- Response and resolution time percentiles
-- ------------------------------------------------------------
-- Check the higher percentiles to understand the slower end of ticket performance.

select
    round(
        percentile_cont(0.75) within group (order by response_time_minutes)::numeric,
        2  ) as p75_response_time,

    round(
        percentile_cont(0.90) within group (order by response_time_minutes)::numeric,
        2  ) as p90_response_time,

    round(
        percentile_cont(0.95) within group (order by response_time_minutes)::numeric,
        2  ) as p95_response_time,

    round(
        percentile_cont(0.75) within group (order by resolution_time_minutes)::numeric,
        2  ) as p75_resolution_time,

    round(
        percentile_cont(0.90) within group (order by resolution_time_minutes)::numeric,
        2  ) as p90_resolution_time,

    round(
        percentile_cont(0.95) within group (order by resolution_time_minutes)::numeric,
        2  ) as p95_resolution_time

from vw_ticket_analysis;


-- ------------------------------------------------------------
-- Response and resolution performance by priority
-- ------------------------------------------------------------
-- Check whether higher-priority tickets are handled faster.

select
    priority_name,
    count(*) as ticket_count,

    round(avg(response_time_minutes), 2) as avg_response_time,

    round(
        percentile_cont(0.5) within group (order by response_time_minutes)::numeric,
        2  ) as median_response_time,

    round(avg(resolution_time_minutes), 2) as avg_resolution_time,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time

from vw_ticket_analysis

group by
    priority_name,
    priority_rank

order by priority_rank;


-- ------------------------------------------------------------
-- Resolution performance by reassignment status
-- ------------------------------------------------------------
-- -- Compare resolution times for reassigned and non-reassigned tickets.

select
    is_reassigned,
    count(*) as ticket_count,

    round(avg(resolution_time_minutes), 2) as avg_resolution_time,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time,

    round(
        percentile_cont(0.90) within group (order by resolution_time_minutes)::numeric,
        2  ) as p90_resolution_time

from vw_ticket_analysis

group by is_reassigned
order by is_reassigned;


-- ------------------------------------------------------------
-- Reassignment impact within each priority
-- ------------------------------------------------------------
-- -- Compare reassigned and non-reassigned tickets within each priority.

select
    priority_name,
    is_reassigned,
    count(*) as ticket_count,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time,

    round(avg(resolution_time_minutes), 2) as avg_resolution_time

from vw_ticket_analysis

group by
    priority_name,
    priority_rank,
    is_reassigned

order by
    priority_rank,
    is_reassigned;


-- ------------------------------------------------------------
-- Contractor performance
-- ------------------------------------------------------------
-- -- Compare resolution performance across contractors.

select
    contractor_name,
    count(*) as ticket_count,

    round(
        percentile_cont(0.5) within group (order by response_time_minutes)::numeric,
        2 ) as median_response_time,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time,

    round(
        percentile_cont(0.90) within group (order by resolution_time_minutes)::numeric,
        2  ) as p90_resolution_time

from vw_ticket_analysis

group by contractor_name

order by median_resolution_time;


-- ------------------------------------------------------------
-- Contractor performance within each priority
-- ------------------------------------------------------------
-- -- Compare contractors for tickets with the same priority.

select
    priority_name,
    contractor_name,
    count(*) as ticket_count,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time,

    round(
        percentile_cont(0.90) within group (order by resolution_time_minutes)::numeric,
        2  ) as p90_resolution_time

from vw_ticket_analysis

group by
    priority_name,
    priority_rank,
    contractor_name

order by
    priority_rank,
    median_resolution_time;


-- ------------------------------------------------------------
-- Overall SLA performance
-- ------------------------------------------------------------
--  Check the overall response and resolution SLA breach rates.

select
    count(*) as total_tickets,

    count(*) filter (where response_sla_breached = true) as response_sla_breaches,

    round(
        100.0 * count(*) filter (where response_sla_breached = true) / count(*),
        2   ) as response_sla_breach_rate,

    count(*) filter (where resolution_sla_breached = true) as resolution_sla_breaches,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*),
        2   ) as resolution_sla_breach_rate

from vw_ticket_analysis;


-- ------------------------------------------------------------
-- SLA performance by priority
-- ------------------------------------------------------------
-- Check whether SLA compliance differs across priority levels.

select
    priority_name,
    count(*) as ticket_count,

    count(*) filter (where response_sla_breached = true) as response_sla_breaches,

    round(
        100.0 * count(*) filter (where response_sla_breached = true) / count(*),
        2  ) as response_sla_breach_rate,

    count(*) filter (where resolution_sla_breached = true) as resolution_sla_breaches,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*),
        2  ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by
    priority_name,
    priority_rank

order by priority_rank;

-- ------------------------------------------------------------
-- SLA performance by contractor
-- ------------------------------------------------------------
-- Compare overall SLA compliance across contractors.

select
    contractor_name,
    count(*) as ticket_count,

    count(*) filter (where response_sla_breached = true) as response_sla_breaches,

    round(
        100.0 * count(*) filter (where response_sla_breached = true) / count(*),
        2  ) as response_sla_breach_rate,

    count(*) filter (where resolution_sla_breached = true) as resolution_sla_breaches,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*),
        2  ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by contractor_name

order by resolution_sla_breach_rate;


-- ------------------------------------------------------------
-- SLA performance by contractor within priority
-- ------------------------------------------------------------
--  Compare contractors for tickets with the same priority.

select
    priority_name,
    contractor_name,
    count(*) as ticket_count,

    round(
        100.0 * count(*) filter (where response_sla_breached = true) / count(*),
        2  ) as response_sla_breach_rate,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*),
        2   ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by
    priority_name,
    priority_rank,
    contractor_name

order by
    priority_rank,
    resolution_sla_breach_rate;


-- ------------------------------------------------------------
-- SLA performance by reassignment status
-- ------------------------------------------------------------
-- Check whether reassigned tickets have higher SLA breach rates.

select
    is_reassigned,
    count(*) as ticket_count,

    round(
        100.0 * count(*) filter (where response_sla_breached = true) / count(*),
        2  ) as response_sla_breach_rate,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*),
        2  ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by is_reassigned

order by is_reassigned;


-- ------------------------------------------------------------
-- SLA performance by reassignment within priority
-- ------------------------------------------------------------
-- Repeat the reassignment comparison within each priority to check
-- whether the overall difference remains after accounting for priority.

select
    priority_name,
    is_reassigned,
    count(*) as ticket_count,

    round(
        100.0 * count(*) filter ( where response_sla_breached = true ) / count(*),
        2   ) as response_sla_breach_rate,

    round(
        100.0 * count(*) filter ( where resolution_sla_breached = true ) / count(*),
        2   ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by
    priority_name,
    priority_rank,
    is_reassigned

order by
    priority_rank,
    is_reassigned;


-- ------------------------------------------------------------
-- SLA performance by asset type
-- ------------------------------------------------------------
-- Look for asset types with unusually high SLA breach rates rather
-- than relying only on their ticket volume.

select
    asset_type,
    count(*) as ticket_count,

    round(
        100.0 * count(*) filter ( where response_sla_breached = true ) / count(*),
        2    ) as response_sla_breach_rate,

    round(
        100.0 * count(*) filter ( where resolution_sla_breached = true ) / count(*),
        2   ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by asset_type

order by resolution_sla_breach_rate desc;


-- ------------------------------------------------------------
-- SLA performance by site
-- ------------------------------------------------------------
-- Check whether any site stands out as a potential SLA performance
-- hotspot.

select
    site_name,
    location_class,
    count(*) as ticket_count,

    round(
        100.0 * count(*) filter ( where response_sla_breached = true ) / count(*),
        2  ) as response_sla_breach_rate,

    round(
        100.0 * count(*) filter ( where resolution_sla_breached = true ) / count(*),
        2   ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by
    site_name,
    location_class

order by resolution_sla_breach_rate desc;


-- ------------------------------------------------------------
-- Monthly ticket volume and SLA performance
-- ------------------------------------------------------------
--  Check monthly SLA breach rates to see if performance improves or gets worse over time.

select
    date_trunc('month', created_at) as month,
    count(*) as ticket_count,

    round(
        100.0 * count(*) filter (where response_sla_breached = true ) / count(*),
        2    ) as response_sla_breach_rate,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true ) / count(*),
        2    ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by date_trunc('month', created_at)

order by month;


-- ------------------------------------------------------------
-- Month-over-month change in ticket volume and SLA performance
-- ------------------------------------------------------------
-- Compare each month with the previous month.

with monthly_performance as (
    select
        date_trunc('month', created_at) as month,
        count(*) as ticket_count,

        100.0 * count(*) filter (where response_sla_breached = true) / count(*)
            as response_sla_breach_rate,

        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*)
            as resolution_sla_breach_rate

    from vw_ticket_analysis

    group by date_trunc('month', created_at)
),

monthly_change as (
    select
        month,
        ticket_count,
        response_sla_breach_rate,
        resolution_sla_breach_rate,

        lag(ticket_count) over (order by month) as previous_month_ticket_count,

        lag(resolution_sla_breach_rate) over (order by month)
            as previous_month_resolution_breach_rate

    from monthly_performance
)

select
    month,
    ticket_count,
    previous_month_ticket_count,

    round(
        100.0 * (ticket_count - previous_month_ticket_count)
        / nullif(previous_month_ticket_count, 0),
        2
    ) as ticket_count_mom_pct,

    round(response_sla_breach_rate::numeric, 2)
        as response_sla_breach_rate,

    round(resolution_sla_breach_rate::numeric, 2)
        as resolution_sla_breach_rate,

    round(
        100.0 * (resolution_sla_breach_rate - previous_month_resolution_breach_rate)
        / nullif(previous_month_resolution_breach_rate, 0),
        2
    ) as resolution_sla_breach_mom_pct

from monthly_change

order by month;

-- ------------------------------------------------------------
-- Monthly workload vs. SLA performance
-- ------------------------------------------------------------
-- Test whether months with more tickets also tend to have higher
-- response or resolution SLA breach rates.

with monthly_performance as (
    select
        date_trunc('month', created_at) as month,
        count(*) as ticket_count,

        100.0 * count(*) filter (where response_sla_breached = true) / count(*) as response_sla_breach_rate,

        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*) as resolution_sla_breach_rate

    from vw_ticket_analysis

    group by date_trunc('month', created_at)
)

select
    round(
        corr(ticket_count,response_sla_breach_rate)::numeric,
        3    ) as correlation_volume_response_breach,

    round(
        corr( ticket_count,resolution_sla_breach_rate)::numeric,
        3    ) as correlation_volume_resolution_breach

from monthly_performance;


-- ------------------------------------------------------------
-- Assignment delay vs. resolution time
-- ------------------------------------------------------------
-- Check whether tickets that take longer to assign also tend to take
-- longer to resolve.

select
    round(
        corr(assignment_delay_minutes,resolution_time_minutes)::numeric,
        3  ) as correlation_assignment_delay_resolution

from vw_ticket_analysis

where assignment_delay_minutes is not null
  and resolution_time_minutes is not null;


-- ------------------------------------------------------------
-- Performance by assignment rejection
-- ------------------------------------------------------------
-- Compare tickets with and without assignment rejections to see
-- whether rejection is associated with slower resolution and more
-- frequent resolution SLA breaches.

select
    case
        when rejection_count = 0 then 'no rejection'
        else 'one or more rejections'
    end as rejection_group,

    count(*) as ticket_count,

    round(
        percentile_cont(0.5) within group (order by resolution_time_minutes)::numeric,
        2  ) as median_resolution_time,

    round(
        100.0 * count(*) filter (where resolution_sla_breached = true) / count(*),
        2  ) as resolution_sla_breach_rate

from vw_ticket_analysis

group by
    case
        when rejection_count = 0 then 'no rejection'
        else 'one or more rejections'
    end;
