# Operations Performance & Infrastructure Reliability Analytics

> 🚧 **Work in Progress**
>
> The core analytical stage is complete. SQL analyses **01–07** and the Python statistical analysis are available in this repository.
>
> The remaining stages are the creation of reporting views and the development of the Power BI data model and dashboard.

---

## Project Overview

This project recreates an operational analytics workflow based on my previous professional experience working with large-scale technical infrastructure and external service contractors.

External contractors were responsible for operational support, incident resolution, and planned maintenance activities across different parts of the infrastructure.

A key objective of the operational reporting process was to provide a transparent and data-based evaluation of contractor performance.

Incident, SLA, and planned-task data were analyzed to determine whether contractors fulfilled their operational and contractual obligations.

The resulting performance information was used as a basis for:

- monthly contractor performance evaluation,
- verification and approval of contractor invoices,
- identification of SLA violations and delayed contractual tasks,
- assessment of contractual deviations,
- corrective-action discussions with contractors,
- management-level contractor reviews,
- and longer-term contract evaluation.

The project is organized into two main analytical areas:

1. **Contractor Performance, Contract Compliance & Invoice Verification**
2. **Infrastructure Reliability & Root Cause Analysis**

The portfolio implementation uses a fully synthetic dataset designed to reproduce realistic analytical structures and business scenarios.

It contains no confidential company, customer, contractor, infrastructure, or production data.

---

# 1. Contractor Performance, Contract Compliance & Invoice Verification

The first analytical area focuses on evaluating the operational and contractual performance of external service contractors.

The analysis combines incident workload, SLA performance, resolution times, planned-task completion, statistical analysis, and monthly contract-compliance metrics.

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

SLA targets vary depending on operational conditions such as incident priority and location group.

Therefore, contractor performance is evaluated within the relevant SLA context rather than relying only on raw resolution times.

### Business Impact

The SLA analysis supports:

- monthly contractor performance reviews,
- identification of recurring SLA violations,
- investigation of contractual deviations,
- corrective-action discussions,
- and evidence-based contract management.

---

## Contractor Performance Analysis

Contractor performance is analyzed from several perspectives to avoid relying on a single KPI.

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

Average and median resolution times are analyzed together because unusually long incidents can influence the average.

Priority and location distributions are also reviewed to provide operational context before directly comparing contractor performance.

The analysis follows the logic:

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

Python is used to extend the SQL contractor-performance analysis with statistical testing.

The objective is to determine whether observed differences in contractor resolution times are statistically significant.

The workflow includes:

1. descriptive statistics by contractor,
2. boxplot analysis of resolution-time distributions,
3. Kruskal–Wallis test across all five contractors,
4. Dunn's post-hoc pairwise analysis,
5. Holm correction for multiple comparisons.

The Kruskal–Wallis test identified a statistically significant difference in resolution-time distributions across contractors:

**H = 63.23, p < 0.001**

Dunn's post-hoc analysis with Holm correction was then used to identify which contractor pairs showed statistically significant differences.

The descriptive analysis provided additional context:

- Contractor B had the lowest median resolution time: **388 minutes**
- Contractor C had the highest median resolution time: **763 minutes**
- Contractors A, D, and E showed intermediate median resolution times

The statistical results support the existence of differences in resolution-time distributions, but they do not establish causation.

Operational factors such as incident priority, location, and complexity should also be considered when evaluating contractor performance.

---

## Planned Task Performance

Contractors are also evaluated based on the completion of planned operational and maintenance tasks.

Unlike incidents, these activities have predefined due dates and represent regular contractual obligations.

Key metrics include:

- Total Planned Tasks
- On-Time Task Rate
- Overdue Task Rate
- Number of overdue tasks
- Task completion delay
- Monthly task-performance trends

The completion timestamp is compared with the contractual due date to determine whether each task was completed on time or overdue.

Monthly analysis is then used to identify changes in contractor performance over time.

### Business Impact

Task-performance analysis supports:

- monitoring of contractual maintenance obligations,
- identification of delayed activities,
- follow-up on contractor commitments,
- prioritization of overdue work,
- and monthly contractor performance evaluation.

---

## Monthly Contract Compliance & Invoice Verification

A dedicated monthly analysis combines incident SLA performance and planned-task performance.

The purpose is to provide the operational data required to verify contractor performance during a billing period.

### Incident Contract Performance

For incidents, the analysis includes:

- total incidents,
- SLA breaches,
- SLA Compliance Rate,
- SLA performance by contractor, priority, location group, and SLA target,
- total SLA excess minutes / hours,
- and detailed records of individual SLA deviations.

For every SLA breach, the actual SLA duration is compared with the contractual SLA target.

This makes it possible to identify both the number of SLA violations and the total amount of time by which contractual SLA targets were exceeded.

### Planned Task Contract Performance

For planned tasks, the analysis includes:

- total planned tasks,
- on-time tasks,
- overdue tasks,
- On-Time Rate,
- total task-delay hours,
- and detailed records of overdue tasks.

### Monthly Contractor Summary

Incident and task results are combined into a contractor-level monthly summary:

```text
Incident SLA Performance
          +
Planned Task Performance
          ↓
Monthly Contract Compliance
          ↓
Invoice Verification
```

Detailed deviation records make the results traceable to individual SLA breaches and overdue tasks.

---

## Invoice Verification & Financial Control

Monthly performance results provide a data basis for contractor invoice verification.

```text
Operational Data
        ↓
SLA & Task Performance
        ↓
Contractual Deviations
        ↓
Monthly Contractor Summary
        ↓
Invoice Verification
        ↓
Finance Review
```

Where the applicable contract defines deductions or penalties for SLA violations or delayed contractual obligations, the identified deviations provide the operational evidence required for their assessment.

The portfolio project itself does **not** calculate financial penalty amounts because penalty formulas are contract-specific and are not included in the synthetic dataset.

---

# 2. Infrastructure Reliability & Root Cause Analysis

The second analytical area moves from contractor performance to the technical reliability of the infrastructure.

The main questions are:

> **Where are incidents occurring?**

and:

> **Which recorded causes contribute to these incidents?**

---

## Reliability Analysis

The reliability analysis starts with the monthly incident trend and then drills down to identify where incidents are concentrated.

The analysis includes:

- monthly incident volume,
- incident trends by location group,
- incident trends by site,
- incident trends by device type,
- incident counts by device model,
- normalized incidents per device model,
- incident counts for individual devices,
- and monthly trends for high-incident devices.

The analytical logic is:

```text
Are incidents increasing?
        ↓
Where is the increase occurring?
        ↓
Which sites are most affected?
        ↓
Which device types and models are involved?
        ↓
Which individual devices have many incidents?
        ↓
Do these devices show recurring patterns over time?
```

Normalization by the number of devices is used when comparing device models because raw incident counts alone can be misleading when the installed device populations are different.

### Business Impact

The analysis helps technical teams identify infrastructure areas and individual assets that require further investigation.

The results can support maintenance prioritization, recurring-problem investigation, and reliability improvement.

---

## Root Cause Analysis

The root-cause analysis continues the reliability investigation by moving from **where problems occur** to **which recorded causes contribute to the incidents**.

The analysis includes:

- incident distribution by category,
- root-cause distribution within each category,
- overall contribution of each root cause,
- Pareto analysis using cumulative incident percentages,
- root-cause distribution by site,
- recurring device and root-cause combinations,
- and monthly root-cause trends.

The analytical logic is:

```text
Incident Category
        ↓
Root Cause within Category
        ↓
Overall Root-Cause Contribution
        ↓
Pareto Analysis
        ↓
Root Cause by Site / Device / Time
```

The Pareto analysis is used to identify which root causes account for the largest cumulative share of incidents.

Site, device, and monthly analyses then provide different perspectives on where and how root-cause patterns occur.

### Business Impact

The analysis helps operational teams prioritize the causes that contribute most to incident volume and identify recurring patterns that require further technical investigation.

The SQL analysis identifies patterns in the available incident data; it does not by itself establish technical causation beyond the recorded root-cause information.

---

# Analytical Workflow

The portfolio follows an analytical workflow similar to an operational reporting environment:

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
- and root-cause analysis.

Python is used to extend the SQL analysis with statistical methods where appropriate.

Power BI will be used to build the final reporting model, DAX measures, interactive visualizations, and management dashboard.

---

# Current Project Status

## Completed

- Synthetic analytical database design
- **01** Data exploration and validation
- **02** SLA analysis
- **03** Contractor performance analysis
- Python statistical analysis of contractor resolution times
  - descriptive statistics
  - boxplot analysis
  - Kruskal–Wallis test
  - Dunn's post-hoc analysis with Holm correction
- **04** Planned task performance analysis
- **05** Monthly contract compliance and invoice-verification analysis
  - SLA breaches by contractor, priority, location group, and SLA target
  - total SLA excess time
  - overdue planned tasks and total task-delay hours
  - detailed deviation records
  - monthly contractor summary
- **06** Infrastructure reliability analysis
  - monthly incident trends
  - location and site analysis
  - device type and model analysis
  - normalized incidents per device
  - high-incident device trends
- **07** Root-cause analysis
  - category and root-cause distributions
  - Pareto analysis
  - root cause by site
  - recurring device/root-cause combinations
  - monthly root-cause trends

## Next Steps

- **08** Create reporting views for Power BI
- Build the Power BI semantic model and DAX measures
- Develop the operational performance dashboard
- Summarize final business insights

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
│   └── 07_root_cause_analysis.sql
│
└── python/
    └── 01_contractor_statistical_analysis.ipynb
```

Planned additions:

```text
sql/08_create_reporting_views.sql
powerbi/operations_performance_dashboard.pbix
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
- Infrastructure Reliability Analysis
- Root Cause Analysis

---

# Project Goal

The goal of this project is to demonstrate how operational data can be transformed into actionable information for contractor performance management, contract compliance, financial control, infrastructure reliability, and management decision-making.

The project demonstrates an analytical chain from operational data to business insight:

```text
Operational Data
        ↓
Data Validation
        ↓
Operational KPI Analysis
        ↓
Contractor Performance
        ↓
Contract Compliance
        ↓
Invoice Verification
        ↓
Infrastructure Reliability
        ↓
Root Cause Analysis
        ↓
Reporting & Decision Support
```

Monthly SLA and planned-task performance provide a data basis for contractor evaluation and invoice verification.

Longer-term performance trends can support contractor-management reviews.

The reliability and root-cause analyses extend the project from contractor performance to technical infrastructure analysis by identifying incident trends, affected assets, recurring patterns, and important recorded causes.

The project combines SQL-based operational analytics with Python-based statistical analysis.

The core analytical stage — **SQL analyses 01–07 plus the Python statistical analysis — is complete**.

The next stage will transform the validated analytical results into reporting views and a Power BI reporting solution.
