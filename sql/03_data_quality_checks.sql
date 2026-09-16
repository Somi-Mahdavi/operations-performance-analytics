-- Data quality checks for generated ticketing data


-- 1. Row counts

SELECT 'tickets' AS table_name, COUNT(*) AS row_count
FROM tickets

UNION ALL

SELECT 'ticket_assignments', COUNT(*)
FROM ticket_assignments

UNION ALL

SELECT 'ticket_events', COUNT(*)
FROM ticket_events;


-- 2. Duplicate business ticket numbers

SELECT
    ticket_number,
    COUNT(*) AS duplicate_count
FROM tickets
GROUP BY ticket_number
HAVING COUNT(*) > 1;


-- 3. Missing required ticket values

SELECT
    COUNT(*) FILTER (WHERE ticket_number IS NULL) AS missing_ticket_number,
    COUNT(*) FILTER (WHERE title IS NULL) AS missing_title,
    COUNT(*) FILTER (WHERE status_id IS NULL) AS missing_status,
    COUNT(*) FILTER (WHERE priority_id IS NULL) AS missing_priority,
    COUNT(*) FILTER (WHERE site_id IS NULL) AS missing_site,
    COUNT(*) FILTER (WHERE asset_id IS NULL) AS missing_asset,
    COUNT(*) FILTER (WHERE contract_id IS NULL) AS missing_contract,
    COUNT(*) FILTER (WHERE current_contractor_id IS NULL) AS missing_contractor,
    COUNT(*) FILTER (WHERE created_at IS NULL) AS missing_created_at
FROM tickets;


-- 4. Ticket lifecycle timestamps

SELECT
    COUNT(*) FILTER (
        WHERE first_response_at < created_at
    ) AS response_before_creation,

    COUNT(*) FILTER (
        WHERE resolved_at <= first_response_at
    ) AS resolution_before_response,

    COUNT(*) FILTER (
        WHERE closed_at <= resolved_at
    ) AS closure_before_resolution
FROM tickets;


-- 5. Master-data references

SELECT
    COUNT(*) FILTER (WHERE a.asset_id IS NULL) AS invalid_asset,
    COUNT(*) FILTER (WHERE s.site_id IS NULL) AS invalid_site,
    COUNT(*) FILTER (WHERE c.contract_id IS NULL) AS invalid_contract,
    COUNT(*) FILTER (WHERE ct.contractor_id IS NULL) AS invalid_contractor,
    COUNT(*) FILTER (WHERE p.priority_id IS NULL) AS invalid_priority,
    COUNT(*) FILTER (WHERE ts.status_id IS NULL) AS invalid_status
FROM tickets t
LEFT JOIN assets a
    ON t.asset_id = a.asset_id
LEFT JOIN sites s
    ON t.site_id = s.site_id
LEFT JOIN contracts c
    ON t.contract_id = c.contract_id
LEFT JOIN contractors ct
    ON t.current_contractor_id = ct.contractor_id
LEFT JOIN priorities p
    ON t.priority_id = p.priority_id
LEFT JOIN ticket_statuses ts
    ON t.status_id = ts.status_id;


-- 6. Tickets without an applicable SLA rule

SELECT
    COUNT(*) AS tickets_without_matching_sla
FROM tickets t
JOIN sites s
    ON t.site_id = s.site_id
LEFT JOIN sla_rules sr
    ON sr.contract_id = t.contract_id
    AND sr.priority_id = t.priority_id
    AND sr.location_class = s.location_class
WHERE sr.sla_rule_id IS NULL;


-- 7. Assignment coverage

WITH assignment_counts AS (
    SELECT
        ticket_id,
        COUNT(*) AS assignment_count
    FROM ticket_assignments
    GROUP BY ticket_id
)

SELECT
    COUNT(*) FILTER (
        WHERE ac.ticket_id IS NULL
    ) AS tickets_without_assignment,

    COUNT(*) FILTER (
        WHERE ac.assignment_count > 1
    ) AS tickets_with_multiple_assignments
FROM tickets t
LEFT JOIN assignment_counts ac
    ON t.ticket_id = ac.ticket_id;


-- 8. Assignment timestamp checks

SELECT
    COUNT(*) FILTER (
        WHERE ta.assigned_at < t.created_at
    ) AS assignment_before_creation,

    COUNT(*) FILTER (
        WHERE ta.accepted_at IS NOT NULL
          AND ta.accepted_at < ta.assigned_at
    ) AS acceptance_before_assignment,

    COUNT(*) FILTER (
        WHERE ta.ended_at IS NOT NULL
          AND ta.ended_at < ta.assigned_at
    ) AS assignment_end_before_start
FROM ticket_assignments ta
JOIN tickets t
    ON ta.ticket_id = t.ticket_id;


-- 9. Rejected assignments should not have an acceptance timestamp

SELECT
    COUNT(*) AS rejected_assignments_with_acceptance
FROM ticket_assignments
WHERE assignment_status = 'Rejected'
  AND accepted_at IS NOT NULL;


-- 10. Event coverage per ticket

WITH event_counts AS (
    SELECT
        ticket_id,
        COUNT(*) AS event_count
    FROM ticket_events
    GROUP BY ticket_id
)

SELECT
    COUNT(*) FILTER (
        WHERE ec.ticket_id IS NULL
    ) AS tickets_without_events,

    MIN(ec.event_count) AS min_events_per_ticket,
    MAX(ec.event_count) AS max_events_per_ticket
FROM tickets t
LEFT JOIN event_counts ec
    ON t.ticket_id = ec.ticket_id;


-- 11. Event timestamps outside the ticket lifecycle

SELECT
    COUNT(*) FILTER (
        WHERE te.event_at < t.created_at
    ) AS events_before_creation,

    COUNT(*) FILTER (
        WHERE te.event_at > t.closed_at
    ) AS events_after_closure
FROM ticket_events te
JOIN tickets t
    ON te.ticket_id = t.ticket_id;