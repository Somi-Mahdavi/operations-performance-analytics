-- ticket-level analytical view

drop view if exists vw_ticket_analysis;

create view vw_ticket_analysis as

with assignment_summary as (
    select
        ticket_id,
        count(*) as assignment_count,
        min(assigned_at) as first_assigned_at,
        min(accepted_at) as first_accepted_at,
        count(*) filter (
            where assignment_status = 'Rejected'
        ) as rejection_count
    from ticket_assignments
    group by ticket_id
)

select
    t.ticket_id,
    t.ticket_number,
    t.title,
    t.category,
    t.source,

    t.created_at,
    t.first_response_at,
    t.resolved_at,
    t.closed_at,

    p.priority_name,
    p.priority_rank,

    ts.status_name,

    a.asset_id,
    a.asset_code,
    a.asset_name,
    a.asset_type,

    s.site_id,
    s.site_code,
    s.site_name,
    s.location_class,

    c.contract_id,
    c.contract_number,
    c.contract_name,
    c.contract_type,

    ct.contractor_id,
    ct.contractor_code,
    ct.contractor_name,

    sr.response_target_minutes,
    sr.resolution_target_minutes,

    coalesce(asm.assignment_count, 0) as assignment_count,
    coalesce(asm.rejection_count, 0) as rejection_count,

    asm.first_assigned_at,
    asm.first_accepted_at,

    case
        when coalesce(asm.assignment_count, 0) > 1 then true
        else false
    end as is_reassigned,

    extract(
        epoch from (t.first_response_at - t.created_at)
        ) / 60.0 as response_time_minutes,

    extract(
        epoch from (t.resolved_at - t.created_at)
        ) / 60.0 as resolution_time_minutes,

    extract(
        epoch from (asm.first_assigned_at - t.created_at)
        ) / 60.0 as assignment_delay_minutes,

    case
        when extract(
            epoch from (t.first_response_at - t.created_at)
        ) / 60.0 > sr.response_target_minutes
        then true
        else false
    end as response_sla_breached,

    case
        when extract(
            epoch from (t.resolved_at - t.created_at)
        ) / 60.0 > sr.resolution_target_minutes
        then true
        else false
    end as resolution_sla_breached

from tickets t

join priorities p
    on t.priority_id = p.priority_id

join ticket_statuses ts
    on t.status_id = ts.status_id

join assets a
    on t.asset_id = a.asset_id

join sites s
    on t.site_id = s.site_id

join contracts c
    on t.contract_id = c.contract_id

join contractors ct
    on t.current_contractor_id = ct.contractor_id

left join sla_rules sr
    on sr.contract_id = t.contract_id
    and sr.priority_id = t.priority_id
    and sr.location_class = s.location_class

left join assignment_summary asm
    on t.ticket_id = asm.ticket_id;


-- validate analytical view

select count(*)
from vw_ticket_analysis;


select
    count(*) as total_rows,
    count(distinct ticket_id) as unique_tickets
from vw_ticket_analysis;


-- check calculated sla fields

select
    ticket_number,
    response_time_minutes,
    response_target_minutes,
    response_sla_breached,
    resolution_time_minutes,
    resolution_target_minutes,
    resolution_sla_breached
from vw_ticket_analysis
limit 20;