WITH unioned_orders AS (
    (
        SELECT DISTINCT ON (user_id) user_id, created_at, amount, 'first'::text as type
        FROM orders
        ORDER BY user_id, created_at ASC, order_id ASC
    )
    UNION ALL
    (
        SELECT DISTINCT ON (user_id) user_id, created_at, amount, 'last'::text as type
        FROM orders
        ORDER BY user_id, created_at DESC, order_id DESC
    )
)
SELECT
    u.user_id,
    MAX(CASE WHEN uo.type = 'first' THEN uo.created_at END) as first_order_date,
    MAX(CASE WHEN uo.type = 'last' THEN uo.created_at END) as last_order_date,
    MAX(CASE WHEN uo.type = 'first' THEN uo.amount END) as first_order_amount,
    MAX(CASE WHEN uo.type = 'last' THEN uo.amount END) as last_order_amount
FROM users u
LEFT JOIN unioned_orders uo ON u.user_id = uo.user_id
GROUP BY u.user_id
ORDER BY u.user_id;
