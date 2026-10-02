# Operations Performance & Infrastructure Reliability Analytics

## Project Overview

This portfolio project is based on my previous professional experience in **operational analytics for large-scale technical infrastructure and external service contractors**.

The project recreates a realistic analytical workflow for monitoring contractor performance, SLA compliance, planned maintenance activities, invoice verification, infrastructure reliability, and recurring technical issues.

> **Confidentiality:** To protect confidential information, all company, contractor, infrastructure, and operational data used in this repository is fully synthetic. The analytical workflow and business scenarios are based on real professional experience, while no confidential production data is included.

---

## Business Context

External service contractors are responsible for operational support, incident resolution, and planned maintenance activities.

Their performance is evaluated against contractual requirements before monthly invoices can be verified and approved.

The analysis focuses on two main areas:

- **Contractor Performance & Contract Compliance**
- **Infrastructure Reliability & Root Cause Analysis**

---

## Analytical Workflow

```text
Operational Data
      ↓
PostgreSQL Analytical Database
      ↓
Data Validation & SQL Analysis
      ↓
SLA / Contractor / Task Performance
      ↓
Contract Compliance & Invoice Verification
      ↓
Infrastructure Reliability & Root Cause Analysis
      ↓
Python Statistical Analysis
      ↓
Reporting Views
      ↓
Power BI Data Model & DAX
      ↓
Management Dashboards
```

---

## Key Analyses

### Contractor & Contract Performance

The analysis covers:

- SLA compliance and SLA breaches
- Contractor resolution times
- Performance by priority and location group
- Planned-task completion and delays
- Monthly contractor performance
- SLA excess hours
- Contract compliance and invoice-verification metrics

Python statistical analysis extends the SQL analysis using:

- Descriptive statistics
- Kruskal–Wallis test
- Dunn's post-hoc analysis
- Holm correction

### Infrastructure Reliability & Root Cause Analysis

The technical analysis investigates:

- Monthly incident trends
- Incidents by site
- Incidents by device type and model
- Normalized incidents per device
- Incident categories and root causes
- Recurring technical patterns
- Pareto analysis of root causes

This provides both a **WHERE** perspective — where incidents occur — and a **WHY** perspective based on recorded root-cause information.

---

## Key Findings

The following findings are based on the **synthetic dataset** created for this portfolio project:

- Overall **SLA compliance was 71.84%**, with **145 SLA breaches** across 515 incidents.
- Incident volume increased from **72 incidents in January to 102 in June**, showing an upward trend during the six-month analysis period.
- Overall contractor SLA compliance ranged from **36.19% to 100%**. Since SLA targets depend on factors such as priority and location group, these overall rates should not be interpreted as a standalone contractor ranking.
- Planned-task performance reached an overall **81.05% on-time rate**, with **108 overdue tasks**.
- Statistical analysis identified a **significant overall difference in incident resolution times between contractors** (Kruskal–Wallis, **p < 0.001**). Contractor B had the lowest median resolution time (**388 minutes**), while Contractor C had the highest (**763 minutes**). Dunn's post-hoc analysis showed significant differences between several contractor pairs, while differences among Contractors A, D, and E were not statistically significant.
- **Network** was the largest incident category with **284 incidents**. The most frequent recorded root causes included **Link Failure, Routing Issue, Interface Failure, and Packet Loss**.

---

## Power BI Dashboard

The final Power BI solution contains three reporting pages.

### 1. Operations Performance Overview

[Operations Performance Overview](https://github.com/Somi-Mahdavi/operations-performance-analytics/blob/main/images/01_executive_overview.png) ([image](https://github.com/Somi-Mahdavi/operations-performance-analytics/raw/main/images/01_executive_overview.png))

Management-level overview of incident volume, SLA compliance, SLA breaches, planned-task performance, and monthly operational trends.

### 2. Contractor & Contract Performance

[Contractor & Contract Performance](https://github.com/Somi-Mahdavi/operations-performance-analytics/blob/main/images/02_contractor_contract_performance.png) ([image](https://github.com/Somi-Mahdavi/operations-performance-analytics/raw/main/images/02_contractor_contract_performance.png))

Detailed contractor performance analysis including SLA compliance by priority and location group, SLA excess hours, task delays, and monthly performance trends.

### 3. Reliability & Root Cause Analysis

[Reliability & Root Cause Analysis](https://github.com/Somi-Mahdavi/operations-performance-analytics/blob/main/images/03_reliability_root_cause.png) ([image](https://github.com/Somi-Mahdavi/operations-performance-analytics/raw/main/images/03_reliability_root_cause.png))

Infrastructure reliability analysis showing incident concentration across sites and devices, normalized incidents per device, recorded root causes, and Pareto analysis.

---

## Repository Structure

```text
operations-performance-analytics/
│
├── data/
│   └── contractor_resolution_times.csv
│
├── database/
│   └── synthetic_database_setup.sql
│
├── sql/
│   ├── 01_data_exploration.sql
│   ├── 02_sla_analysis.sql
│   ├── 03_contractor_performance.sql
│   ├── 04_task_performance.sql
│   ├── 05_monthly_contract_compliance.sql
│   ├── 06_reliability_analysis.sql
│   ├── 07_root_cause_analysis.sql
│   └── 08_create_reporting_views.sql
│
├── python/
│   └── 01_contractor_statistical_analysis.ipynb
│
├── powerbi/
│   └── operations_performance_analytics.pbix
│
├── images/
│   ├── 01_executive_overview.png
│   ├── 02_contractor_contract_performance.png
│   └── 03_reliability_root_cause.png
│
└── README.md
```

---

## Tools & Technologies

**PostgreSQL · SQL · pgAdmin · Python · pandas · SciPy · Matplotlib · Power BI · DAX · Data Modeling · Statistical Analysis**

---

## Project Outcome

This project demonstrates an end-to-end operational analytics workflow:

**Data Validation → KPI Analysis → Contractor Performance → Contract Compliance → Invoice Verification → Infrastructure Reliability → Root Cause Analysis → Management Reporting**

It demonstrates how SQL, Python, statistical analysis, and Power BI can be combined to transform operational data into structured information for technical and management decision support.
