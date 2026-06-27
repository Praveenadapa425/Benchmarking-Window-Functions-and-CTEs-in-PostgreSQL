SELECT
    order_id,
    user_id,
    amount,
    (amount / SUM(amount) OVER (PARTITION BY user_id)) * 100 as lifetime_share_pct
FROM orders
ORDER BY user_id, order_id;
