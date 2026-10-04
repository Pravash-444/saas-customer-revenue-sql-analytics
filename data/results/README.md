# Selected Analysis Results

This folder contains three selected CSV outputs from the SaaS Customer & Revenue Analytics project.

## 1. Monthly Revenue

**File:** [`monthly_revenue.csv`](monthly_revenue.csv)

Contains monthly successful payment revenue, payment volume, successful payment count, and payment success rate. This output helps track revenue trends and payment performance over time.

## 2. Monthly Churn

**File:** [`monthly_churn.csv`](monthly_churn.csv)

Contains monthly customer churn results. The churn rate uses customers active at the start of the month as its denominator.

The churn count includes cancelled customers whose subscription ends during that month and who do not have another subscription active into the following month. Expired subscriptions are excluded from the cancellation numerator.

## 3. Monthly Retention

**File:** [`monthly_retention.csv`](monthly_retention.csv)

Contains the monthly customer retention rate, calculated as the share of customers active at the start of the month who remain after accounting for churn during that month.

---

## Project References

- [Main Project README](../../README.md) — Project overview, objectives, database schema, analysis stages, business questions, and key insights.
- [SQL Queries](../../queries.sql) — SQL queries used for the analysis and KPI reporting.

These CSV files are selected query outputs for convenient review. Refer to the main README and SQL script for the full business context and calculation logic.
