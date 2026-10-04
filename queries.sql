--Stage 1

--Exploratory Data Analysis (EDA)

--Review table columns and data types.

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'sa'
ORDER BY table_name, ordinal_position;


--EDA — Customer Analysis

--Q1. How many total customers have registered with the company?

SELECT
    COUNT(DISTINCT customer_id) AS total_customers
FROM sa.customers;

--Q2. How many new customers registered each month?

SELECT
    DATE_TRUNC('month', signup_date)::DATE AS signup_month,
    COUNT(DISTINCT customer_id) AS new_customers
FROM sa.customers
GROUP BY DATE_TRUNC('month', signup_date)
ORDER BY signup_month;

--Q3. Which countries generate the most customers?

SELECT
    country,
    COUNT(DISTINCT customer_id) AS total_customers
FROM sa.customers
GROUP BY country
ORDER BY total_customers DESC;

--Q4. Which acquisition channels generate the most customers?

SELECT
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS total_customers
FROM sa.customers
GROUP BY acquisition_channel
ORDER BY total_customers DESC;

==========================================================

--Revenue & Subscription Analysis.

--Q5. What is the monthly revenue trend?

SELECT
    DATE_TRUNC('month', payment_date)::DATE AS revenue_month,
    SUM(amount) AS monthly_revenue
FROM sa.payments
WHERE LOWER(TRIM(payment_status)) = 'successful'
GROUP BY DATE_TRUNC('month', payment_date)
ORDER BY revenue_month;


--Q6. Which subscription plans generate the most revenue?

SELECT
    p.plan_name,
    SUM(pay.amount) AS total_revenue
FROM sa.payments pay
JOIN sa.subscriptions s
    ON pay.subscription_id = s.subscription_id
JOIN sa.plans p
    ON s.plan_id = p.plan_id
WHERE LOWER(TRIM(pay.payment_status)) = 'successful'
GROUP BY p.plan_name
ORDER BY total_revenue DESC;


--Q7. What is the average revenue per customer (ARPC)?

SELECT
    ROUND(
        SUM(pay.amount) / COUNT(DISTINCT s.customer_id),
        2
    ) AS average_revenue_per_customer
FROM sa.payments pay
JOIN sa.subscriptions s
    ON pay.subscription_id = s.subscription_id
WHERE LOWER(TRIM(pay.payment_status)) = 'successful';


--Q8. How many subscriptions are active, cancelled and expired?

SELECT
    status,
    COUNT(DISTINCT subscription_id) AS total_subscriptions
FROM sa.subscriptions
GROUP BY status
ORDER BY total_subscriptions DESC;


--Q9. How many customers cancelled their subscriptions each month?

SELECT
    DATE_TRUNC('month', end_date)::DATE AS cancellation_month,
    COUNT(DISTINCT customer_id) AS cancelled_customers
FROM sa.subscriptions
WHERE LOWER(TRIM(status)) = 'cancelled'
  AND end_date IS NOT NULL
GROUP BY DATE_TRUNC('month', end_date)
ORDER BY cancellation_month;

============================================================================================

----Churn & Retention Analysis

--Q10. What is the monthly customer churn rate?


WITH months AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(start_date)),
        DATE_TRUNC('month', MAX(end_date)),
        INTERVAL '1 month'
    )::DATE AS month_start
    FROM sa.subscriptions
),
starting_customers AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT s.customer_id) AS active_at_start
    FROM months m
    JOIN sa.subscriptions s
        ON s.start_date < m.month_start
       AND (s.end_date IS NULL OR s.end_date >= m.month_start)
    GROUP BY m.month_start
),
churned_customers AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT s.customer_id) AS churned
    FROM months m
    JOIN sa.subscriptions s
        ON s.start_date < m.month_start
       AND s.end_date >= m.month_start
       AND s.end_date < m.month_start + INTERVAL '1 month'
       AND LOWER(TRIM(s.status)) = 'cancelled'
    WHERE NOT EXISTS (
        SELECT 1
        FROM sa.subscriptions s2
        WHERE s2.customer_id = s.customer_id
          AND s2.subscription_id <> s.subscription_id
          AND s2.start_date < m.month_start + INTERVAL '1 month'
          AND (
              s2.end_date IS NULL
              OR s2.end_date >= m.month_start + INTERVAL '1 month'
          )
    )
    GROUP BY m.month_start
)
SELECT
    sc.month_start,
    sc.active_at_start,
    COALESCE(cc.churned, 0) AS churned_customers,
    ROUND(
        COALESCE(cc.churned, 0) * 100.0 /
        NULLIF(sc.active_at_start, 0),
        2
    ) AS churn_rate_pct
FROM starting_customers sc
LEFT JOIN churned_customers cc
    ON sc.month_start = cc.month_start
ORDER BY sc.month_start;

--Q11. What is the monthly customer retention rate?

WITH months AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(start_date)),
        DATE_TRUNC('month', MAX(end_date)),
        INTERVAL '1 month'
    )::DATE AS month_start
    FROM sa.subscriptions
),
starting_customers AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT s.customer_id) AS active_at_start
    FROM months m
    JOIN sa.subscriptions s
        ON s.start_date < m.month_start
       AND (s.end_date IS NULL OR s.end_date >= m.month_start)
    GROUP BY m.month_start
),
churned_customers AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT s.customer_id) AS churned
    FROM months m
    JOIN sa.subscriptions s
        ON s.start_date < m.month_start
       AND s.end_date >= m.month_start
       AND s.end_date < m.month_start + INTERVAL '1 month'
       AND LOWER(TRIM(s.status)) = 'cancelled'
    WHERE NOT EXISTS (
        SELECT 1
        FROM sa.subscriptions s2
        WHERE s2.customer_id = s.customer_id
          AND s2.subscription_id <> s.subscription_id
          AND s2.start_date < m.month_start + INTERVAL '1 month'
          AND (
              s2.end_date IS NULL
              OR s2.end_date >= m.month_start + INTERVAL '1 month'
          )
    )
    GROUP BY m.month_start
)
SELECT
    sc.month_start,
    sc.active_at_start,
    COALESCE(cc.churned, 0) AS churned_customers,
    ROUND(
        (sc.active_at_start - COALESCE(cc.churned, 0)) * 100.0
        / NULLIF(sc.active_at_start, 0),
        2
    ) AS retention_rate_pct
FROM starting_customers sc
LEFT JOIN churned_customers cc
    ON sc.month_start = cc.month_start
ORDER BY sc.month_start;


============================================================================================

--Product Usage Analysis


--Q12. How many Monthly Active Users (MAU) does the company have?

SELECT
    DATE_TRUNC('month', event_date)::DATE AS usage_month,
    COUNT(DISTINCT customer_id) AS monthly_active_users
FROM sa.usage_events
GROUP BY DATE_TRUNC('month', event_date)
ORDER BY usage_month;


--Q13. How does product usage differ between retained and churned customers?


WITH months AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(start_date)),
        DATE_TRUNC('month', MAX(end_date)),
        INTERVAL '1 month'
    )::DATE AS month_start
    FROM sa.subscriptions
),
starting_customers AS (
    SELECT DISTINCT
        m.month_start,
        s.customer_id
    FROM months m
    JOIN sa.subscriptions s
        ON s.start_date < m.month_start
       AND (s.end_date IS NULL OR s.end_date >= m.month_start)
),
churned_customers AS (
    SELECT DISTINCT
        m.month_start,
        s.customer_id
    FROM months m
    JOIN sa.subscriptions s
        ON s.end_date >= m.month_start
       AND s.end_date < m.month_start + INTERVAL '1 month'
       AND LOWER(TRIM(s.status)) = 'cancelled'
    WHERE NOT EXISTS (
        SELECT 1
        FROM sa.subscriptions s2
        WHERE s2.customer_id = s.customer_id
          AND s2.subscription_id <> s.subscription_id
          AND s2.start_date < m.month_start + INTERVAL '1 month'
          AND (s2.end_date IS NULL OR
               s2.end_date >= m.month_start + INTERVAL '1 month')
    )
),
monthly_usage AS (
    SELECT
        DATE_TRUNC('month', event_date)::DATE AS month_start,
        customer_id,
        COUNT(*) AS usage_events,
        SUM(duration_minutes) AS total_minutes
    FROM sa.usage_events
    GROUP BY 1, 2
)
SELECT
    sc.month_start,
    CASE
        WHEN cc.customer_id IS NOT NULL THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,
    COUNT(*) AS total_customers,
    ROUND(AVG(COALESCE(mu.usage_events, 0)), 2) AS avg_usage_events,
    ROUND(AVG(COALESCE(mu.total_minutes, 0)), 2) AS avg_usage_minutes
FROM starting_customers sc
LEFT JOIN churned_customers cc
    ON sc.month_start = cc.month_start
   AND sc.customer_id = cc.customer_id
LEFT JOIN monthly_usage mu
    ON sc.month_start = mu.month_start
   AND sc.customer_id = mu.customer_id
GROUP BY
    sc.month_start,
    customer_status
ORDER BY
    sc.month_start,
    customer_status;


===========================================================================================================================================================
===========================================================================================================================================================

--Stage 2 — Intermediate SQL Analysis

--Q1 — Identify Customers Generating Above-Average Revenue

WITH customer_revenue AS (
    SELECT
        s.customer_id,
        SUM(p.amount) AS total_revenue
    FROM sa.payments p
    JOIN sa.subscriptions s
        ON p.subscription_id = s.subscription_id
    WHERE LOWER(TRIM(p.payment_status)) = 'successful'
    GROUP BY s.customer_id
)
SELECT
    c.customer_id,
    c.customer_name,
    cr.total_revenue
FROM customer_revenue cr
JOIN sa.customers c
    ON cr.customer_id = c.customer_id
WHERE cr.total_revenue > (
    SELECT AVG(total_revenue)
    FROM customer_revenue
)
ORDER BY cr.total_revenue DESC;


--Q2 — Successful vs. Unsuccessful Payments by Payment Method

SELECT
    payment_method,
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(payment_status)) = 'successful'
    ) AS successful_payments,
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(payment_status)) <> 'successful'
    ) AS unsuccessful_payments,
    SUM(amount) FILTER (
        WHERE LOWER(TRIM(payment_status)) = 'successful'
    ) AS successful_revenue
FROM sa.payments
GROUP BY payment_method
ORDER BY successful_revenue DESC;


--Q3 — Monthly Revenue and Month-over-Month (MoM) Growth

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date)::DATE AS revenue_month,
        SUM(amount) AS revenue
    FROM sa.payments
    WHERE LOWER(TRIM(payment_status)) = 'successful'
    GROUP BY DATE_TRUNC('month', payment_date)
),
revenue_with_previous AS (
    SELECT
        revenue_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY revenue_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    revenue_month,
    revenue,
    previous_month_revenue,
    ROUND(
        (revenue - previous_month_revenue) * 100.0
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM revenue_with_previous
ORDER BY revenue_month;


--Q4 — Revenue by Acquisition Channel
--Business question: How much successful payment revenue is generated by customers from each acquisition channel?


SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT CASE
        WHEN p.payment_id IS NOT NULL THEN c.customer_id
    END) AS paying_customers,
    COALESCE(SUM(p.amount), 0) AS total_revenue,
    ROUND(
        COALESCE(SUM(p.amount), 0) /
        NULLIF(COUNT(DISTINCT CASE
            WHEN p.payment_id IS NOT NULL THEN c.customer_id
        END), 0),
        2
    ) AS revenue_per_paying_customer
FROM sa.customers c
LEFT JOIN sa.subscriptions s
    ON c.customer_id = s.customer_id
LEFT JOIN sa.payments p
    ON s.subscription_id = p.subscription_id
    AND LOWER(TRIM(p.payment_status)) = 'successful'
GROUP BY c.acquisition_channel
ORDER BY total_revenue DESC;


--Q5 — Paying Customer Rate by Acquisition Channel

SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT CASE
        WHEN p.payment_id IS NOT NULL THEN c.customer_id
    END) AS paying_customers,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN p.payment_id IS NOT NULL THEN c.customer_id
        END) * 100.0 /
        COUNT(DISTINCT c.customer_id),
        2
    ) AS paying_customer_rate_pct
FROM sa.customers c
LEFT JOIN sa.subscriptions s
    ON c.customer_id = s.customer_id
LEFT JOIN sa.payments p
    ON s.subscription_id = p.subscription_id
    AND LOWER(TRIM(p.payment_status)) = 'successful'
GROUP BY c.acquisition_channel
ORDER BY paying_customer_rate_pct DESC;


--Q6 — Average Subscription Price by Plan

SELECT
    plan_name,
    billing_cycle,
    monthly_price
FROM sa.plans
ORDER BY monthly_price DESC;


--Q7 — Customers with Multiple Subscriptions


SELECT
    c.customer_id,
    c.customer_name,
    COUNT(s.subscription_id) AS total_subscriptions
FROM sa.customers c
JOIN sa.subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING COUNT(s.subscription_id) > 1
ORDER BY total_subscriptions DESC;


--Q8 — Subscription Count by Plan and Status

SELECT
    p.plan_name,
    s.status,
    COUNT(*) AS total_subscriptions
FROM sa.subscriptions s
JOIN sa.plans p
    ON s.plan_id = p.plan_id
GROUP BY
    p.plan_name,
    s.status
ORDER BY
    p.plan_name,
    total_subscriptions DESC;

--Q9 — Average Usage Duration by Event Type

SELECT
    event_type,
    COUNT(*) AS total_events,
    ROUND(AVG(duration_minutes), 2) AS avg_duration_minutes,
    SUM(duration_minutes) AS total_duration_minutes
FROM sa.usage_events
GROUP BY event_type
ORDER BY avg_duration_minutes DESC;


--Q10: Successful Revenue by Country

SELECT
    c.country,
    SUM(p.amount) AS total_revenue
FROM sa.customers c
JOIN sa.subscriptions s
    ON c.customer_id = s.customer_id
JOIN sa.payments p
    ON s.subscription_id = p.subscription_id
WHERE LOWER(TRIM(p.payment_status)) = 'successful'
GROUP BY c.country
ORDER BY total_revenue DESC;


--Q11: Average Revenue per Paying Customer by Country

SELECT
    c.country,
    COUNT(DISTINCT c.customer_id) AS paying_customers,
    SUM(p.amount) AS total_revenue,
    ROUND(
        SUM(p.amount) / COUNT(DISTINCT c.customer_id),
        2
    ) AS revenue_per_paying_customer
FROM sa.customers c
JOIN sa.subscriptions s
    ON c.customer_id = s.customer_id
JOIN sa.payments p
    ON s.subscription_id = p.subscription_id
WHERE LOWER(TRIM(p.payment_status)) = 'successful'
GROUP BY c.country
ORDER BY revenue_per_paying_customer DESC;


--Q12: Subscription Status by Acquisition Channel

SELECT
    c.acquisition_channel,
    s.status,
    COUNT(*) AS total_subscriptions
FROM sa.customers c
JOIN sa.subscriptions s
    ON c.customer_id = s.customer_id
GROUP BY
    c.acquisition_channel,
    s.status
ORDER BY
    c.acquisition_channel,
    total_subscriptions DESC;

--Q13: Successful Revenue by Subscription Status

SELECT
    s.status,
    SUM(p.amount) AS total_revenue,
    COUNT(DISTINCT s.subscription_id) AS subscriptions_with_successful_payments
FROM sa.subscriptions s
JOIN sa.payments p
    ON s.subscription_id = p.subscription_id
WHERE LOWER(TRIM(p.payment_status)) = 'successful'
GROUP BY s.status
ORDER BY total_revenue DESC;

============================================================================================================================================================
============================================================================================================================================================


--Stage 3 — Advanced SQL Analysis


--Q1 — Rank Customers by Total Revenue

WITH customer_revenue AS (
    SELECT
        s.customer_id,
        SUM(p.amount) AS total_revenue
    FROM sa.subscriptions s
    JOIN sa.payments p
        ON s.subscription_id = p.subscription_id
    WHERE LOWER(TRIM(p.payment_status)) = 'successful'
    GROUP BY s.customer_id
)
SELECT
    c.customer_id,
    c.customer_name,
    cr.total_revenue,
    RANK() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
FROM customer_revenue cr
JOIN sa.customers c
    ON cr.customer_id = c.customer_id
ORDER BY revenue_rank;


--Q2: Top 3 Revenue-Generating Customers in Each Country

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.country,
        SUM(p.amount) AS total_revenue
    FROM sa.customers c
    JOIN sa.subscriptions s
        ON c.customer_id = s.customer_id
    JOIN sa.payments p
        ON s.subscription_id = p.subscription_id
    WHERE LOWER(TRIM(p.payment_status)) = 'successful'
    GROUP BY
        c.customer_id,
        c.customer_name,
        c.country
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_name,
        country,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM customer_revenue
)
SELECT
    country,
    customer_id,
    customer_name,
    total_revenue,
    revenue_rank
FROM ranked_customers
WHERE revenue_rank <= 3
ORDER BY country, revenue_rank;

--Q3: Cumulative Monthly Revenue

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date)::DATE AS revenue_month,
        SUM(amount) AS monthly_revenue
    FROM sa.payments
    WHERE LOWER(TRIM(payment_status)) = 'successful'
    GROUP BY DATE_TRUNC('month', payment_date)
)
SELECT
    revenue_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY revenue_month
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY revenue_month;



--Q4: Segment Customers into Revenue Quartiles

WITH customer_revenue AS (
    SELECT
        s.customer_id,
        SUM(p.amount) AS total_revenue
    FROM sa.subscriptions s
    JOIN sa.payments p
        ON s.subscription_id = p.subscription_id
    WHERE LOWER(TRIM(p.payment_status)) = 'successful'
    GROUP BY s.customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        total_revenue,
        NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile
    FROM customer_revenue
)
SELECT
    revenue_quartile,
    COUNT(*) AS total_customers,
    ROUND(AVG(total_revenue), 2) AS avg_revenue,
    SUM(total_revenue) AS total_revenue
FROM customer_segments
GROUP BY revenue_quartile
ORDER BY revenue_quartile;


--Q5: Three-Month Moving Average of Revenue


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date)::DATE AS revenue_month,
        SUM(amount) AS monthly_revenue
    FROM sa.payments
    WHERE LOWER(TRIM(payment_status)) = 'successful'
    GROUP BY DATE_TRUNC('month', payment_date)
)
SELECT
    revenue_month,
    monthly_revenue,
    CASE
        WHEN ROW_NUMBER() OVER (ORDER BY revenue_month) >= 3
        THEN ROUND(
            AVG(monthly_revenue) OVER (
                ORDER BY revenue_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        )
        ELSE NULL
    END AS moving_avg_3_month
FROM monthly_revenue
ORDER BY revenue_month;




--Q6: Monthly Revenue Contribution to Total Revenue

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date)::DATE AS revenue_month,
        SUM(amount) AS monthly_revenue
    FROM sa.payments
    WHERE LOWER(TRIM(payment_status)) = 'successful'
    GROUP BY DATE_TRUNC('month', payment_date)
)
SELECT
    revenue_month,
    monthly_revenue,
    ROUND(
        monthly_revenue * 100.0 /
        SUM(monthly_revenue) OVER (),
        2
    ) AS revenue_contribution_pct
FROM monthly_revenue
ORDER BY revenue_month;

--Q7: Year-over-Year (YoY) Revenue Growth

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', payment_date)::DATE AS revenue_month,
        SUM(amount) AS monthly_revenue
    FROM sa.payments
    WHERE LOWER(TRIM(payment_status)) = 'successful'
    GROUP BY DATE_TRUNC('month', payment_date)
),
revenue_comparison AS (
    SELECT
        revenue_month,
        monthly_revenue,
        LAG(monthly_revenue, 12) OVER (
            ORDER BY revenue_month
        ) AS previous_year_revenue
    FROM monthly_revenue
)
SELECT
    revenue_month,
    monthly_revenue,
    previous_year_revenue,
    ROUND(
        (monthly_revenue - previous_year_revenue) * 100.0
        / NULLIF(previous_year_revenue, 0),
        2
    ) AS yoy_growth_pct
FROM revenue_comparison
ORDER BY revenue_month;




--Q08 — Classify Customers by Payment Activity Span
SELECT
    s.customer_id,
    MIN(p.payment_date) AS first_payment_date,
    MAX(p.payment_date) AS latest_payment_date,
    MAX(p.payment_date) - MIN(p.payment_date) AS payment_span_days,
    CASE
        WHEN MAX(p.payment_date) - MIN(p.payment_date) < 90
            THEN 'Under 3 Months'
        WHEN MAX(p.payment_date) - MIN(p.payment_date) < 365
            THEN '3 to 12 Months'
        ELSE 'Over 12 Months'
    END AS payment_activity_span
FROM sa.subscriptions s
JOIN sa.payments p
    ON s.subscription_id = p.subscription_id
WHERE LOWER(TRIM(p.payment_status)) = 'successful'
GROUP BY s.customer_id
ORDER BY payment_span_days DESC;




--Q9: Identify Customers with Gaps of More Than 90 Days Between Payments

WITH payment_dates AS (
    SELECT DISTINCT
        s.customer_id,
        p.payment_date
    FROM sa.subscriptions s
    JOIN sa.payments p
        ON s.subscription_id = p.subscription_id
    WHERE LOWER(TRIM(p.payment_status)) = 'successful'
),
payment_gaps AS (
    SELECT
        customer_id,
        payment_date,
        LAG(payment_date) OVER (
            PARTITION BY customer_id
            ORDER BY payment_date
        ) AS previous_payment_date
    FROM payment_dates
)
SELECT
    customer_id,
    previous_payment_date,
    payment_date,
    payment_date - previous_payment_date AS gap_days
FROM payment_gaps
WHERE payment_date - previous_payment_date > 90
ORDER BY gap_days DESC;



--Q10: Analyze Payment Gaps by Billing Cycle


WITH payment_gaps AS (
    SELECT
        p.subscription_id,
        pl.billing_cycle,
        p.payment_date
            - LAG(p.payment_date) OVER (
                PARTITION BY p.subscription_id
                ORDER BY p.payment_date
            ) AS gap_days
    FROM sa.payments p
    JOIN sa.subscriptions s
        ON p.subscription_id = s.subscription_id
    JOIN sa.plans pl
        ON s.plan_id = pl.plan_id
    WHERE LOWER(TRIM(p.payment_status)) = 'successful'
)
SELECT
    billing_cycle,
    COUNT(gap_days) AS payment_intervals,
    ROUND(AVG(gap_days), 2) AS avg_gap_days,
    MAX(gap_days) AS longest_gap_days,
    COUNT(*) FILTER (WHERE gap_days > 90) AS gaps_over_90_days
FROM payment_gaps
WHERE gap_days IS NOT NULL
GROUP BY billing_cycle
ORDER BY billing_cycle



----Q11:Cohort Analysis — Monthly Product Usage Retention

WITH customer_cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date)::DATE AS cohort_month
    FROM sa.customers
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', event_date)::DATE AS activity_month
    FROM sa.usage_events
)
SELECT
    c.cohort_month,
    (
        (EXTRACT(YEAR FROM a.activity_month) -
         EXTRACT(YEAR FROM c.cohort_month)) * 12
        + EXTRACT(MONTH FROM a.activity_month) -
          EXTRACT(MONTH FROM c.cohort_month)
    )::INT AS months_since_signup,
    cs.cohort_size,
    COUNT(DISTINCT a.customer_id) AS active_customers,
    ROUND(
        COUNT(DISTINCT a.customer_id) * 100.0 /
        NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_rate
FROM customer_cohorts c
JOIN cohort_sizes cs
    ON c.cohort_month = cs.cohort_month
JOIN monthly_activity a
    ON c.customer_id = a.customer_id
   AND a.activity_month >= c.cohort_month
WHERE
    (
        (EXTRACT(YEAR FROM a.activity_month) -
         EXTRACT(YEAR FROM c.cohort_month)) * 12
        + EXTRACT(MONTH FROM a.activity_month) -
          EXTRACT(MONTH FROM c.cohort_month)
    ) BETWEEN 0 AND 12
GROUP BY
    c.cohort_month,
    a.activity_month,
    cs.cohort_size
ORDER BY
    c.cohort_month,
    months_since_signup;

============================================================================================================================================================
============================================================================================================================================================

--Stage 4 — KPI Reporting & Performance

--1: Overall Business KPI Snapshot

SELECT
    (SELECT COUNT(*)
     FROM sa.customers) AS total_customers,

    (SELECT COUNT(DISTINCT customer_id)
     FROM sa.subscriptions
     WHERE status = 'active') AS active_customers,

    (SELECT COUNT(*)
     FROM sa.subscriptions
     WHERE status = 'active') AS active_subscriptions,

    (SELECT ROUND(SUM(amount), 2)
     FROM sa.payments
     WHERE payment_status = 'successful') AS total_successful_revenue,

    (SELECT COUNT(DISTINCT s.customer_id)
     FROM sa.subscriptions s
     JOIN sa.payments p
         ON s.subscription_id = p.subscription_id
     WHERE p.payment_status = 'successful') AS customers_with_successful_payments,

    (SELECT ROUND(
        COUNT(*) FILTER (WHERE payment_status = 'successful') * 100.0
        / NULLIF(COUNT(*), 0),
        2
     )
     FROM sa.payments) AS payment_success_rate;


--Monthly KPI Reporting

--2: Monthly Revenue & Payment Performance

SELECT
    DATE_TRUNC('month', payment_date)::DATE AS month,
    ROUND(
        SUM(amount) FILTER (
            WHERE payment_status = 'successful'
        ), 2
    ) AS monthly_revenue,
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (
        WHERE payment_status = 'successful'
    ) AS successful_payments,
    ROUND(
        COUNT(*) FILTER (
            WHERE payment_status = 'successful'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS payment_success_rate
FROM sa.payments
GROUP BY DATE_TRUNC('month', payment_date)
ORDER BY month;


--3 — Create a KPI View

CREATE OR REPLACE VIEW sa.vw_overall_business_kpis AS
SELECT
    (SELECT COUNT(*)
     FROM sa.customers) AS total_customers,

    (SELECT COUNT(DISTINCT customer_id)
     FROM sa.subscriptions
     WHERE status = 'active') AS active_customers,

    (SELECT COUNT(*)
     FROM sa.subscriptions
     WHERE status = 'active') AS active_subscriptions,

    (SELECT ROUND(SUM(amount), 2)
     FROM sa.payments
     WHERE payment_status = 'successful') AS total_successful_revenue,

    (SELECT COUNT(DISTINCT s.customer_id)
     FROM sa.subscriptions s
     JOIN sa.payments p
         ON s.subscription_id = p.subscription_id
     WHERE p.payment_status = 'successful')
         AS customers_with_successful_payments,

    (SELECT ROUND(
        COUNT(*) FILTER (
            WHERE payment_status = 'successful'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
     )
     FROM sa.payments) AS payment_success_rate;


---run the view

SELECT *
FROM sa.vw_overall_business_kpis;

---4: Create a Monthly Revenue View

CREATE OR REPLACE VIEW sa.vw_monthly_revenue_performance AS
SELECT
    DATE_TRUNC('month', payment_date)::DATE AS month,
    ROUND(
        SUM(amount) FILTER (
            WHERE payment_status = 'successful'
        ), 2
    ) AS monthly_revenue,
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (
        WHERE payment_status = 'successful'
    ) AS successful_payments,
    ROUND(
        COUNT(*) FILTER (
            WHERE payment_status = 'successful'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS payment_success_rate
FROM sa.payments
GROUP BY DATE_TRUNC('month', payment_date);


--run the view

SELECT *
FROM sa.vw_monthly_revenue_performance
ORDER BY month;


--5: EXPLAIN ANALYZE

EXPLAIN ANALYZE
SELECT *
FROM sa.vw_monthly_revenue_performance
ORDER BY month;






























