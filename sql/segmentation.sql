-- Проверка качества данных
SELECT *
FROM orders
WHERE user_id IS NULL
   OR order_id IS NULL
   OR order_date IS NULL
   OR amount IS NULL;

SELECT order_id, COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT *
FROM orders
WHERE amount <= 0;

SELECT MIN(order_date) AS min_date,
       MAX(order_date) AS max_date
FROM orders;

-- RFM-таблица по пользователям
WITH snapshot AS (
    SELECT MAX(order_date) + INTERVAL '1 day' AS snapshot_date
    FROM orders
),
rfm_base AS (
    SELECT
        o.user_id,
        (SELECT snapshot_date FROM snapshot) - MAX(o.order_date) AS recency_interval,
        COUNT(o.order_id) AS frequency,
        SUM(o.amount) AS monetary
    FROM orders o
    GROUP BY o.user_id
),
rfm_clean AS (
    SELECT
        user_id,
        EXTRACT(DAY FROM recency_interval) AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    SELECT
        user_id,
        recency,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_clean
),
rfm_segments AS (
    SELECT
        user_id,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
            WHEN r_score >= 3 AND f_score >= 4 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising'
            WHEN r_score BETWEEN 2 AND 3 AND f_score BETWEEN 2 AND 3 THEN 'Low Activity'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
            ELSE 'Regular'
        END AS segment,
        CASE
            WHEN recency > 90 THEN 1
            ELSE 0
        END AS churn_risk
    FROM rfm_scores
)
SELECT *
FROM rfm_segments
ORDER BY monetary DESC;

-- Сводка по сегментам
WITH snapshot AS (
    SELECT MAX(order_date) + INTERVAL '1 day' AS snapshot_date
    FROM orders
),
rfm_base AS (
    SELECT
        o.user_id,
        (SELECT snapshot_date FROM snapshot) - MAX(o.order_date) AS recency_interval,
        COUNT(o.order_id) AS frequency,
        SUM(o.amount) AS monetary
    FROM orders o
    GROUP BY o.user_id
),
rfm_clean AS (
    SELECT
        user_id,
        EXTRACT(DAY FROM recency_interval) AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    SELECT
        user_id,
        recency,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_clean
),
rfm_segments AS (
    SELECT
        user_id,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
            WHEN r_score >= 3 AND f_score >= 4 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising'
            WHEN r_score BETWEEN 2 AND 3 AND f_score BETWEEN 2 AND 3 THEN 'Low Activity'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
            ELSE 'Regular'
        END AS segment,
        CASE
            WHEN recency > 90 THEN 1
            ELSE 0
        END AS churn_risk
    FROM rfm_scores
),
totals AS (
    SELECT SUM(monetary) AS total_revenue,
           COUNT(*) AS total_users
    FROM rfm_segments
)
SELECT
    s.segment,
    COUNT(*) AS users_count,
    ROUND(100.0 * COUNT(*) / (SELECT total_users FROM totals), 2) AS users_share_pct,
    ROUND(SUM(s.monetary), 2) AS revenue,
    ROUND(100.0 * SUM(s.monetary) / (SELECT total_revenue FROM totals), 2) AS revenue_share_pct,
    ROUND(AVG(s.monetary), 2) AS avg_revenue_per_user,
    ROUND(AVG(s.frequency), 2) AS avg_orders_per_user,
    SUM(s.churn_risk) AS churn_risk_users
FROM rfm_segments s
GROUP BY s.segment
ORDER BY revenue DESC;
