# SaaS Customer & Revenue Analytics

A PostgreSQL-based data analytics portfolio project exploring customer
acquisition, subscription performance, revenue, churn, retention, and
product engagement. The project uses SQL to turn relational data into
business-focused analysis and reusable KPI reporting.

## Project Objectives

- Understand customer registration patterns and acquisition channels.
- Analyze subscription plans, statuses, and revenue performance.
- Measure monthly churn and retention using explicit subscription-based
  definitions.
- Explore product engagement through monthly active users, usage
  behavior, and cohort retention.
- Apply intermediate and advanced PostgreSQL techniques to answer
  business questions.
- Create reusable KPI views and inspect query execution with
  `EXPLAIN ANALYZE`.

## Technology

- **Database:** PostgreSQL
- **Language:** SQL
- **Schema:** `sa`

## Data Model

The database contains five related tables:

| Table              | Grain / purpose                 | Main columns                                                                                  |
|:-------------------|:--------------------------------|:----------------------------------------------------------------------------------------------|
| `sa.customers`     | One row per customer            | `customer_id`, `customer_name`, `email`, `country`, `signup_date`, `acquisition_channel`      |
| `sa.plans`         | One row per subscription plan   | `plan_id`, `plan_name`, `monthly_price`, `billing_cycle`                                      |
| `sa.subscriptions` | One row per subscription        | `subscription_id`, `customer_id`, `plan_id`, `start_date`, `end_date`, `status`               |
| `sa.payments`      | One row per payment record      | `payment_id`, `subscription_id`, `payment_date`, `amount`, `payment_status`, `payment_method` |
| `sa.usage_events`  | One row per product usage event | `event_id`, `customer_id`, `event_date`, `event_type`, `duration_minutes`                     |

Relationships: - A customer can have multiple subscriptions. - A plan
can be associated with multiple subscriptions. - A subscription can have
multiple payment records. - A customer can have multiple usage events.

## Project Workflow

### Stage 1 — Exploratory Data Analysis (EDA)

**Customer Analysis** - Count registered customers. - Analyze monthly
customer registrations. - Compare customer counts by country. - Compare
customer counts by acquisition channel.

**Revenue & Subscription Analysis** - Track monthly successful payment
revenue. - Compare revenue across subscription plans. - Calculate
average revenue per customer (ARPC) based on customers with successful
payments. - Review subscriptions by status. - Count customers cancelling
subscriptions by cancellation month.

**Churn & Retention** - Calculate monthly customer churn rate. -
Calculate monthly customer retention rate.

The monthly churn calculation uses customers active at the start of the
month as its denominator. The churn numerator counts customers whose
cancelled subscription ends during the month and who do not have another
subscription active into the following month. Expired subscriptions are
not treated as cancellations in this churn measure.

**Product Usage** - Calculate monthly active users (MAU). - Compare
average usage events and usage duration for retained and churned
customers by month.

### Stage 2 — Intermediate SQL Analysis

- Identify customers generating above-average successful payment
  revenue.
- Compare successful and unsuccessful payments by payment method.
- Calculate monthly revenue and month-over-month (MoM) growth.
- Analyze revenue and revenue per paying customer by acquisition
  channel.
- Calculate paying customer rate by acquisition channel.
- Review plan prices and billing cycles.
- Identify customers with multiple subscriptions.
- Analyze subscription counts by plan and status.
- Calculate average usage duration by event type.
- Analyze successful revenue by country.
- Calculate average revenue per paying customer by country.
- Compare subscription status by acquisition channel.
- Analyze successful revenue by current subscription status.

### Stage 3 — Advanced SQL Analysis

- Rank customers by successful payment revenue.
- Identify the top three revenue-generating customers in each country.
- Calculate cumulative monthly revenue.
- Segment customers into revenue quartiles.
- Calculate a three-month moving average of revenue.
- Calculate each month’s contribution to total revenue.
- Calculate year-over-year (YoY) revenue growth.
- Classify customers by the span between their first and latest
  successful payment.
- Identify customers with more than 90 days between successful payments.
- Analyze payment gaps by billing cycle.
- Perform cohort analysis for monthly product usage retention over the
  first 12 months after signup.

**Cohort definition:** Customers are grouped by signup month. Monthly
activity is measured using distinct customers with at least one usage
event in each activity month. Retention rate is active customers in that
cohort-month divided by the original cohort size. This measures monthly
product usage, not continuous activity or paid-subscription retention.
Cohort months with no activity are not returned as zero-activity rows by
the current query, and recent cohorts have incomplete observation
periods.

### Stage 4 — KPI Reporting & Performance

- Create an overall business KPI snapshot.
- Report monthly successful revenue, payment volume, successful
  payments, and payment success rate.
- Create the reusable view `sa.vw_overall_business_kpis`.
- Create the reusable view `sa.vw_monthly_revenue_performance`.
- Use `EXPLAIN ANALYZE` to inspect the monthly revenue view’s execution
  plan.

The KPI snapshot distinguishes active customers from customers with
historical successful payments. Historical paying customers should not
be interpreted as current paying customers.

## KPI Views

### `sa.vw_overall_business_kpis`

Returns a single-row snapshot containing: - Total registered customers -
Active customers - Active subscriptions - Total successful payment
revenue - Distinct customers with successful payments - Payment success
rate

``` sql
SELECT *
FROM sa.vw_overall_business_kpis;
```

### `sa.vw_monthly_revenue_performance`

Returns monthly: - Successful payment revenue - Total payment records -
Successful payment records - Payment success rate

``` sql
SELECT *
FROM sa.vw_monthly_revenue_performance
ORDER BY month;
```

These are standard PostgreSQL views, not stored snapshots. Their results
are calculated from the underlying tables when queried.

## Selected Results Shared During Analysis

The overall KPI snapshot returned:

| KPI                                |     Result |
|:-----------------------------------|-----------:|
| Total customers                    |      2,000 |
| Active customers                   |      1,331 |
| Active subscriptions               |      1,331 |
| Total successful revenue           | 200,055.69 |
| Customers with successful payments |        458 |
| Payment success rate               |     90.91% |

The monthly revenue output covered January 2023 through September 2026.
Within the results shared, May 2026 had the highest monthly successful
revenue (8,594.12), while December 2024 had the lowest payment success
rate (83.87%).

No currency is specified in the source SQL/results, so revenue values
are shown without a currency symbol.

## SQL Skills Demonstrated

- Filtering, sorting, grouping, and aggregation
- `JOIN`, `LEFT JOIN`, and multi-table analysis
- Subqueries and Common Table Expressions (CTEs)
- Conditional aggregation with `FILTER` and `CASE`
- Date/time functions including `DATE_TRUNC`, `EXTRACT`, and
  `generate_series`
- Window functions including `LAG`, ranking functions, and windowed
  aggregates
- Revenue growth, cumulative totals, moving averages, and quartile
  segmentation
- Cohort-based product usage retention
- PostgreSQL views
- Query plan inspection with `EXPLAIN ANALYZE`

## Performance Review

The `EXPLAIN ANALYZE` result for selecting from
`sa.vw_monthly_revenue_performance` and ordering by month showed: -
Sequential scan of 8,000 payment rows - Hash aggregation to 45 monthly
rows - Sort of the 45 monthly rows using quicksort - Planning time:
0.270 ms - Execution time: 11.724 ms

For the dataset size used in this analysis, the observed execution time
was low and the plan did not indicate a clear need for an index for this
full-table monthly aggregation. This is an observation for the current
dataset and query, not a general claim that indexes are unnecessary.

## Repository Contents

- `queries(2).sql` — SQL script containing table definitions,
  exploratory checks, analysis queries, KPI views, and performance
  inspection.

## Notes & Limitations

- The analysis reflects the fields and business rules encoded in the SQL
  script.
- Successful payment revenue is based on payment records marked
  `successful`.
- Monthly product usage retention is not equivalent to subscription
  retention or continuous month-over-month retention.
- Churn is based on cancelled subscriptions under the monthly definition
  described above; expired subscriptions are excluded from the
  cancellation numerator.
- The SQL file contains query logic; not every query’s result set is
  embedded in it. Findings are reported only where outputs were shared
  during the analysis.

## Author

**Pravash Paul**
