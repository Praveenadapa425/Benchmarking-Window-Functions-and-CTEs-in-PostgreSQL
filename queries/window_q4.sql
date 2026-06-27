WITH user_periods AS (
    SELECT u.user_id, p.period
    FROM users u
    CROSS JOIN (VALUES (1), (2)) p(period)
),
period_counts AS (
    SELECT
        up.user_id,
        up.period,
        COUNT(o.order_id)::int as order_count
    FROM user_periods up
    LEFT JOIN orders o ON up.user_id = o.user_id AND (
        (up.period = 1 AND o.created_at >= CURRENT_DATE - INTERVAL '60 days' AND o.created_at < CURRENT_DATE - INTERVAL '30 days') OR
        (up.period = 2 AND o.created_at >= CURRENT_DATE - INTERVAL '30 days' AND o.created_at < CURRENT_DATE)
    )
    GROUP BY up.user_id, up.period
),
lagged AS (
    SELECT
        user_id,
        period,
        order_count,
        LAG(order_count) OVER (PARTITION BY user_id ORDER BY period) as prev_count
    FROM period_counts
)
SELECT
    user_id,
    order_count as orders_last_30d,
    prev_count as orders_prev_30d
FROM lagged
WHERE period = 2 AND order_count < prev_count
ORDER BY user_id;
