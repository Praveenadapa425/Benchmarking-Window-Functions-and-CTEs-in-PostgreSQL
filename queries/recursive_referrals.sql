WITH RECURSIVE top_users AS (
    SELECT user_id
    FROM orders
    GROUP BY user_id
    ORDER BY COUNT(*) DESC, user_id ASC
    LIMIT 100
),
referral_tree AS (
    SELECT
        user_id as start_user_id,
        user_id,
        1 as depth
    FROM top_users

    UNION ALL

    SELECT
        rt.start_user_id,
        u.user_id,
        rt.depth + 1
    FROM referral_tree rt
    JOIN users u ON u.referred_by = rt.user_id
)
SELECT
    start_user_id as user_id,
    MAX(depth) as chain_depth
FROM referral_tree
GROUP BY start_user_id
ORDER BY chain_depth DESC, start_user_id ASC;
