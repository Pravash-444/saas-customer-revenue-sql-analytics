# SaaS Customer & Revenue Analytics

A PostgreSQL-based data analytics portfolio project focused on customer
acquisition, subscription performance, revenue, churn, retention, and
product engagement. The project applies SQL to answer business questions
and create reusable KPI reporting.

## Project Objectives

- Understand customer registration patterns and acquisition channels.
- Evaluate subscription plans, statuses, and payment revenue.
- Analyze churn and retention using defined monthly calculations.
- Explore product engagement through monthly active users and
  cohort-based usage retention.
- Apply intermediate and advanced PostgreSQL techniques to business
  analysis.
- Create reusable KPI views and inspect query execution with
  `EXPLAIN ANALYZE`.

## Tools & Technologies

- **Database:** PostgreSQL
- **Query Language:** SQL
- **Schema:** `sa`

## Database Schema

| Table              | Purpose                                      | Key columns                                                                                   |
|:-------------------|:---------------------------------------------|:----------------------------------------------------------------------------------------------|
| `sa.customers`     | Customer profile and acquisition information | `customer_id`, `customer_name`, `email`, `country`, `signup_date`, `acquisition_channel`      |
| `sa.plans`         | Subscription plan details                    | `plan_id`, `plan_name`, `monthly_price`, `billing_cycle`                                      |
| `sa.subscriptions` | Customer subscription records                | `subscription_id`, `customer_id`, `plan_id`, `start_date`, `end_date`, `status`               |
| `sa.payments`      | Payment transactions and status              | `payment_id`, `subscription_id`, `payment_date`, `amount`, `payment_status`, `payment_method` |
| `sa.usage_events`  | Product usage activity                       | `event_id`, `customer_id`, `event_date`, `event_type`, `duration_minutes`                     |

**Relationships** - One customer can have multiple subscriptions. - One
plan can be linked to multiple subscriptions. - One subscription can
have multiple payment records. - One customer can have multiple usage
events.

## Project Analysis & Business Questions

### Stage 1 — Exploratory Data Analysis (EDA)

#### Customer Analysis

| \#  | Analysis                         | Business question                                                                         |
|:----|:---------------------------------|:------------------------------------------------------------------------------------------|
| 1   | Total Registered Customers       | How many customers have registered with the company?                                      |
| 2   | Monthly Customer Registrations   | How many new customers registered each month, and how does registration change over time? |
| 3   | Customers by Country             | Which countries have the largest customer base?                                           |
| 4   | Customers by Acquisition Channel | Which acquisition channels bring in the most customers?                                   |

#### Revenue & Subscription Analysis

| \#  | Analysis                            | Business question                                                                      |
|:----|:------------------------------------|:---------------------------------------------------------------------------------------|
| 5   | Monthly Revenue Trend               | How does successful payment revenue change from month to month?                        |
| 6   | Revenue by Subscription Plan        | Which subscription plans generate the most successful payment revenue?                 |
| 7   | Average Revenue per Customer (ARPC) | What is the average successful payment revenue per customer with a successful payment? |
| 8   | Subscriptions by Status             | How many subscriptions are active, cancelled, and expired?                             |
| 9   | Monthly Subscription Cancellations  | How many customers cancelled a subscription in each month?                             |

#### Churn & Retention Analysis

| \#  | Analysis                        | Business question                                                                                                               |
|:----|:--------------------------------|:--------------------------------------------------------------------------------------------------------------------------------|
| 10  | Monthly Customer Churn Rate     | Of the customers active at the start of each month, what percentage churned during that month?                                  |
| 11  | Monthly Customer Retention Rate | Of the customers active at the start of each month, what percentage were retained after accounting for churn during that month? |

The monthly churn calculation uses customers active at the start of the
month as its denominator. The churn numerator counts cancelled customers
whose subscription ends during that month and who do not have another
subscription active into the following month. Expired subscriptions are
excluded from the cancellation numerator.

#### Product Usage Analysis

| \#  | Analysis                              | Business question                                                                                   |
|:----|:--------------------------------------|:----------------------------------------------------------------------------------------------------|
| 12  | Monthly Active Users (MAU)            | How many distinct customers used the product in each month?                                         |
| 13  | Usage: Retained vs. Churned Customers | How does average monthly usage activity and duration differ between retained and churned customers? |

### Stage 2 — Intermediate SQL Analysis

| \#  | Analysis                                   | Business question                                                                                                                           |
|:----|:-------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------|
| 1   | Above-Average Revenue Customers            | Which customers generated more successful payment revenue than the average revenue per paying customer in the dataset?                      |
| 2   | Payment Performance by Method              | How many successful and unsuccessful payments occur through each payment method, and how much successful revenue does each method generate? |
| 3   | Monthly Revenue and MoM Growth             | How much successful revenue was generated each month, and what was the month-over-month percentage change?                                  |
| 4   | Revenue by Acquisition Channel             | How much successful payment revenue comes from each acquisition channel, and what is the revenue per paying customer for each channel?      |
| 5   | Paying Customer Rate by Channel            | What percentage of customers from each acquisition channel have at least one successful payment?                                            |
| 6   | Subscription Price by Plan                 | What are the listed prices and billing cycles of the available subscription plans?                                                          |
| 7   | Customers with Multiple Subscriptions      | Which customers have more than one subscription, and how many subscriptions does each have?                                                 |
| 8   | Subscriptions by Plan and Status           | How are subscriptions distributed across plans and subscription statuses?                                                                   |
| 9   | Usage by Event Type                        | How many usage events occur for each event type, and what are the average and total usage durations?                                        |
| 10  | Successful Revenue by Country              | Which countries generate the highest successful payment revenue?                                                                            |
| 11  | Revenue per Paying Customer by Country     | How much successful payment revenue is generated per paying customer in each country?                                                       |
| 12  | Subscription Status by Acquisition Channel | How do subscription counts by status differ across customer acquisition channels?                                                           |
| 13  | Successful Revenue by Subscription Status  | How is successful payment revenue distributed across subscriptions’ current statuses?                                                       |

For Stage 2, “paying customer” means a customer with at least one
successful payment in the available payment records. Revenue grouped by
current subscription status is historical successful payment revenue
categorized by the subscription’s current status.

### Stage 3 — Advanced SQL Analysis

| \#  | Analysis                                          | Business question                                                                                                                                                                     |
|:----|:--------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1   | Rank Customers by Revenue                         | How do customers rank by total successful payment revenue?                                                                                                                            |
| 2   | Top 3 Revenue Customers by Country                | Who are the three highest-revenue customers in each country?                                                                                                                          |
| 3   | Cumulative Monthly Revenue                        | How does successful revenue accumulate over the months in the dataset?                                                                                                                |
| 4   | Customer Revenue Quartiles                        | How are paying customers distributed across four groups based on their successful payment revenue?                                                                                    |
| 5   | Three-Month Moving Average                        | What is the smoothed monthly revenue trend using a rolling three-month average?                                                                                                       |
| 6   | Monthly Revenue Contribution                      | What percentage of total successful revenue is contributed by each month?                                                                                                             |
| 7   | Year-over-Year Revenue Growth                     | How has monthly successful revenue changed compared with the same month in the previous year?                                                                                         |
| 8   | Customer Payment Activity Span                    | How long is the observed period between each customer’s first and latest successful payment?                                                                                          |
| 9   | Payment Gaps over 90 Days                         | Which customers have gaps of more than 90 days between successful payment dates?                                                                                                      |
| 10  | Payment Gaps by Billing Cycle                     | How do payment intervals vary by billing cycle, including average, longest, and over-90-day gaps?                                                                                     |
| 11  | Cohort Analysis — Monthly Product Usage Retention | For customers who signed up in the same month, how many are active in each subsequent month during the first 12 months, and what percentage of the original cohort do they represent? |

**Cohort definition:** Customers are grouped by signup month. Activity
is measured as distinct customers with at least one usage event in a
given activity month. The retention rate is active customers in the
cohort-month divided by the original cohort size. This measures monthly
product usage, not continuous month-to-month activity or
paid-subscription retention. Months with no activity are not represented
as zero-activity rows in the current query, and newer cohorts have
incomplete follow-up periods.

### Stage 4 — KPI Reporting & Performance

| \#  | Analysis                              | Business question                                                                                                                                                        |
|:----|:--------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1   | Overall Business KPI Snapshot         | What is the current high-level picture of registered customers, active subscriptions, successful payment revenue, historical paying customers, and payment success rate? |
| 2   | Monthly Revenue & Payment Performance | How do monthly successful revenue, payment volume, successful payment count, and payment success rate change over time?                                                  |
| 3   | Overall KPI View                      | Can the overall business KPIs be made available through a reusable PostgreSQL view?                                                                                      |
| 4   | Monthly Revenue Performance View      | Can monthly revenue and payment performance be made available through a reusable PostgreSQL view?                                                                        |
| 5   | `EXPLAIN ANALYZE`                     | How does PostgreSQL execute the monthly revenue performance query, and does the execution plan indicate a need for optimization?                                         |

The project created these reusable views:

- `sa.vw_overall_business_kpis`
- `sa.vw_monthly_revenue_performance`

Example usage:

``` sql
SELECT *
FROM sa.vw_overall_business_kpis;

SELECT *
FROM sa.vw_monthly_revenue_performance
ORDER BY month;
```

These are standard PostgreSQL views, not stored snapshots. Their queries
are evaluated against the underlying tables when selected.

## Selected Results

The overall KPI snapshot returned the following results:

| KPI                                |     Result |
|:-----------------------------------|-----------:|
| Total customers                    |      2,000 |
| Active customers                   |      1,331 |
| Active subscriptions               |      1,331 |
| Total successful revenue           | 200,055.69 |
| Customers with successful payments |        458 |
| Payment success rate               |     90.91% |

The monthly revenue results shared covered January 2023 through
September 2026. Within those results, May 2026 had the highest monthly
successful revenue at **8,594.12**. December 2024 had the lowest monthly
payment success rate at **83.87%**.

Revenue values are shown without a currency symbol because the project
data does not specify a currency.

### Exported Query Results

Selected outputs are available in the [`results/`](data/results/)
folder:

| File                                                          | Description                                         |
|:--------------------------------------------------------------|:----------------------------------------------------|
| [`monthly_revenue.csv`](data/results/monthly_revenue.csv)     | Monthly successful revenue and payment performance. |
| [`monthly_churn.csv`](data/results/monthly_churn.csv)         | Monthly customer churn results.                     |
| [`monthly_retention.csv`](data/results/monthly_retention.csv) |  Monthly customer retention results.             |

These files provide examples of the project’s results; the corresponding
SQL analysis and definitions are documented in `queries.sql` and this
README.

## Performance Review

The `EXPLAIN ANALYZE` output for selecting from
`sa.vw_monthly_revenue_performance` and ordering by month showed:

- Sequential scan of 8,000 payment rows
- Hash aggregation to 45 monthly rows
- Quicksort of the monthly output
- Planning time: **0.270 ms**
- Execution time: **11.724 ms**

For the current dataset and full-table monthly aggregation, the measured
execution time was low and the plan did not show a clear need for an
index. This is a finding for the current query and dataset size, not a
general conclusion that indexes are unnecessary.

## SQL Concepts Demonstrated

- `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, and `HAVING`
- Aggregate functions and conditional aggregation using `FILTER` and
  `CASE`
- Inner and outer joins
- Subqueries and Common Table Expressions (CTEs)
- Date/time functions such as `DATE_TRUNC`, `EXTRACT`, and
  `generate_series`
- Window functions such as `LAG`, `RANK`, `ROW_NUMBER`, `NTILE`, and
  windowed aggregates
- Month-over-month and year-over-year growth
- Cumulative totals and moving averages
- Revenue segmentation and cohort analysis
- PostgreSQL views
- Query plan analysis using `EXPLAIN ANALYZE`

## Repository Contents

- `queries.sql` — SQL script containing exploratory checks, business
  analysis queries, KPI views, and performance inspection.
- `data/raw/` — source CSV files for customers, plans, subscriptions,
  payments, and usage events.
- `data/results/` — selected query outputs exported as CSV files.
- `data/results/README.md` — descriptions of the selected result files.

## Key Insights

- **Customer Base:** The business has 2,000 registered customers, with
  1,331 currently active customers.
- **Revenue:** Total successful revenue is 200,055.69 (currency not
  specified in the dataset).
- **Payment Performance:** The overall payment success rate is 90.91%,
  indicating that some payment attempts are unsuccessful.
- **Historical Paying Customers:** 458 customers have made at least one
  successful payment. This is a lifetime measure, not the number of
  current paying customers.
- **Monthly Performance:** May 2026 recorded the highest monthly
  successful revenue at 8,594.12, while December 2024 had the lowest
  payment success rate at 83.87%.

## Business Recommendations

- **Improve Payment Success:** Investigate unsuccessful payments by
  payment method and identify opportunities to reduce payment failures.
- **Monitor Customer Activity:** Track active customers and subscription
  status over time to identify changes in customer engagement.
- **Investigate Revenue Trends:** Examine the factors contributing to
  monthly revenue fluctuations and the strong performance observed in
  May 2026.
- **Strengthen Retention:** Use cohort and churn analyses to identify
  patterns in customer activity and inform retention initiatives.

> **Note:** These recommendations are potential actions based on the
> analysis, not proven causes or outcomes. More detailed findings would
> require reviewing the corresponding query results.

## Author

**Pravash Paul**
