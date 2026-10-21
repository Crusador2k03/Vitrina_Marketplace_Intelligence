-- =========================================================
-- EDA 09: DELIVERY PERFORMANCE VS CUSTOMER SATISFACTION
-- =========================================================

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score,
        COUNT(*) AS review_count
    FROM
        `funnel-analysis-sql.o_list_eda.reviews`
    GROUP BY
        order_id
),

order_experience AS (
    SELECT
        o.order_id,
        o.delivery_performance,
        r.avg_review_score
    FROM
        `funnel-analysis-sql.o_list_eda.orders` AS o
    JOIN
        review_by_order AS r
        ON o.order_id = r.order_id
    WHERE
        o.order_status = 'delivered'
        AND o.delivery_performance IN ('Early', 'On Time', 'Late')
)

SELECT
    delivery_performance,

    COUNT(*) AS delivered_orders_with_reviews,

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
    order_experience

GROUP BY
    delivery_performance

ORDER BY
    CASE delivery_performance
        WHEN 'Early' THEN 1
        WHEN 'On Time' THEN 2
        WHEN 'Late' THEN 3
    END;