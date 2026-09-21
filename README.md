# Operations Performance & Service Reliability Analytics

> 🚧 **Work in Progress**
>
> This project is currently under active development. The SQL analysis is being built incrementally, followed by the development of a Power BI reporting layer and interactive dashboard. Additional reliability, recurring-incident, and root-cause analyses will be added as the project progresses.

## Project Overview

This project recreates an operational analytics workflow based on my previous professional experience working with large-scale technical infrastructure and external service contractors.

The objective is to transform operational issue, task, SLA, asset, and service data into actionable insights for two main business areas:

1. **Contractor Performance & Operational Control**
2. **Technical Reliability & Service Quality**

The project focuses not only on calculating KPIs, but also on connecting analytical results to operational and business decisions.

The portfolio implementation uses a fully synthetic dataset designed to reproduce realistic analytical structures and business scenarios. It contains no confidential company, customer, contractor, infrastructure, or production data.

---

## 1. Contractor Performance & Operational Control

External contractors are responsible for operational support, incident resolution, and planned maintenance activities.

The analysis evaluates contractor performance using several operational KPIs.

### SLA Performance

Key metrics include:

* SLA Compliance Rate
* SLA Breach Rate
* Number of SLA breaches
* Resolution Time
* Performance by incident priority
* Performance by location group
* Monthly SLA trends

SLA targets vary depending on operational conditions such as incident priority and location. Therefore, contractor performance is analyzed within the relevant SLA context rather than relying only on raw resolution times.

**Business Impact**

The analysis can support:

* monthly contractor performance reviews,
* invoice verification,
* identification of recurring SLA violations,
* contractual penalty assessment where applicable,
* corrective-action discussions,
* and evidence-based contract management decisions.

---

### Planned Task Performance

Contractors are also evaluated based on the completion of planned operational and maintenance tasks.

Key metrics include:

* On-Time Task Rate
* Overdue Task Rate
* Task completion delay
* Monthly task performance
* Contractor-level task trends

**Business Impact**

Task performance analysis helps identify delayed maintenance activities, follow up on contractor commitments, prioritize overdue work, and improve preventive maintenance planning.

---

## 2. Technical Reliability & Service Quality

The second analytical area focuses on the technical performance and stability of the infrastructure.

The objective is to identify where incidents occur, whether reliability is deteriorating, and which technical components require further investigation.

### Incident Trend Analysis

Analysis includes:

* incident volume by month,
* incident trends over time,
* incident distribution by site and location,
* and normalized incident rates where appropriate.

**Business Impact**

Trend analysis can reveal increasing operational problems early and help teams prioritize investigation and maintenance resources.

---

### Equipment Reliability Analysis

Incidents are analyzed across technical asset characteristics such as:

* device type,
* device model,
* vendor or equipment family where available,
* site,
* and individual devices.

The analysis also investigates recurring incidents and equipment with unusually high incident frequency.

**Business Impact**

These insights can support decisions related to:

* preventive maintenance,
* replacement of unreliable equipment,
* spare-parts planning,
* inventory prioritization,
* technical standardization,
* and resource allocation.

---

### Root Cause Analysis

Incident root causes are analyzed across dimensions such as:

* incident category,
* device type and model,
* site and location,
* contractor,
* and time period.

Recurring combinations of incidents and root causes are investigated to distinguish isolated events from systematic technical problems.

**Business Impact**

Root-cause analysis helps move operational teams from repeated incident resolution toward permanent corrective actions, such as hardware replacement, configuration changes, software remediation, power-infrastructure improvements, or maintenance-process changes.

---

### Service Quality & Reliability

The project will progressively include additional reliability and service-quality metrics, including:

* recurring incident analysis,
* incident frequency by asset,
* normalized incident rates,
* Mean Time Between Incidents (MTBI),
* equipment reliability trends,
* service availability analysis where appropriate monitoring data is available.

These metrics provide additional context for identifying weak points and supporting reliability improvement initiatives.

---

## Analytical Workflow

The portfolio follows an analytical workflow similar to a real operational reporting environment:

```text
Operational Data
       ↓
Analytical PostgreSQL Database
       ↓
SQL Data Exploration & Validation
       ↓
SLA / Contractor / Task / Reliability Analysis
       ↓
Reporting Views
       ↓
Power BI Data Model
       ↓
Operational Performance Dashboard
       ↓
Business & Operational Decisions
```

SQL is used for data exploration, validation, KPI development, and analytical preparation. Power BI will be used to build the reporting model, measures, interactive visualizations, and management dashboard.

---

## Current Project Status

### Completed

* Synthetic analytical database design
* Data exploration and validation
* SLA analysis
* SLA compliance and breach calculations
* SLA analysis by priority and location
* Contractor SLA comparison
* Monthly SLA trend analysis

### In Progress

* Contractor performance analysis
* Resolution-time analysis
* Monthly contractor performance
* Planned task performance analysis

### Planned

* Equipment reliability analysis
* Incident trend and normalized incident-rate analysis
* Recurring incident analysis
* MTBI analysis
* Root cause analysis
* Reporting views for Power BI
* Power BI data model
* Operational performance dashboard
* Final business insights and recommendations

---

## Repository Structure

```text
operations-performance-analytics/
│
├── README.md
│
├── database/
│   └── synthetic_database_setup.sql
│
├── sql/
│   ├── 01_data_exploration.sql
│   ├── 02_sla_analysis.sql
│   ├── 03_contractor_performance.sql
│   ├── 04_task_performance.sql
│   ├── 05_reliability_analysis.sql
│   └── 06_root_cause_analysis.sql
│
└── powerbi/
    └── operations_performance_dashboard.pbix
```

---

## Tools & Technologies

* PostgreSQL
* SQL
* pgAdmin
* Power BI
* Data Modeling
* Operational KPI Analysis
* SLA & Performance Analytics

---

## Project Goal

The goal of this project is to demonstrate how operational data can be transformed into actionable information for contractor management, service-quality monitoring, infrastructure reliability, maintenance planning, and operational decision-making.

The project is being developed incrementally, with each analytical layer validated before being incorporated into the final Power BI reporting solution.
