WITH daily_rev AS (
    SELECT created_at::date as day, SUM(amount) as daily_revenue
    FROM orders
    WHERE created_at >= CURRENT_DATE - INTERVAL '96 days'
    GROUP BY 1
)
SELECT
    d1.day,
    d1.daily_revenue,
    AVG(d2.daily_revenue) as rolling_7d_avg
FROM daily_rev d1
JOIN daily_rev d2 ON d2.day BETWEEN d1.day - 6 AND d1.day
WHERE d1.day >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY d1.day, d1.daily_revenue
ORDER BY d1.day;
