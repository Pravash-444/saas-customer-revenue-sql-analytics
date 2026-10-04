# Selected Analysis Results

This folder contains three selected CSV outputs from the SaaS Customer & Revenue Analytics project.

## `monthly_revenue.csv`

Monthly successful payment revenue, payment volume, successful payment count, and payment success rate.

## `monthly_churn.csv`

Monthly customer churn results. The churn rate uses customers active at the start of the month as its denominator. The churn count includes cancelled customers whose subscription ends during that month and who do not have another subscription active into the following month. Expired subscriptions are excluded from the cancellation numerator.

## `monthly_retention.csv`

Monthly customer retention rate, calculated as the share of customers active at the start of the month who remain after accounting for churn during that month.

---

These files are exported query results for convenient review. Refer to the root [README.md](../README.md) for the business questions and calculation definitions, and to [queries.sql](../queries.sql) for the SQL analysis.
