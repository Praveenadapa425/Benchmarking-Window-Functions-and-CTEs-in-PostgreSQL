WITH user_spend AS (
    SELECT
        u.cohort_month,
        u.user_id,
        COALESCE(SUM(o.amount), 0) as total_spend
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.cohort_month, u.user_id
),
ranked_spend AS (
    SELECT
        cohort_month,
        user_id,
        total_spend,
        ROW_NUMBER() OVER (PARTITION BY cohort_month ORDER BY total_spend DESC, user_id ASC) as rank_in_cohort
    FROM user_spend
)
SELECT cohort_month, user_id, total_spend, rank_in_cohort
FROM ranked_spend
WHERE rank_in_cohort <= 10
ORDER BY cohort_month, rank_in_cohort;
