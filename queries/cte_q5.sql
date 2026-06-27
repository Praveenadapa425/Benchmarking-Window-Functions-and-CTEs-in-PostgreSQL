WITH user_totals AS (
    SELECT user_id, SUM(amount) as total_spend
    FROM orders
    GROUP BY user_id
)
SELECT
    o.order_id,
    o.user_id,
    o.amount,
    (o.amount / ut.total_spend) * 100 as lifetime_share_pct
FROM orders o
JOIN user_totals ut ON o.user_id = ut.user_id
ORDER BY o.user_id, o.order_id;
