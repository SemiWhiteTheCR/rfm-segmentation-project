-- RFM segmentation project
-- SQL part: data quality checks and core RFM calculation
-- Target DBMS: PostgreSQL

-- Example table definition:
-- CREATE TABLE orders (
--   user_id INT,
--   order_id VARCHAR(64),
--   order_date DATE,
--   amount NUMERIC(12,2)
-- );

-- Data quality checks
SELECT COUNT(*) AS null_user_id
FROM orders
WHERE user_id IS NULL;

SELECT COUNT(*) AS null_order_id
FROM orders
WHERE order_id IS NULL;

SELECT COUNT(*) AS null_order_date
FROM orders
WHERE order_date IS NULL;

SELECT COUNT(*) AS null_amount
FROM orders
WHERE amount IS NULL;

SELECT MIN(order_date) AS min_order_date,
       MAX(order_date) AS max_order_date
FROM orders;

SELECT COUNT(*) AS non_positive_amounts
FROM orders
WHERE amount <= 0;

SELECT order_id, COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Core RFM calculation
WITH rfm_raw AS (
    SELECT
        user_id,
        DATE '2026-06-01' AS ref_date,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(amount) AS monetary
    FROM orders
    GROUP BY user_id
),
rfm AS (
    SELECT
        user_id,
        (ref_date - last_order_date) AS recency,
        frequency,
        monetary
    FROM rfm_raw
)
SELECT *
FROM rfm
ORDER BY user_id;
