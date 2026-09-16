/* ============================================================
   TELECOM CONTRACTOR OPERATIONS ANALYTICS
   Schema and Master Data Validation

   Purpose:
   Validate table relationships, reference data completeness,
   SLA coverage, and master-data loading before generating and
   analyzing transactional ticket data.
   ============================================================ */


/* ============================================================
   1. VALIDATE ASSET → SITE → CONTRACT → CONTRACTOR

   Purpose:
   Confirm that every asset can be traced to:
   - its operational site
   - its supporting contract
   - the contractor responsible for that contract
   ============================================================ */

SELECT
    a.asset_id,
    a.asset_code,
    a.asset_name,
    a.asset_type,

    s.site_id,
    s.site_code,
    s.site_name,
    s.city,
    s.region,
    s.location_class,

    c.contract_id,
    c.contract_number,
    c.contract_name,

    ct.contractor_id,
    ct.contractor_code,
    ct.contractor_name

FROM assets a

JOIN sites s
    ON a.site_id = s.site_id

JOIN contracts c
    ON a.contract_id = c.contract_id

JOIN contractors ct
    ON c.contractor_id = ct.contractor_id

ORDER BY a.asset_id;


/* ============================================================
   2. VALIDATE CONTRACT → CONTRACTOR

   Purpose:
   Confirm that every contract belongs to a valid contractor.
   ============================================================ */

SELECT
    c.contract_id,
    c.contract_number,
    c.contract_name,
    c.contract_type,
    c.start_date,
    c.end_date,
    c.contract_status,

    ct.contractor_id,
    ct.contractor_code,
    ct.contractor_name

FROM contracts c

JOIN contractors ct
    ON c.contractor_id = ct.contractor_id

ORDER BY c.contract_id;


/* ============================================================
   3. VALIDATE SLA RULES

   Purpose:
   Check that SLA rules are correctly connected to:
   - contract
   - contractor
   - priority
   - location class

   This allows us to read IDs as business information.
   ============================================================ */

SELECT
    sr.sla_rule_id,

    c.contract_number,
    c.contract_name,

    ct.contractor_name,

    p.priority_name,
    p.priority_rank,

    sr.location_class,
    sr.response_target_minutes,
    sr.resolution_target_minutes

FROM sla_rules sr

JOIN contracts c
    ON sr.contract_id = c.contract_id

JOIN contractors ct
    ON c.contractor_id = ct.contractor_id

JOIN priorities p
    ON sr.priority_id = p.priority_id

ORDER BY
    c.contract_id,
    p.priority_rank,
    sr.location_class;


/* ============================================================
   4. CHECK SLA COMPLETENESS

   Expected:
       4 contracts
     × 4 priorities
     × 2 location classes
     = 32 SLA rules

   Purpose:
   Confirm that no required SLA combination is missing.
   ============================================================ */

SELECT
    COUNT(*) AS actual_sla_rule_count,
    4 * 4 * 2 AS expected_sla_rule_count

FROM sla_rules;


/* ============================================================
   5. CHECK SLA RULE COUNT PER CONTRACT

   Each contract should have:
       4 priorities × 2 location classes = 8 rules
   ============================================================ */

SELECT
    c.contract_id,
    c.contract_number,
    ct.contractor_name,
    COUNT(sr.sla_rule_id) AS sla_rule_count

FROM contracts c

JOIN contractors ct
    ON c.contractor_id = ct.contractor_id

LEFT JOIN sla_rules sr
    ON c.contract_id = sr.contract_id

GROUP BY
    c.contract_id,
    c.contract_number,
    ct.contractor_name

ORDER BY c.contract_id;


/* ============================================================
   6. CHECK SLA COMBINATION COMPLETENESS

   Purpose:
   Verify that each contract has an SLA for every
   priority/location combination.
   ============================================================ */

SELECT
    c.contract_number,
    p.priority_name,
    lc.location_class,

    CASE
        WHEN sr.sla_rule_id IS NULL THEN 'MISSING'
        ELSE 'OK'
    END AS validation_status

FROM contracts c

CROSS JOIN priorities p

CROSS JOIN (
    VALUES
        ('Central'),
        ('Regional')
) AS lc(location_class)

LEFT JOIN sla_rules sr
    ON sr.contract_id = c.contract_id
    AND sr.priority_id = p.priority_id
    AND sr.location_class = lc.location_class

ORDER BY
    c.contract_id,
    p.priority_rank,
    lc.location_class;


/* ============================================================
   7. VALIDATE TASK TEMPLATES

   Purpose:
   Confirm that recurring contractual obligations are connected
   to the correct contract and contractor.
   ============================================================ */

SELECT
    tt.template_id,

    c.contract_number,
    c.contract_name,

    ct.contractor_name,

    tt.task_name,
    tt.task_type,
    tt.frequency,
    tt.due_days,
    tt.active

FROM task_templates tt

JOIN contracts c
    ON tt.contract_id = c.contract_id

JOIN contractors ct
    ON c.contractor_id = ct.contractor_id

ORDER BY tt.template_id;


/* ============================================================
   8. MASTER TABLE ROW COUNTS

   Purpose:
   Create a quick overview to confirm that reference/master
   tables were loaded as expected.
   ============================================================ */

SELECT
    'contractors' AS table_name,
    COUNT(*) AS row_count
FROM contractors

UNION ALL

SELECT
    'contracts',
    COUNT(*)
FROM contracts

UNION ALL

SELECT
    'sites',
    COUNT(*)
FROM sites

UNION ALL

SELECT
    'assets',
    COUNT(*)
FROM assets

UNION ALL

SELECT
    'priorities',
    COUNT(*)
FROM priorities

UNION ALL

SELECT
    'ticket_statuses',
    COUNT(*)
FROM ticket_statuses

UNION ALL

SELECT
    'sla_rules',
    COUNT(*)
FROM sla_rules

UNION ALL

SELECT
    'task_templates',
    COUNT(*)
FROM task_templates;


/* ============================================================
   9. CHECK FOR ASSETS WITHOUT VALID SITES

   Expected result:
   0 rows
   ============================================================ */

SELECT
    a.asset_id,
    a.asset_code

FROM assets a

LEFT JOIN sites s
    ON a.site_id = s.site_id

WHERE s.site_id IS NULL;


/* ============================================================
   10. CHECK FOR ASSETS WITHOUT VALID CONTRACTS

   Expected result:
   0 rows
   ============================================================ */

SELECT
    a.asset_id,
    a.asset_code

FROM assets a

LEFT JOIN contracts c
    ON a.contract_id = c.contract_id

WHERE c.contract_id IS NULL;


/* ============================================================
   11. CHECK FOR CONTRACTS WITHOUT VALID CONTRACTORS

   Expected result:
   0 rows
   ============================================================ */

SELECT
    c.contract_id,
    c.contract_number

FROM contracts c

LEFT JOIN contractors ct
    ON c.contractor_id = ct.contractor_id

WHERE ct.contractor_id IS NULL;


/* ============================================================
   12. CHECK FOR INVALID SLA REFERENCES

   Expected result:
   0 rows
   ============================================================ */

SELECT
    sr.sla_rule_id,
    sr.contract_id,
    sr.priority_id

FROM sla_rules sr

LEFT JOIN contracts c
    ON sr.contract_id = c.contract_id

LEFT JOIN priorities p
    ON sr.priority_id = p.priority_id

WHERE
    c.contract_id IS NULL
    OR p.priority_id IS NULL;


/* ============================================================
   13. CHECK CONTRACT DATE LOGIC

   Purpose:
   Find contracts where the end date is not after the start date.

   Expected result:
   0 rows
   ============================================================ */

SELECT
    contract_id,
    contract_number,
    start_date,
    end_date

FROM contracts

WHERE end_date <= start_date;


/* ============================================================
   14. CHECK INVALID SLA TARGETS

   Purpose:
   Response/resolution targets must be positive,
   and resolution time should normally be >= response time.

   Expected result:
   0 rows
   ============================================================ */

SELECT
    sla_rule_id,
    contract_id,
    priority_id,
    location_class,
    response_target_minutes,
    resolution_target_minutes

FROM sla_rules

WHERE
    response_target_minutes <= 0
    OR resolution_target_minutes <= 0
    OR resolution_target_minutes < response_target_minutes;


/* ============================================================
   15. VALIDATE PRIORITY ORDER

   Purpose:
   Confirm the expected priority hierarchy.
   ============================================================ */

SELECT
    priority_id,
    priority_name,
    priority_rank

FROM priorities

ORDER BY priority_rank;


/* ============================================================
   16. VALIDATE TICKET STATUS REFERENCE DATA

   Purpose:
   Confirm that the expected ticket lifecycle statuses exist.
   ============================================================ */

SELECT
    status_id,
    status_name,
    is_closed

FROM ticket_statuses

ORDER BY status_id;


/* ============================================================
   VALIDATION SUMMARY

   Before generating ticket transactions, we validated:

   1. Asset → Site relationship
   2. Asset → Contract relationship
   3. Contract → Contractor relationship
   4. SLA relationships
   5. SLA completeness
   6. Recurring task templates
   7. Master-data row counts
   8. Foreign-key consistency
   9. Contract date logic
   10. SLA target logic

   Once these checks pass, the master/reference layer is ready
   for synthetic ticket generation and later analysis.
   ============================================================ */