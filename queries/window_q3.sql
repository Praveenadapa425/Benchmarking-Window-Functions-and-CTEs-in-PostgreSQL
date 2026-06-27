WITH distinct_orders AS (
    SELECT DISTINCT
        user_id,
        FIRST_VALUE(created_at) OVER (PARTITION BY user_id ORDER BY created_at ASC, order_id ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as first_order_date,
        FIRST_VALUE(created_at) OVER (PARTITION BY user_id ORDER BY created_at DESC, order_id DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_order_date,
        FIRST_VALUE(amount) OVER (PARTITION BY user_id ORDER BY created_at ASC, order_id ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as first_order_amount,
        FIRST_VALUE(amount) OVER (PARTITION BY user_id ORDER BY created_at DESC, order_id DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_order_amount
    FROM orders
)
SELECT
    u.user_id,
    d_ord.first_order_date,
    d_ord.last_order_date,
    d_ord.first_order_amount,
    d_ord.last_order_amount
FROM users u
LEFT JOIN distinct_orders d_ord ON u.user_id = d_ord.user_id
ORDER BY u.user_id;
