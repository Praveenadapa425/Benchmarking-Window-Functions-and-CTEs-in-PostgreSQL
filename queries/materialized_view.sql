CREATE MATERIALIZED VIEW daily_revenue_stats AS
WITH daily_rev AS (
    SELECT created_at::date as day, SUM(amount) as daily_revenue
    FROM orders
    WHERE created_at >= CURRENT_DATE - INTERVAL '96 days'
    GROUP BY 1
),
rolling AS (
    SELECT
        day,
        daily_revenue,
        AVG(daily_revenue) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_7d_avg
    FROM daily_rev
)
SELECT day, daily_revenue, rolling_7d_avg
FROM rolling
WHERE day >= CURRENT_DATE - INTERVAL '90 days';
