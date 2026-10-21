-- =========================================================
-- EDA 10: DELIVERY DELAY SEVERITY VS REVIEW SCORES
-- =========================================================

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM
        `funnel-analysis-sql.o_list_eda.reviews`
    GROUP BY
        order_id
),

delivery_analysis AS (
    SELECT
        o.order_id,
        r.avg_review_score,

        DATE_DIFF(
            DATE(o.order_delivered_customer_date),
            o.order_estimated_delivery_date,
            DAY
        ) AS delay_days

    FROM
        `funnel-analysis-sql.o_list_eda.orders` AS o

    JOIN
        review_by_order AS r
        ON o.order_id = r.order_id

    WHERE
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
),

delay_groups AS (
    SELECT
        *,

        CASE
            WHEN delay_days <= -7 THEN '1. 7+ days early'
            WHEN delay_days BETWEEN -6 AND -1
                THEN '2. 1–6 days early'
            WHEN delay_days = 0
                THEN '3. On estimated date'
            WHEN delay_days BETWEEN 1 AND 3
                THEN '4. 1–3 days late'
            WHEN delay_days BETWEEN 4 AND 7
                THEN '5. 4–7 days late'
            ELSE '6. 8+ days late'
        END AS delay_group

    FROM
        delivery_analysis
)

SELECT
    delay_group,

    COUNT(*) AS orders_with_reviews,

    ROUND(AVG(avg_review_score), 2)
        AS avg_review_score,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(avg_review_score <= 2),
            COUNT(*)
        ),
        2
    ) AS low_review_share_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNTIF(avg_review_score >= 4),
            COUNT(*)
        ),
        2
    ) AS high_review_share_pct

FROM
    delay_groups

GROUP BY
    delay_group

ORDER BY
    delay_group;