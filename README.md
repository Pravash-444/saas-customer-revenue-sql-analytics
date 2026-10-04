# SaaS Customer & Revenue Analytics

A PostgreSQL-based data analytics portfolio project focused on customer
acquisition, subscription performance, revenue, churn, retention, and
product engagement. The project applies SQL to answer business questions
and create reusable KPI reporting.

## Project Objectives

-   Understand customer registration patterns and acquisition channels.
-   Evaluate subscription plans, statuses, and payment revenue.
-   Analyze churn and retention using defined monthly calculations.
-   Explore product engagement through monthly active users and
    cohort-based usage retention.
-   Apply intermediate and advanced PostgreSQL techniques to business
    analysis.
-   Create reusable KPI views and inspect query execution with
    `EXPLAIN ANALYZE`.

## Tools & Technologies

-   **Database:** PostgreSQL
-   **Query Language:** SQL
-   **Schema:** `sa`

## Database Schema

  -----------------------------------------------------------------------------------
  Table                Purpose              Key columns
  -------------------- -------------------- -----------------------------------------
  `sa.customers`       Customer profile and `customer_id`, `customer_name`, `email`,
                       acquisition          `country`, `signup_date`,
                       information          `acquisition_channel`

  `sa.plans`           Subscription plan    `plan_id`, `plan_name`, `monthly_price`,
                       details              `billing_cycle`

  `sa.subscriptions`   Customer             `subscription_id`, `customer_id`,
                       subscription records `plan_id`, `start_date`, `end_date`,
                                            `status`

  `sa.payments`        Payment transactions `payment_id`, `subscription_id`,
                       and status           `payment_date`, `amount`,
                                            `payment_status`, `payment_method`

  `sa.usage_events`    Product usage        `event_id`, `customer_id`, `event_date`,
                       activity             `event_type`, `duration_minutes`
  -----------------------------------------------------------------------------------

**Relationships** - One customer can have multiple subscriptions. - One
plan can be linked to multiple subscriptions. - One subscription can
have multiple payment records. - One customer can have multiple usage
events.

## Project Analysis & Business Questions

### Stage 1 --- Exploratory Data Analysis (EDA)

#### Customer Analysis

  -------------------------------------------------------------------------
  \#   Analysis           Business question
  ---- ------------------ -------------------------------------------------
  1    Total Registered   How many customers have registered with the
       Customers          company?

  2    Monthly Customer   How many new customers registered each month, and
       Registrations      how does registration change over time?

  3    Customers by       Which countries have the largest customer base?
       Country            

  4    Customers by       Which acquisition channels bring in the most
       Acquisition        customers?
       Channel            
  -------------------------------------------------------------------------

#### Revenue & Subscription Analysis

  --------------------------------------------------------------------------
  \#   Analysis             Business question
  ---- -------------------- ------------------------------------------------
  5    Monthly Revenue      How does successful payment revenue change from
       Trend                month to month?

  6    Revenue by           Which subscription plans generate the most
       Subscription Plan    successful payment revenue?

  7    Average Revenue per  What is the average successful payment revenue
       Customer (ARPC)      per customer with a successful payment?

  8    Subscriptions by     How many subscriptions are active, cancelled,
       Status               and expired?

  9    Monthly Subscription How many customers cancelled a subscription in
       Cancellations        each month?
  --------------------------------------------------------------------------

#### Churn & Retention Analysis

  --------------------------------------------------------------------------
  \#   Analysis       Business question
  ---- -------------- ------------------------------------------------------
  10   Monthly        Of the customers active at the start of each month,
       Customer Churn what percentage churned during that month?
       Rate           

  11   Monthly        Of the customers active at the start of each month,
       Customer       what percentage were retained after accounting for
       Retention Rate churn during that month?
  --------------------------------------------------------------------------

The monthly churn calculation uses customers active at the start of the
month as its denominator. The churn numerator counts cancelled customers
whose subscription ends during that month and who do not have another
subscription active into the following month. Expired subscriptions are
excluded from the cancellation numerator.

#### Product Usage Analysis

  --------------------------------------------------------------------------
  \#   Analysis            Business question
  ---- ------------------- -------------------------------------------------
  12   Monthly Active      How many distinct customers used the product in
       Users (MAU)         each month?

  13   Usage: Retained     How does average monthly usage activity and
       vs. Churned         duration differ between retained and churned
       Customers           customers?
  --------------------------------------------------------------------------

### Stage 2 --- Intermediate SQL Analysis

  --------------------------------------------------------------------------
  \#   Analysis         Business question
  ---- ---------------- ----------------------------------------------------
  1    Above-Average    Which customers generated more successful payment
       Revenue          revenue than the average revenue per paying customer
       Customers        in the dataset?

  2    Payment          How many successful and unsuccessful payments occur
       Performance by   through each payment method, and how much successful
       Method           revenue does each method generate?

  3    Monthly Revenue  How much successful revenue was generated each
       and MoM Growth   month, and what was the month-over-month percentage
                        change?

  4    Revenue by       How much successful payment revenue comes from each
       Acquisition      acquisition channel, and what is the revenue per
       Channel          paying customer for each channel?

  5    Paying Customer  What percentage of customers from each acquisition
       Rate by Channel  channel have at least one successful payment?

  6    Subscription     What are the listed prices and billing cycles of the
       Price by Plan    available subscription plans?

  7    Customers with   Which customers have more than one subscription, and
       Multiple         how many subscriptions does each have?
       Subscriptions    

  8    Subscriptions by How are subscriptions distributed across plans and
       Plan and Status  subscription statuses?

  9    Usage by Event   How many usage events occur for each event type, and
       Type             what are the average and total usage durations?

  10   Successful       Which countries generate the highest successful
       Revenue by       payment revenue?
       Country          

  11   Revenue per      How much successful payment revenue is generated per
       Paying Customer  paying customer in each country?
       by Country       

  12   Subscription     How do subscription counts by status differ across
       Status by        customer acquisition channels?
       Acquisition      
       Channel          

  13   Successful       How is successful payment revenue distributed across
       Revenue by       subscriptions' current statuses?
       Subscription     
       Status           
  --------------------------------------------------------------------------

For Stage 2, "paying customer" means a customer with at least one
successful payment in the available payment records. Revenue grouped by
current subscription status is historical successful payment revenue
categorized by the subscription's current status.

### Stage 3 --- Advanced SQL Analysis

  ----------------------------------------------------------------------------
  \#   Analysis         Business question
  ---- ---------------- ------------------------------------------------------
  1    Rank Customers   How do customers rank by total successful payment
       by Revenue       revenue?

  2    Top 3 Revenue    Who are the three highest-revenue customers in each
       Customers by     country?
       Country          

  3    Cumulative       How does successful revenue accumulate over the months
       Monthly Revenue  in the dataset?

  4    Customer Revenue How are paying customers distributed across four
       Quartiles        groups based on their successful payment revenue?

  5    Three-Month      What is the smoothed monthly revenue trend using a
       Moving Average   rolling three-month average?

  6    Monthly Revenue  What percentage of total successful revenue is
       Contribution     contributed by each month?

  7    Year-over-Year   How has monthly successful revenue changed compared
       Revenue Growth   with the same month in the previous year?

  8    Customer Payment How long is the observed period between each
       Activity Span    customer's first and latest successful payment?

  9    Payment Gaps     Which customers have gaps of more than 90 days between
       over 90 Days     successful payment dates?

  10   Payment Gaps by  How do payment intervals vary by billing cycle,
       Billing Cycle    including average, longest, and over-90-day gaps?

  11   Cohort Analysis  For customers who signed up in the same month, how
       --- Monthly      many are active in each subsequent month during the
       Product Usage    first 12 months, and what percentage of the original
       Retention        cohort do they represent?
  ----------------------------------------------------------------------------

**Cohort definition:** Customers are grouped by signup month. Activity
is measured as distinct customers with at least one usage event in a
given activity month. The retention rate is active customers in the
cohort-month divided by the original cohort size. This measures monthly
product usage, not continuous month-to-month activity or
paid-subscription retention. Months with no activity are not represented
as zero-activity rows in the current query, and newer cohorts have
incomplete follow-up periods.

### Stage 4 --- KPI Reporting & Performance

  ---------------------------------------------------------------------------------
  \#   Analysis            Business question
  ---- ------------------- --------------------------------------------------------
  1    Overall Business    What is the current high-level picture of registered
       KPI Snapshot        customers, active subscriptions, successful payment
                           revenue, historical paying customers, and payment
                           success rate?

  2    Monthly Revenue &   How do monthly successful revenue, payment volume,
       Payment Performance successful payment count, and payment success rate
                           change over time?

  3    Overall KPI View    Can the overall business KPIs be made available through
                           a reusable PostgreSQL view?

  4    Monthly Revenue     Can monthly revenue and payment performance be made
       Performance View    available through a reusable PostgreSQL view?

  5    `EXPLAIN ANALYZE`   How does PostgreSQL execute the monthly revenue
                           performance query, and does the execution plan indicate
                           a need for optimization?
  ---------------------------------------------------------------------------------

The project created these reusable views:

-   `sa.vw_overall_business_kpis`
-   `sa.vw_monthly_revenue_performance`

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

  KPI                                        Result
  ------------------------------------ ------------
  Total customers                             2,000
  Active customers                            1,331
  Active subscriptions                        1,331
  Total successful revenue               200,055.69
  Customers with successful payments            458
  Payment success rate                       90.91%

The monthly revenue results shared covered January 2023 through
September 2026. Within those results, May 2026 had the highest monthly
successful revenue at **8,594.12**. December 2024 had the lowest monthly
payment success rate at **83.87%**.

Revenue values are shown without a currency symbol because the project
data does not specify a currency.

### Exported Query Results

Selected outputs are available in the [`results/`](results/) folder:

  ----------------------------------------------------------------------------------------------
  File                                                       Description
  ---------------------------------------------------------- -----------------------------------
  [`monthly_revenue.csv`](results/monthly_revenue.csv)       Monthly successful revenue and
                                                             payment performance.

  [`monthly_churn.csv`](results/monthly_churn.csv)           Monthly customer churn results.

  [`monthly_retention.csv`](results/monthly_retention.csv)   Monthly customer retention results.
  ----------------------------------------------------------------------------------------------

These files provide examples of the project's results; the corresponding
SQL analysis and definitions are documented in `queries.sql` and this
README.

## Performance Review

The `EXPLAIN ANALYZE` output for selecting from
`sa.vw_monthly_revenue_performance` and ordering by month showed:

-   Sequential scan of 8,000 payment rows
-   Hash aggregation to 45 monthly rows
-   Quicksort of the monthly output
-   Planning time: **0.270 ms**
-   Execution time: **11.724 ms**

For the current dataset and full-table monthly aggregation, the measured
execution time was low and the plan did not show a clear need for an
index. This is a finding for the current query and dataset size, not a
general conclusion that indexes are unnecessary.

## SQL Concepts Demonstrated

-   `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, and `HAVING`
-   Aggregate functions and conditional aggregation using `FILTER` and
    `CASE`
-   Inner and outer joins
-   Subqueries and Common Table Expressions (CTEs)
-   Date/time functions such as `DATE_TRUNC`, `EXTRACT`, and
    `generate_series`
-   Window functions such as `LAG`, `RANK`, `ROW_NUMBER`, `NTILE`, and
    windowed aggregates
-   Month-over-month and year-over-year growth
-   Cumulative totals and moving averages
-   Revenue segmentation and cohort analysis
-   PostgreSQL views
-   Query plan analysis using `EXPLAIN ANALYZE`

## Repository Contents

-   `queries.sql` --- SQL script containing exploratory checks, business
    analysis queries, KPI views, and performance inspection.
-   `data/raw/` --- source CSV files for customers, plans,
    subscriptions, payments, and usage events.
-   `results/` --- selected query outputs exported as CSV files.
-   `results/README.md` --- descriptions of the selected result files.

## Key Insights

-   **Customer Base:** The business has 2,000 registered customers, with
    1,331 currently active customers.
-   **Revenue:** Total successful revenue is 200,055.69 (currency not
    specified in the dataset).
-   **Payment Performance:** The overall payment success rate is 90.91%,
    indicating that some payment attempts are unsuccessful.
-   **Historical Paying Customers:** 458 customers have made at least
    one successful payment. This is a lifetime measure, not the number
    of current paying customers.
-   **Monthly Performance:** May 2026 recorded the highest monthly
    successful revenue at 8,594.12, while December 2024 had the lowest
    payment success rate at 83.87%.

## Business Recommendations

-   **Improve Payment Success:** Investigate unsuccessful payments by
    payment method and identify opportunities to reduce payment
    failures.
-   **Monitor Customer Activity:** Track active customers and
    subscription status over time to identify changes in customer
    engagement.
-   **Investigate Revenue Trends:** Examine the factors contributing to
    monthly revenue fluctuations and the strong performance observed in
    May 2026.
-   **Strengthen Retention:** Use cohort and churn analyses to identify
    patterns in customer activity and inform retention initiatives.

> **Note:** These recommendations are potential actions based on the
> analysis, not proven causes or outcomes. More detailed findings would
> require reviewing the corresponding query results.

## Author

**Pravash Paul**
