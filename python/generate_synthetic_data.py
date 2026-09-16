# ============================================================
# TELECOM CONTRACTOR OPERATIONS ANALYTICS
# generate_synthetic_data.py
#
# Purpose:
# Generate reproducible synthetic incident data for a
# Jira-Service-Management-like contractor support workflow.
#
# The script:
# 1. Connects to PostgreSQL
# 2. Reads existing master/reference data
# 3. Generates 24 months of synthetic incidents
# 4. Assigns assets, priorities and SLA rules
# 5. Simulates manual/automatic ticket routing
# 6. Simulates reassignment cases
# 7. Generates lifecycle timestamps
# 8. Generates ticket events
# 9. Validates the data
# 10. Loads transactional data into PostgreSQL
# ============================================================


# ============================================================
# 1. IMPORT LIBRARIES
# ============================================================

from pathlib import Path
import os

import numpy as np
import pandas as pd

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


# ============================================================
# 2. LOAD DATABASE CREDENTIALS
# ============================================================

# Find the project root regardless of the current terminal folder.
PROJECT_ROOT = Path(__file__).resolve().parents[1]

load_dotenv(PROJECT_ROOT / ".env")

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


# ============================================================
# 3. CREATE POSTGRESQL CONNECTION
# ============================================================

database_url = URL.create(
    drivername="postgresql+psycopg2",
    username=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=int(DB_PORT),
    database=DB_NAME
)

engine = create_engine(database_url)


# Test connection
with engine.connect() as connection:

    database_name = connection.execute(
        text("SELECT current_database();")
    ).scalar()

    print("Database connection successful.")
    print("Connected database:", database_name)


# ============================================================
# 4. READ MASTER / REFERENCE DATA
# ============================================================

assets = pd.read_sql(
    """
    SELECT
        a.asset_id,
        a.asset_code,
        a.asset_name,
        a.asset_type,
        a.site_id,
        a.contract_id,

        s.site_name,
        s.location_class,

        c.contractor_id,

        ct.contractor_name

    FROM assets a

    JOIN sites s
        ON a.site_id = s.site_id

    JOIN contracts c
        ON a.contract_id = c.contract_id

    JOIN contractors ct
        ON c.contractor_id = ct.contractor_id

    ORDER BY a.asset_id;
    """,
    engine
)


priorities = pd.read_sql(
    """
    SELECT
        priority_id,
        priority_name,
        priority_rank

    FROM priorities

    ORDER BY priority_rank;
    """,
    engine
)


sla_rules = pd.read_sql(
    """
    SELECT
        sla_rule_id,
        contract_id,
        priority_id,
        location_class,
        response_target_minutes,
        resolution_target_minutes

    FROM sla_rules

    ORDER BY
        contract_id,
        priority_id,
        location_class;
    """,
    engine
)


statuses = pd.read_sql(
    """
    SELECT
        status_id,
        status_name,
        is_closed

    FROM ticket_statuses

    ORDER BY status_id;
    """,
    engine
)


print("\nMaster data loaded.")
print("Assets:", len(assets))
print("Priorities:", len(priorities))
print("SLA rules:", len(sla_rules))
print("Statuses:", len(statuses))


# ============================================================
# 5. SYNTHETIC DATA SETTINGS
# ============================================================

# Fixed random seed makes the generated dataset reproducible.
rng = np.random.default_rng(42)

N_TICKETS = 10000

# 24 COMPLETE historical months:
# August 2024 through July 2026
START_DATE = pd.Timestamp("2024-08-01")
END_DATE = pd.Timestamp("2026-08-01")


# ============================================================
# 6. CREATE THE 24 MONTHS
# ============================================================

months = pd.date_range(
    start=START_DATE,
    end=END_DATE - pd.offsets.MonthBegin(1),
    freq="MS"
)


# ============================================================
# 7. CREATE MONTHLY TICKET PATTERN
# ============================================================

# These are relative weights, not ticket counts.
# They introduce moderate operational variation.

base_month_weights = np.array([
    0.95, 0.90, 1.00, 1.05, 1.02, 1.08,
    1.12, 1.10, 0.92, 0.98, 1.05, 0.94,

    0.97, 0.93, 1.03, 1.08, 1.05, 1.11,
    1.15, 1.13, 0.96, 1.00, 1.07, 0.96
])


# Add small reproducible random variation around the pattern.
monthly_noise = rng.normal(
    loc=1.0,
    scale=0.04,
    size=len(months)
)

month_weights = (
    base_month_weights
    * monthly_noise
)


# Normalize weights into probabilities.
month_probabilities = (
    month_weights
    / month_weights.sum()
)


# Assign one month to each ticket.
selected_months = rng.choice(
    months,
    size=N_TICKETS,
    p=month_probabilities
)


# ============================================================
# 8. GENERATE EXACT CREATED_AT TIMESTAMP
# ============================================================

created_at_list = []

for month_start in selected_months:

    month_start = pd.Timestamp(month_start)

    month_end = (
        month_start
        + pd.offsets.MonthBegin(1)
    )

    seconds_in_month = int(
        (month_end - month_start)
        .total_seconds()
    )

    random_second = rng.integers(
        low=0,
        high=seconds_in_month
    )

    created_at_list.append(
        month_start
        + pd.to_timedelta(
            random_second,
            unit="s"
        )
    )


# ============================================================
# 9. CREATE TICKET DATAFRAME
# ============================================================

tickets = pd.DataFrame({
    "created_at": created_at_list
})


# Sort tickets chronologically.
tickets = (
    tickets
    .sort_values("created_at")
    .reset_index(drop=True)
)


# Generate business-facing ticket numbers.
tickets["ticket_number"] = [
    f"INC-{i:06d}"
    for i in range(
        1,
        len(tickets) + 1
    )
]


# ============================================================
# 10. ASSIGN ASSETS
# ============================================================

# Different assets have slightly different incident frequency.

asset_weights = rng.uniform(
    low=0.7,
    high=1.3,
    size=len(assets)
)

asset_probabilities = (
    asset_weights
    / asset_weights.sum()
)


tickets["asset_id"] = rng.choice(
    assets["asset_id"].to_numpy(),
    size=N_TICKETS,
    p=asset_probabilities
)


# Bring site, contract and contractor relationships
# from the master data.
tickets = tickets.merge(
    assets[
        [
            "asset_id",
            "asset_code",
            "asset_name",
            "asset_type",
            "site_id",
            "site_name",
            "location_class",
            "contract_id",
            "contractor_id",
            "contractor_name"
        ]
    ],

    on="asset_id",
    how="left",
    validate="many_to_one"
)


# ============================================================
# 11. ASSIGN PRIORITIES
# ============================================================

priority_names = np.array([
    "Critical",
    "High",
    "Medium",
    "Low"
])

priority_probabilities = np.array([
    0.06,
    0.17,
    0.45,
    0.32
])


tickets["priority_name"] = rng.choice(
    priority_names,
    size=N_TICKETS,
    p=priority_probabilities
)


# Get database priority_id.
tickets = tickets.merge(
    priorities[
        [
            "priority_id",
            "priority_name",
            "priority_rank"
        ]
    ],

    on="priority_name",
    how="left",
    validate="many_to_one"
)


# ============================================================
# 12. ATTACH THE APPLICABLE SLA RULE
# ============================================================

# SLA depends on:
# contract + priority + location class

tickets = tickets.merge(
    sla_rules[
        [
            "sla_rule_id",
            "contract_id",
            "priority_id",
            "location_class",
            "response_target_minutes",
            "resolution_target_minutes"
        ]
    ],

    on=[
        "contract_id",
        "priority_id",
        "location_class"
    ],

    how="left",
    validate="many_to_one"
)


missing_sla = (
    tickets["sla_rule_id"]
    .isna()
    .sum()
)

print(
    "\nTickets without SLA rule:",
    missing_sla
)


# ============================================================
# 13. GENERATE INCIDENT SOURCE
# ============================================================

source_names = np.array([
    "Monitoring",
    "NOC",
    "Service Desk",
    "Operations"
])

source_probabilities = np.array([
    0.45,
    0.30,
    0.15,
    0.10
])


tickets["source"] = rng.choice(
    source_names,
    size=N_TICKETS,
    p=source_probabilities
)


# ============================================================
# 14. GENERATE ROUTING MODE
# ============================================================

# Jira-like workflow:
#
# 1. Manual assignment at creation
# 2. Automatic assignment shortly after creation
# 3. Manual triage after ticket creation

routing_modes = np.array([
    "Manual at creation",
    "Automatic",
    "Manual triage"
])

routing_probabilities = np.array([
    0.30,
    0.45,
    0.25
])


tickets["routing_mode"] = rng.choice(
    routing_modes,
    size=N_TICKETS,
    p=routing_probabilities
)


# ============================================================
# 15. PRESERVE RESPONSIBLE CONTRACTOR
# ============================================================

# This contractor comes from:
# Asset -> Contract -> Contractor

tickets = tickets.rename(
    columns={
        "contractor_id":
            "responsible_contractor_id"
    }
)


# ============================================================
# 16. CREATE INITIAL ASSIGNMENT TIMESTAMP
# ============================================================

tickets["initial_assigned_at"] = pd.NaT


# ------------------------------------------------------------
# A. MANUAL ASSIGNMENT AT CREATION
#
# Assignee/contractor is selected when the ticket is submitted.
# created_at and assigned_at are therefore equal.
# ------------------------------------------------------------

manual_creation_mask = (
    tickets["routing_mode"]
    == "Manual at creation"
)

tickets.loc[
    manual_creation_mask,
    "initial_assigned_at"
] = tickets.loc[
    manual_creation_mask,
    "created_at"
]


# ------------------------------------------------------------
# B. AUTOMATIC ROUTING
#
# Automation runs shortly after ticket creation.
# ------------------------------------------------------------

automatic_mask = (
    tickets["routing_mode"]
    == "Automatic"
)

automatic_delay_seconds = rng.integers(
    low=5,
    high=61,
    size=automatic_mask.sum()
)

tickets.loc[
    automatic_mask,
    "initial_assigned_at"
] = (
    tickets.loc[
        automatic_mask,
        "created_at"
    ]
    +
    pd.to_timedelta(
        automatic_delay_seconds,
        unit="s"
    )
)


# ------------------------------------------------------------
# C. MANUAL TRIAGE
#
# Ticket is first created and reviewed in a queue.
# Assignment happens several minutes later.
# ------------------------------------------------------------

manual_triage_mask = (
    tickets["routing_mode"]
    == "Manual triage"
)

triage_delay_minutes = rng.integers(
    low=5,
    high=61,
    size=manual_triage_mask.sum()
)

tickets.loc[
    manual_triage_mask,
    "initial_assigned_at"
] = (
    tickets.loc[
        manual_triage_mask,
        "created_at"
    ]
    +
    pd.to_timedelta(
        triage_delay_minutes,
        unit="m"
    )
)


# ============================================================
# 17. DECIDE WHICH TICKETS ARE MISROUTED
# ============================================================

# Around 8% of tickets are initially sent to
# a contractor that is not responsible for the asset.

tickets["is_reassigned"] = (
    rng.random(N_TICKETS)
    < 0.08
)


contractor_ids = (
    assets["contractor_id"]
    .drop_duplicates()
    .to_numpy()
)


def choose_wrong_contractor(
    correct_contractor_id
):

    possible_contractors = contractor_ids[
        contractor_ids
        != correct_contractor_id
    ]

    return rng.choice(
        possible_contractors
    )


# ============================================================
# 18. DETERMINE INITIAL CONTRACTOR
# ============================================================

tickets["initial_contractor_id"] = (
    tickets["responsible_contractor_id"]
)


misrouted_mask = (
    tickets["is_reassigned"]
)


tickets.loc[
    misrouted_mask,
    "initial_contractor_id"
] = (
    tickets.loc[
        misrouted_mask,
        "responsible_contractor_id"
    ]
    .apply(
        choose_wrong_contractor
    )
)


# ============================================================
# 19. GENERATE REJECTION TIME
# ============================================================

tickets["rejected_at"] = pd.NaT


rejection_delay_minutes = rng.integers(
    low=5,
    high=31,
    size=misrouted_mask.sum()
)


tickets.loc[
    misrouted_mask,
    "rejected_at"
] = (
    tickets.loc[
        misrouted_mask,
        "initial_assigned_at"
    ]
    +
    pd.to_timedelta(
        rejection_delay_minutes,
        unit="m"
    )
)


# ============================================================
# 20. GENERATE FINAL ASSIGNMENT
# ============================================================

# Normal tickets:
# final assignment = initial assignment

tickets["final_assigned_at"] = (
    tickets["initial_assigned_at"]
)


# Misrouted tickets:
# assign to correct contractor after rejection

reassignment_delay_minutes = rng.integers(
    low=1,
    high=11,
    size=misrouted_mask.sum()
)


tickets.loc[
    misrouted_mask,
    "final_assigned_at"
] = (
    tickets.loc[
        misrouted_mask,
        "rejected_at"
    ]
    +
    pd.to_timedelta(
        reassignment_delay_minutes,
        unit="m"
    )
)


# ============================================================
# 21. GENERATE ACCEPTANCE TIMESTAMP
# ============================================================

acceptance_delay_minutes = rng.integers(
    low=3,
    high=16,
    size=N_TICKETS
)


tickets["accepted_at"] = (
    tickets["final_assigned_at"]
    +
    pd.to_timedelta(
        acceptance_delay_minutes,
        unit="m"
    )
)


# ============================================================
# 22. GENERATE ACTUAL RESPONSE TIME
# ============================================================

# Most tickets respond within the SLA target.
response_within_sla = (
    rng.random(N_TICKETS)
    < 0.85
)


response_factor = np.where(

    response_within_sla,

    rng.uniform(
        0.20,
        0.95,
        N_TICKETS
    ),

    rng.uniform(
        1.05,
        1.80,
        N_TICKETS
    )
)


tickets["response_minutes"] = (
    tickets["response_target_minutes"]
    * response_factor
).round().astype(int)


tickets["first_response_at"] = (
    tickets["created_at"]
    +
    pd.to_timedelta(
        tickets["response_minutes"],
        unit="m"
    )
)


# First response must occur after contractor acceptance.
response_before_acceptance = (
    tickets["first_response_at"]
    <= tickets["accepted_at"]
)


tickets.loc[
    response_before_acceptance,
    "first_response_at"
] = (
    tickets.loc[
        response_before_acceptance,
        "accepted_at"
    ]
    + pd.Timedelta(minutes=1)
)


# ============================================================
# 23. GENERATE ACTUAL RESOLUTION TIME
# ============================================================

resolution_within_sla = (
    rng.random(N_TICKETS)
    < 0.82
)


resolution_factor = np.where(

    resolution_within_sla,

    rng.uniform(
        0.30,
        0.95,
        N_TICKETS
    ),

    rng.uniform(
        1.05,
        1.60,
        N_TICKETS
    )
)


tickets["resolution_minutes"] = (
    tickets["resolution_target_minutes"]
    * resolution_factor
).round().astype(int)


# ============================================================
# 24. ADD REASSIGNMENT PENALTY
# ============================================================

# Misrouting consumes operational time.

reassignment_penalty = np.zeros(
    N_TICKETS,
    dtype=int
)


reassignment_penalty[
    misrouted_mask
] = rng.integers(
    low=20,
    high=121,
    size=misrouted_mask.sum()
)


tickets["resolution_minutes"] = (
    tickets["resolution_minutes"]
    + reassignment_penalty
)


# ============================================================
# 25. GENERATE RESOLUTION TIMESTAMP
# ============================================================

tickets["resolved_at"] = (
    tickets["created_at"]
    +
    pd.to_timedelta(
        tickets["resolution_minutes"],
        unit="m"
    )
)


# Ensure correct event order.
invalid_resolution_order = (
    tickets["resolved_at"]
    <= tickets["first_response_at"]
)


tickets.loc[
    invalid_resolution_order,
    "resolved_at"
] = (
    tickets.loc[
        invalid_resolution_order,
        "first_response_at"
    ]
    + pd.Timedelta(minutes=15)
)


# ============================================================
# 26. GENERATE CLOSURE TIMESTAMP
# ============================================================

closure_delay_minutes = rng.integers(
    low=5,
    high=241,
    size=N_TICKETS
)


tickets["closed_at"] = (
    tickets["resolved_at"]
    +
    pd.to_timedelta(
        closure_delay_minutes,
        unit="m"
    )
)


# ============================================================
# 27. SET CURRENT CONTRACTOR
# ============================================================

# After routing/reassignment is completed,
# the correct support contractor owns the ticket.

tickets["current_contractor_id"] = (
    tickets["responsible_contractor_id"]
)


# ============================================================
# 28. GENERATE INCIDENT CATEGORY
# ============================================================

def choose_incident_category(
    asset_type
):

    if asset_type == "Firewall":

        categories = [
            "Availability",
            "Configuration",
            "Security",
            "Performance",
            "Connectivity"
        ]

        probabilities = [
            0.25,
            0.30,
            0.20,
            0.10,
            0.15
        ]

    elif asset_type == "Security Gateway":

        categories = [
            "Availability",
            "Configuration",
            "Security",
            "Performance",
            "Connectivity"
        ]

        probabilities = [
            0.20,
            0.25,
            0.25,
            0.15,
            0.15
        ]

    elif asset_type == "IDS/IPS":

        categories = [
            "Availability",
            "Configuration",
            "Security",
            "Performance",
            "Connectivity"
        ]

        probabilities = [
            0.15,
            0.20,
            0.35,
            0.15,
            0.15
        ]

    elif asset_type == "Management Server":

        categories = [
            "Availability",
            "Configuration",
            "Application",
            "Performance",
            "Access"
        ]

        probabilities = [
            0.20,
            0.20,
            0.25,
            0.20,
            0.15
        ]

    elif asset_type == "Log Server":

        categories = [
            "Availability",
            "Configuration",
            "Application",
            "Performance",
            "Storage"
        ]

        probabilities = [
            0.15,
            0.15,
            0.20,
            0.25,
            0.25
        ]

    elif asset_type == "Application Server":

        categories = [
            "Availability",
            "Application",
            "Performance",
            "Configuration",
            "Access"
        ]

        probabilities = [
            0.20,
            0.30,
            0.25,
            0.15,
            0.10
        ]

    else:

        categories = [
            "Availability",
            "Configuration",
            "Performance",
            "Connectivity",
            "Other"
        ]

        probabilities = [
            0.25,
            0.20,
            0.20,
            0.20,
            0.15
        ]

    return rng.choice(
        categories,
        p=probabilities
    )


tickets["category"] = (
    tickets["asset_type"]
    .apply(
        choose_incident_category
    )
)


# ============================================================
# 29. GENERATE TITLE AND DESCRIPTION
# ============================================================

title_map = {

    "Availability":
        "Asset unavailable",

    "Configuration":
        "Configuration issue detected",

    "Security":
        "Security-related event detected",

    "Performance":
        "Degraded system performance",

    "Connectivity":
        "Connectivity issue detected",

    "Application":
        "Application issue detected",

    "Access":
        "Access issue reported",

    "Storage":
        "Storage-related issue detected",

    "Other":
        "Operational issue reported"
}


description_map = {

    "Availability":
        "The affected asset is currently unavailable.",

    "Configuration":
        "A configuration-related issue requires investigation.",

    "Security":
        "A security-related event requires investigation.",

    "Performance":
        "Performance degradation has been detected.",

    "Connectivity":
        "Connectivity to the affected asset is degraded or unavailable.",

    "Application":
        "An application-related issue requires investigation.",

    "Access":
        "An access-related issue has been reported.",

    "Storage":
        "A storage-related condition requires investigation.",

    "Other":
        "An operational issue requires investigation."
}


tickets["title"] = (
    tickets["category"]
    .map(title_map)
)


tickets["description"] = (
    tickets["category"]
    .map(description_map)
)


# ============================================================
# 30. SET FINAL STATUS
# ============================================================

closed_status_id = (
    statuses.loc[
        statuses["status_name"]
        == "Closed",
        "status_id"
    ]
    .iloc[0]
)


tickets["status_id"] = (
    closed_status_id
)


# ============================================================
# 31. BUILD INITIAL ASSIGNMENT RECORDS
# ============================================================

assignment_reason_map = {

    "Manual at creation":
        "Manual assignment during ticket creation",

    "Automatic":
        "Automatic routing rule",

    "Manual triage":
        "Manual assignment after triage"
}


initial_assignments = pd.DataFrame({

    "ticket_number":
        tickets["ticket_number"],

    "contractor_id":
        tickets[
            "initial_contractor_id"
        ],

    "assigned_at":
        tickets[
            "initial_assigned_at"
        ],

    "accepted_at":
        tickets[
            "accepted_at"
        ],

    "ended_at":
        pd.NaT,

    "assignment_status":
        np.where(
            tickets["is_reassigned"],
            "Rejected",
            "Accepted"
        ),

    "assignment_reason":
        tickets["routing_mode"]
        .map(
            assignment_reason_map
        ),

    "reassignment_reason":
        np.where(
            tickets["is_reassigned"],
            "Incorrect support scope",
            None
        )
})


# Misrouted initial assignments were rejected,
# therefore they were not accepted.
initial_assignments.loc[
    misrouted_mask,
    "accepted_at"
] = pd.NaT


initial_assignments.loc[
    misrouted_mask,
    "ended_at"
] = (
    tickets.loc[
        misrouted_mask,
        "rejected_at"
    ]
    .to_numpy()
)


# ============================================================
# 32. BUILD SECOND ASSIGNMENTS
# ============================================================

reassigned_tickets = (
    tickets[
        tickets["is_reassigned"]
    ]
    .copy()
)


second_assignments = pd.DataFrame({

    "ticket_number":
        reassigned_tickets[
            "ticket_number"
        ],

    "contractor_id":
        reassigned_tickets[
            "responsible_contractor_id"
        ],

    "assigned_at":
        reassigned_tickets[
            "final_assigned_at"
        ],

    "accepted_at":
        reassigned_tickets[
            "accepted_at"
        ],

    "ended_at":
        pd.NaT,

    "assignment_status":
        "Accepted",

    "assignment_reason":
        "Manual reassignment to responsible contractor",

    "reassignment_reason":
        None
})


# ============================================================
# 33. COMBINE ASSIGNMENT HISTORY
# ============================================================

assignments = pd.concat(
    [
        initial_assignments,
        second_assignments
    ],
    ignore_index=True
)


assignments = (
    assignments
    .sort_values(
        [
            "ticket_number",
            "assigned_at"
        ]
    )
    .reset_index(drop=True)
)


# ============================================================
# 34. CREATE TICKET EVENTS
# ============================================================

event_rows = []


for _, row in tickets.iterrows():

    # Ticket created
    event_rows.append({

        "ticket_number":
            row["ticket_number"],

        "event_type":
            "Ticket Created",

        "old_value":
            None,

        "new_value":
            "New",

        "event_at":
            row["created_at"],

        "performed_by":
            row["source"]
    })

    # Initial assignment
    event_rows.append({

        "ticket_number":
            row["ticket_number"],

        "event_type":
            "Assignment",

        "old_value":
            None,

        "new_value":
            str(
                row[
                    "initial_contractor_id"
                ]
            ),

        "event_at":
            row[
                "initial_assigned_at"
            ],

        "performed_by":
            row[
                "routing_mode"
            ]
    })

    # Reassignment path
    if row["is_reassigned"]:

        event_rows.append({

            "ticket_number":
                row["ticket_number"],

            "event_type":
                "Assignment Rejected",

            "old_value":
                str(
                    row[
                        "initial_contractor_id"
                    ]
                ),

            "new_value":
                None,

            "event_at":
                row["rejected_at"],

            "performed_by":
                "Contractor"
        })

        event_rows.append({

            "ticket_number":
                row["ticket_number"],

            "event_type":
                "Reassignment",

            "old_value":
                str(
                    row[
                        "initial_contractor_id"
                    ]
                ),

            "new_value":
                str(
                    row[
                        "responsible_contractor_id"
                    ]
                ),

            "event_at":
                row[
                    "final_assigned_at"
                ],

            "performed_by":
                "Operations"
        })

    # First response
    event_rows.append({

        "ticket_number":
            row["ticket_number"],

        "event_type":
            "First Response",

        "old_value":
            None,

        "new_value":
            "Responded",

        "event_at":
            row["first_response_at"],

        "performed_by":
            "Contractor"
    })

    # Resolved
    event_rows.append({

        "ticket_number":
            row["ticket_number"],

        "event_type":
            "Status Change",

        "old_value":
            "In Progress",

        "new_value":
            "Resolved",

        "event_at":
            row["resolved_at"],

        "performed_by":
            "Contractor"
    })

    # Closed
    event_rows.append({

        "ticket_number":
            row["ticket_number"],

        "event_type":
            "Status Change",

        "old_value":
            "Resolved",

        "new_value":
            "Closed",

        "event_at":
            row["closed_at"],

        "performed_by":
            "Operations"
    })


ticket_events = pd.DataFrame(
    event_rows
)


# ============================================================
# 35. PREPARE FINAL TICKET DATAFRAME
# ============================================================

tickets_final = tickets[
    [
        "ticket_number",
        "title",
        "description",
        "category",
        "source",
        "status_id",
        "priority_id",
        "site_id",
        "asset_id",
        "contract_id",
        "current_contractor_id",
        "created_at",
        "first_response_at",
        "resolved_at",
        "closed_at"
    ]
].copy()


# ============================================================
# 36. PREPARE FINAL ASSIGNMENT DATAFRAME
# ============================================================

assignments_final = assignments[
    [
        "ticket_number",
        "contractor_id",
        "assigned_at",
        "accepted_at",
        "ended_at",
        "assignment_status",
        "assignment_reason",
        "reassignment_reason"
    ]
].copy()


# ============================================================
# 37. PREPARE FINAL EVENT DATAFRAME
# ============================================================

events_final = ticket_events[
    [
        "ticket_number",
        "event_type",
        "old_value",
        "new_value",
        "event_at",
        "performed_by"
    ]
].copy()


# ============================================================
# 38. DATA QUALITY CHECKS
# ============================================================

print("\n--- DATA QUALITY CHECKS ---")


print(
    "Duplicate ticket numbers:",
    tickets_final[
        "ticket_number"
    ]
    .duplicated()
    .sum()
)


required_ticket_columns = [
    "ticket_number",
    "title",
    "status_id",
    "priority_id",
    "asset_id",
    "contract_id",
    "current_contractor_id",
    "created_at"
]


print(
    "\nMissing required values:"
)

print(
    tickets_final[
        required_ticket_columns
    ]
    .isna()
    .sum()
)


print(
    "\nResponse before creation:",
    (
        tickets[
            "first_response_at"
        ]
        < tickets["created_at"]
    ).sum()
)


print(
    "Assignment before creation:",
    (
        tickets[
            "initial_assigned_at"
        ]
        < tickets["created_at"]
    ).sum()
)


print(
    "Resolution before response:",
    (
        tickets["resolved_at"]
        <= tickets[
            "first_response_at"
        ]
    ).sum()
)


print(
    "Closure before resolution:",
    (
        tickets["closed_at"]
        <= tickets["resolved_at"]
    ).sum()
)


print(
    "Assignments without contractor:",
    assignments_final[
        "contractor_id"
    ]
    .isna()
    .sum()
)


print(
    "Events without timestamp:",
    events_final[
        "event_at"
    ]
    .isna()
    .sum()
)


# ============================================================
# 39. ROUTING VALIDATION
# ============================================================

print("\n--- ROUTING MODE DISTRIBUTION ---")

print(
    tickets[
        "routing_mode"
    ]
    .value_counts(
        normalize=True
    )
    .mul(100)
    .round(2)
)


# Calculate initial assignment delay in minutes
tickets[
    "assignment_delay_minutes"
] = (
    (
        tickets[
            "initial_assigned_at"
        ]
        -
        tickets["created_at"]
    )
    .dt.total_seconds()
    / 60
)


print(
    "\n--- AVG ASSIGNMENT DELAY BY ROUTING MODE ---"
)

print(
    tickets.groupby(
        "routing_mode"
    )[
        "assignment_delay_minutes"
    ]
    .mean()
    .round(2)
)


print(
    "\nReassignment rate %:",
    round(
        tickets[
            "is_reassigned"
        ]
        .mean()
        * 100,
        2
    )
)


# ============================================================
# 40. MONTHLY VALIDATION
# ============================================================

monthly_counts = (
    tickets
    .set_index("created_at")
    .resample("MS")
    .size()
)


print("\n--- MONTHLY TICKET COUNTS ---")
print(monthly_counts)


# ============================================================
# 41. CLEAR EXISTING TRANSACTIONAL DATA
# ============================================================

with engine.begin() as connection:

    connection.execute(
        text(
            """
            TRUNCATE TABLE
                ticket_events,
                ticket_comments,
                ticket_assignments,
                tickets
            RESTART IDENTITY;
            """
        )
    )


print(
    "\nExisting transactional data cleared."
)


# ============================================================
# 42. INSERT TICKETS
# ============================================================

tickets_final.to_sql(
    name="tickets",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=1000
)


print(
    f"{len(tickets_final)} tickets inserted."
)


# ============================================================
# 43. GET DATABASE TICKET IDS
# ============================================================

ticket_id_map = pd.read_sql(
    """
    SELECT
        ticket_id,
        ticket_number
    FROM tickets;
    """,
    engine
)


print(
    f"{len(ticket_id_map)} ticket IDs retrieved."
)


# ============================================================
# 44. MAP TICKET_ID TO ASSIGNMENTS
# ============================================================

assignments_db = (
    assignments_final
    .merge(
        ticket_id_map,
        on="ticket_number",
        how="left",
        validate="many_to_one"
    )
)


print(
    "Assignments without PostgreSQL ticket_id:",
    assignments_db[
        "ticket_id"
    ]
    .isna()
    .sum()
)


assignments_db = assignments_db[
    [
        "ticket_id",
        "contractor_id",
        "assigned_at",
        "accepted_at",
        "ended_at",
        "assignment_status",
        "assignment_reason",
        "reassignment_reason"
    ]
]


# ============================================================
# 45. INSERT ASSIGNMENTS
# ============================================================

assignments_db.to_sql(
    name="ticket_assignments",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=1000
)


print(
    f"{len(assignments_db)} assignment records inserted."
)


# ============================================================
# 46. MAP TICKET_ID TO EVENTS
# ============================================================

events_db = (
    events_final
    .merge(
        ticket_id_map,
        on="ticket_number",
        how="left",
        validate="many_to_one"
    )
)


print(
    "Events without PostgreSQL ticket_id:",
    events_db[
        "ticket_id"
    ]
    .isna()
    .sum()
)


events_db = events_db[
    [
        "ticket_id",
        "event_type",
        "old_value",
        "new_value",
        "event_at",
        "performed_by"
    ]
]


# ============================================================
# 47. INSERT EVENTS
# ============================================================

events_db.to_sql(
    name="ticket_events",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=1000
)


print(
    f"{len(events_db)} event records inserted."
)


# ============================================================
# 48. FINAL DATABASE VALIDATION
# ============================================================

database_counts = pd.read_sql(
    """
    SELECT
        'tickets' AS table_name,
        COUNT(*) AS row_count
    FROM tickets

    UNION ALL

    SELECT
        'ticket_assignments',
        COUNT(*)
    FROM ticket_assignments

    UNION ALL

    SELECT
        'ticket_events',
        COUNT(*)
    FROM ticket_events;
    """,
    engine
)


print("\n--- POSTGRESQL LOAD CHECK ---")
print(database_counts)


print(
    "\nSynthetic transactional data loaded successfully."
)
