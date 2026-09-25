# Operations Performance & Infrastructure Reliability Analytics

> 🚧 **Work in Progress**
>
> This project is currently under active development. Data exploration, SLA analysis,
> contractor performance analysis, statistical comparison of contractor resolution
> times, planned-task performance, and monthly contract compliance analysis have been
> completed.
>
> The remaining stages include infrastructure reliability analysis, root-cause
> analysis, reporting views, and the development of a Power BI dashboard.

---

## Project Overview

This project recreates an operational analytics workflow based on my previous
professional experience working with large-scale technical infrastructure and
external service contractors.

External contractors were responsible for operational support, incident resolution,
and planned maintenance activities across different parts of the infrastructure.

A key objective of the operational reporting process was to provide a transparent
and data-based evaluation of contractor performance.

Incident, SLA, and planned-task data were analyzed to determine whether contractors
fulfilled their operational and contractual obligations.

The resulting performance information was used as a basis for:

- monthly contractor performance evaluation,
- verification and approval of contractor invoices by the Finance department,
- identification of SLA violations and delayed contractual tasks,
- assessment of contractual deviations,
- corrective-action discussions with contractors,
- management-level contractor reviews,
- and decisions regarding the continuation or renewal of contractor agreements.

The project therefore connects technical and operational data directly with
financial control and management decision-making.

The analytical work is organized into two main areas:

1. **Contractor Performance, Contract Compliance & Invoice Verification**
2. **Infrastructure Reliability & Operational Improvement**

The portfolio implementation uses a fully synthetic dataset designed to reproduce
realistic analytical structures and business scenarios.

It contains no confidential company, customer, contractor, infrastructure, or
production data.

---

# 1. Contractor Performance, Contract Compliance & Invoice Verification

The first analytical area focuses on evaluating the operational and contractual
performance of external service contractors.

The analysis combines incident workload, SLA performance, resolution times,
planned-task completion, statistical analysis, and monthly contract-compliance
metrics.

The objective is not only to calculate operational KPIs, but also to transform them
into information that can support contractor evaluation, invoice verification,
financial control, and management decisions.

---

## SLA Performance

Incident performance is evaluated against contractual SLA targets.

Key metrics include:

- SLA Compliance Rate
- SLA Breach Rate
- Number of SLA breaches
- Resolution Time
- Performance by incident priority
- Performance by location group
- Monthly SLA trends

SLA targets vary depending on operational conditions such as incident priority and
location.

Therefore, contractor performance is evaluated within the relevant SLA context
rather than relying only on raw resolution times.

### Business Impact

The SLA analysis supports:

- monthly contractor performance reviews,
- identification of recurring SLA violations,
- investigation of contractual deviations,
- corrective-action discussions,
- and evidence-based contract management.

---

## Contractor Performance Analysis

Contractor performance is analyzed from several perspectives to avoid relying on a
single KPI.

The analysis includes:

- incident workload by contractor,
- average resolution time,
- median resolution time,
- incident priority mix,
- location mix,
- SLA performance by contractor,
- monthly SLA trends,
- monthly resolution-time trends,
- and resolution-time comparison by incident priority.

Average and median resolution times are analyzed together because unusually long
incidents can influence the average.

Priority and location distributions are also reviewed to provide operational context
before directly comparing contractor performance.

The analysis therefore follows the logic:

```text
Incident Workload
        ↓
Resolution Time
        ↓
Average & Median
        ↓
Priority / Location Context
        ↓
SLA Performance
        ↓
Monthly Performance Trends
        ↓
Contractor Evaluation
```

---

## Statistical Analysis of Resolution Time

A statistical analysis was performed in Python to determine whether the observed
differences in contractor resolution times were supported by statistical evidence.

The workflow included:

1. descriptive statistics by contractor,
2. boxplot analysis of resolution-time distributions,
3. Kruskal–Wallis test across all five contractors,
4. Dunn's post-hoc pairwise analysis,
5. Holm correction for multiple comparisons.

The Kruskal–Wallis test identified a statistically significant difference in
resolution-time distributions across contractors:

**H = 63.23, p < 0.001**

Dunn's post-hoc analysis with Holm correction was then used to identify which
contractor pairs differed.

The analysis showed that Contractor B and Contractor C had statistically significant
differences from several other contractors, while no statistically significant
differences were found among Contractors A, D, and E.

The descriptive analysis provided additional context:

- Contractor B had the lowest median resolution time: **388 minutes**
- Contractor C had the highest median resolution time: **763 minutes**
- Contractors A, D, and E showed intermediate median resolution times

The combination of descriptive and inferential analysis therefore showed that the
observed resolution-time differences for Contractors B and C were supported by
statistical evidence.

These results do not establish causation.

Operational factors such as incident priority, location, and complexity should also
be considered when evaluating contractor performance.

### Business Impact

The statistical analysis provides additional evidence for contractor performance
reviews by distinguishing observed KPI differences from differences that are
supported by statistical analysis.

---

## Planned Task Performance

Contractors are also evaluated based on the completion of planned operational and
maintenance tasks.

Unlike incidents, these activities have predefined due dates and represent regular
contractual obligations.

Key metrics include:

- Total Planned Tasks
- On-Time Task Rate
- Overdue Task Rate
- Number of overdue tasks
- Task completion delay
- Average overdue delay
- Maximum overdue delay
- Monthly task-performance trends

The completion timestamp is compared with the contractual due date to determine
whether each task was completed on time or overdue.

Monthly analysis is then used to identify changes in contractor performance over
time.

### Business Impact

Task-performance analysis supports:

- monitoring of contractual maintenance obligations,
- identification of delayed activities,
- follow-up on contractor commitments,
- prioritization of overdue work,
- preventive maintenance planning,
- and monthly contractor performance evaluation.

---

## Monthly Contract Compliance & Invoice Verification

A dedicated monthly contract-compliance analysis combines incident SLA performance
and planned-task performance.

The purpose of this analysis is to determine whether each contractor fulfilled its
operational and contractual obligations during the relevant billing period.

### Incident Contract Performance

For incidents, the analysis calculates:

- total incidents,
- SLA-compliant incidents,
- SLA breaches,
- SLA Compliance Rate,
- total SLA excess hours,
- average SLA excess time,
- and detailed records of individual SLA deviations.

For every SLA breach, the actual SLA duration is compared with the contractual SLA
target.

This makes it possible to measure not only how many SLA breaches occurred, but also
the magnitude of the SLA deviation.

### Planned Task Contract Performance

For planned tasks, the analysis calculates:

- total required tasks,
- on-time tasks,
- overdue tasks,
- On-Time Rate,
- total task-delay hours,
- average task delay,
- maximum task delay,
- and detailed records of overdue tasks.

This provides both a monthly performance summary and the detailed records required
to investigate individual contractual deviations.

### Monthly Contractor Summary

Incident and planned-task results are combined into a contractor-level monthly
performance summary.

The resulting structure connects:

```text
Incident Performance
        +
Planned Task Performance
        ↓
Monthly Contract Compliance
        ↓
Contractor Performance Evaluation
```

The detailed deviation records also provide drill-down information for individual
SLA breaches and overdue contractual tasks.

---

## Invoice Verification & Financial Control

The monthly contractor performance reports provide a data basis for the financial
review of contractor invoices.

The process can be represented as:

```text
Operational Data
        ↓
SLA & Task Performance Analysis
        ↓
Monthly Contractor Performance
        ↓
Contract Compliance Evaluation
        ↓
Invoice Verification
        ↓
Finance Review & Invoice Approval
```

The Finance department can use the validated monthly performance results as a basis
for contractor invoice verification and approval.

Where the applicable contract defines deductions or penalties for SLA violations or
delayed contractual obligations, the identified deviations provide the operational
evidence required for their assessment.

The portfolio project itself does not calculate financial penalty amounts because
penalty formulas are contract-specific and are not included in the synthetic
dataset.

---

## Management & Contract Renewal Decisions

The contractor performance reports also provide information for longer-term
management evaluation.

While monthly reports support operational and financial control, performance trends
over longer periods can reveal:

- recurring SLA violations,
- repeated delays in contractual tasks,
- deterioration or improvement in contractor performance,
- recurring operational problems,
- and systematic contractual deviations.

This information can support senior management when reviewing contractor
performance and considering the continuation or renewal of contractor agreements.

The overall decision-support workflow can therefore be summarized as:

```text
Operational Data
        ↓
Performance KPIs
        ↓
Monthly Contractor Evaluation
        ↓
Contract Compliance
        ↓
┌──────────────────────────────┐
│                              │
↓                              ↓
Invoice Verification       Management Review
│                              │
↓                              ↓
Finance Approval          Performance Trends
                               │
                               ↓
                      Contract Continuation /
                         Renewal Decisions
```

This creates a direct connection between operational analytics, financial control,
contractor management, and strategic management decisions.

---

# 2. Infrastructure Reliability & Operational Improvement

The second analytical area focuses on the technical stability and reliability of the
infrastructure.

The objective is to move from the question:

> **How did the contractors perform?**

to:

> **Where are technical problems occurring and which infrastructure components
> require further investigation?**

This part of the project uses incident and asset data to identify technical patterns,
recurring problems, and potential reliability issues.

---

## Incident Trend Analysis

The analysis includes:

- incident volume by month,
- incident trends over time,
- changes in incident frequency,
- incident distribution by site,
- incident distribution by location,
- and normalized incident rates where appropriate.

### Business Impact

Incident trend analysis can reveal increasing operational problems early and help
technical teams prioritize investigation and maintenance resources.

---

## Equipment Reliability Analysis

Incidents are analyzed across available technical asset characteristics such as:

- device type,
- device model,
- site,
- location,
- and individual devices.

The analysis also investigates recurring incidents and equipment with unusually high
incident frequency.

### Business Impact

These insights can support decisions related to:

- preventive maintenance,
- replacement of unreliable equipment,
- spare-parts planning,
- inventory prioritization,
- technical standardization,
- and maintenance resource allocation.

---

## Recurring Incident Analysis

Repeated incidents affecting the same devices, sites, or equipment groups are
identified separately from isolated incidents.

The objective is to identify assets that repeatedly generate operational problems.

This helps distinguish between:

```text
Isolated Incident
        ↓
Corrective Resolution
```

and:

```text
Recurring Incident
        ↓
Systematic Problem
        ↓
Further Investigation
        ↓
Preventive / Permanent Action
```

---

## Root Cause Analysis

Incident root causes are analyzed across dimensions such as:

- incident category,
- root cause,
- device type,
- device model,
- site and location,
- contractor,
- and time period.

Recurring combinations of incidents and root causes are investigated to distinguish
isolated events from systematic technical problems.

### Business Impact

Root-cause analysis can help operational teams move from repeated incident resolution
toward permanent corrective actions.

Depending on the identified cause, possible actions may include:

- hardware replacement,
- configuration changes,
- software remediation,
- power-infrastructure improvements,
- preventive maintenance,
- or maintenance-process improvements.

The analytical objective is:

```text
Incident
   ↓
Pattern
   ↓
Root Cause
   ↓
Corrective / Preventive Action
   ↓
Improved Reliability
```

---

# Analytical Workflow

The portfolio follows an analytical workflow similar to a real operational reporting
environment:

```text
Operational Data
        ↓
Analytical PostgreSQL Database
        ↓
SQL Data Exploration & Validation
        ↓
SLA Analysis
        ↓
Contractor Performance Analysis
        ↓
Python Statistical Analysis
        ↓
Planned Task Performance
        ↓
Monthly Contract Compliance
        ↓
Invoice Verification Analysis
        ↓
Infrastructure Reliability Analysis
        ↓
Root Cause Analysis
        ↓
Reporting Views
        ↓
Power BI Data Model
        ↓
Operational Performance Dashboard
        ↓
Business & Management Decisions
```

SQL is used for:

- data exploration,
- data validation,
- KPI development,
- SLA analysis,
- contractor-performance analysis,
- planned-task analysis,
- monthly contract-compliance analysis,
- reliability analysis,
- and analytical preparation for reporting.

Python is used to extend the SQL analysis with statistical methods where appropriate.

In the contractor-performance analysis, Python was used for:

- descriptive statistics,
- visualization,
- the Kruskal–Wallis test,
- Dunn's post-hoc analysis,
- and Holm correction for multiple comparisons.

Power BI will be used to build the final reporting model, measures, interactive
visualizations, and management dashboard.

---

# Current Project Status

## Completed

- Synthetic analytical database design
- Data exploration and validation
- SLA analysis
- SLA compliance and breach calculations
- SLA analysis by priority and location
- Contractor performance analysis
- Average and median resolution-time analysis
- Contractor priority and location mix analysis
- Monthly contractor SLA analysis
- Monthly contractor resolution-time analysis
- Statistical contractor comparison in Python
- Kruskal–Wallis test
- Dunn's post-hoc analysis with Holm correction
- Planned task performance analysis
- On-Time and Overdue Task analysis
- Task-delay analysis
- Monthly task-performance trends
- Monthly contract-compliance analysis
- SLA excess analysis
- Contractual deviation detail analysis
- Overdue-task deviation detail analysis
- Monthly contractor summary for invoice verification

## In Progress

- Infrastructure reliability analysis

## Planned

- Incident trend analysis
- Equipment reliability analysis
- Recurring incident analysis
- Root cause analysis
- Reporting views for Power BI
- Power BI data model
- Operational performance dashboard
- Final business insights and recommendations

---

# Repository Structure

```text
operations-performance-analytics/
│
├── README.md
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
└── powerbi/
    └── operations_performance_dashboard.pbix
```

---

# Tools & Technologies

- PostgreSQL
- SQL
- pgAdmin
- Python
- pandas
- SciPy
- scikit-posthocs
- Matplotlib
- Power BI
- Data Modeling
- Statistical Analysis
- Operational KPI Analysis
- SLA Analytics
- Contractor Performance Analytics
- Contract Compliance Analytics

---

# Project Goal

The goal of this project is to demonstrate how operational data can be transformed
into actionable information for contractor performance management, contract
compliance, financial control, infrastructure reliability, and management
decision-making.

The project demonstrates a complete analytical chain:

```text
Operational Data
        ↓
Data Validation
        ↓
KPI Analysis
        ↓
Contractor Performance Evaluation
        ↓
Contract Compliance
        ↓
Invoice Verification
        ↓
Management Decision Support
```

Monthly SLA and planned-task performance provide a data basis for contractor
evaluation and invoice verification.

The validated performance results can support Finance in the monthly invoice-review
and approval process.

Longer-term performance trends can also support senior management when evaluating
contractor performance and considering contract continuation or renewal.

The second part of the project extends the analysis from contractor performance to
technical reliability by identifying recurring incidents, problematic assets, and
root-cause patterns.

The project combines SQL-based operational analytics with Python-based statistical
analysis and will ultimately integrate the validated analytical results into a
Power BI reporting solution.

The project is being developed incrementally, with each analytical layer validated
before being incorporated into the final reporting model.
