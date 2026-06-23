# RFM Segmentation Project for E-commerce

## Project goal
This project solves a business question: **what customer segments exist in an e-commerce business, and how should the company work with each of them?**

The project uses synthetic transactional data and RFM analysis:
- **Recency** — how long ago the customer made the last purchase.
- **Frequency** — how many orders the customer placed.
- **Monetary** — how much money the customer brought.

Then customers are grouped into segments such as `VIP`, `Loyal`, `New`, `At Risk`, `Dormant`, and `Other`.

## Repository structure

- `data/orders_dataset.csv` — generated raw transactional dataset.
- `sql/segmentation.sql` — SQL script for data checks and RFM calculation.
- `notebooks/analysis.ipynb` — notebook for segmentation and analysis.
- `results/rfm_table.csv` — final user-level RFM table.
- `results/segment_summary.csv` — final segment summary.

## Dataset
Synthetic e-commerce data was generated for **500 users** over about **1 year** up to **2026-06-01**.

Fields:
- `user_id`
- `order_id`
- `order_date`
- `amount`

## Methodology

### 1. Data preparation
Checks:
- NULL values
- valid dates
- numeric positive amounts
- duplicate orders

### 2. RFM calculation
For each user:
- `recency` = days since last purchase up to `2026-06-01`
- `frequency` = number of unique orders
- `monetary` = total revenue from the user

### 3. Quantile scoring
Each metric is split into quartiles:
- `r_score` from 1 to 4
- `f_score` from 1 to 4
- `m_score` from 1 to 4

Then a combined `rfm_score` is built.

### 4. Segment rules
Used rules:
- `VIP` — strongest RFM profile
- `Loyal` — recent and frequent buyers
- `New` — very recent but still low frequency
- `At Risk` — previously active, but less recent
- `Dormant` — old and low-activity users
- `Other` — users not covered by the main rules

### 5. Churn risk
`churn_risk = 1`, if the customer has not purchased for more than **90 days**.

## Main business metrics
For each segment the project calculates:
- number of users
- total revenue
- revenue share
- churn risk share

## Example interview pitch
> I built a customer segmentation project for e-commerce using RFM analysis. I generated synthetic transaction data, calculated recency, frequency and monetary metrics, created customer segments, analyzed each segment’s contribution to revenue, and identified users with high churn risk. Based on that, I proposed retention and reactivation strategies.

## How to use
1. Open `data/orders_dataset.csv`.
2. Run `sql/segmentation.sql` in PostgreSQL or adapt it to another DBMS.
3. Open `notebooks/analysis.ipynb` and run all cells.
4. Review `results/rfm_table.csv` and `results/segment_summary.csv`.
