WITH last_30d AS (
    SELECT u.user_id, COUNT(o.order_id)::int as orders_last_30d
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
        AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
        AND o.created_at < CURRENT_DATE
    GROUP BY u.user_id
),
prev_30d AS (
    SELECT u.user_id, COUNT(o.order_id)::int as orders_prev_30d
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
        AND o.created_at >= CURRENT_DATE - INTERVAL '60 days'
        AND o.created_at < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY u.user_id
)
SELECT
    l.user_id,
    l.orders_last_30d,
    p.orders_prev_30d
FROM last_30d l
JOIN prev_30d p ON l.user_id = p.user_id
WHERE l.orders_last_30d < p.orders_prev_30d
ORDER BY l.user_id;
