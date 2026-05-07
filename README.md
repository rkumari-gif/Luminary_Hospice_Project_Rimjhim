# Luminary_Hospice_Project_Rimjhim
# Luminary Hospice dbt Data Platform

## 📌 Overview
This project implements a modern data platform for **Luminary Hospice** using **Snowflake, dbt, and Sigma**.

The solution follows a **Medallion Architecture (Bronze → Silver → Gold)** to transform raw healthcare data into reliable, analytics-ready datasets powering operational dashboards.

---

## 🏗️ Architecture

GitHub (dbt Models & CI/CD)
        ↓
dbt (Transformations & Tests)
        ↓
Snowflake (Data Warehouse)
        ↓
Sigma (Business Dashboards)

---

## 📂 Project Structure

models/
  ├── staging/        # Raw data cleaning (Bronze)
  ├── intermediate/   # Business transformations (Silver)
  ├── marts/          # Analytics layer (Gold)
      ├── facts/
      ├── dimensions/

macros/               # Reusable SQL logic
tests/                # Custom validation tests
.github/workflows/    # CI/CD pipeline

---

## ⚙️ Key Features

- ✅ Medallion Architecture (Bronze / Silver / Gold)
- ✅ Incremental dbt models for efficient data processing
- ✅ Data quality validation using dbt tests
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Secure Snowflake integration (Key-Pair Authentication)
- ✅ Sigma dashboard for reporting
- ✅ Role-Based Access Control (RBAC)

---

## 📊 Data Models

### ✅ Fact Tables
- `fact_admissions` — Patient admissions data  
- `fact_discharges` — Patient discharge data  
- `fact_census` — Daily census tracking (ADC)  
- `fact_referrals` — Referral and conversion tracking  
- `fact_staffing` — Staffing and fill rate metrics  

---

### ✅ Dimension Tables
- `dim_patients` — Patient details  
- `dim_facilities` — Facility metadata  
- `dim_date` — Date dimension  

---

## 🔁 Incremental Processing

Fact tables are implemented as **incremental models**, ensuring:
- Only new data is processed
- Faster execution
- Reduced Snowflake compute cost

Example:
```sql
{{ config(materialized='incremental', unique_key='admission_id') }}

{% if is_incremental() %}
WHERE admission_date > (SELECT MAX(admission_date) FROM {{ this }})
{% endif %}

