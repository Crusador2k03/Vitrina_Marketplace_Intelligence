-- =========================================================
-- EDA 06: SELLER REVENUE CONCENTRATION
-- =========================================================

WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM
        `funnel-analysis-sql.o_list_eda.order_items` AS oi
    JOIN
        `funnel-analysis-sql.o_list_eda.orders` AS o
        ON oi.order_id = o.order_id
    WHERE
        o.order_status = 'delivered'
    GROUP BY
        oi.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        total_revenue,

        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC, seller_id
        ) AS seller_rank,

        SUM(total_revenue) OVER () AS overall_revenue,

        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC, seller_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_revenue

    FROM seller_revenue
)

SELECT
    COUNT(*) AS sellers_with_delivered_sales,

    ROUND(
        100 * SAFE_DIVIDE(
            SUM(IF(seller_rank = 1, total_revenue, 0)),
            MAX(overall_revenue)
        ),
        2
    ) AS top_1_seller_share_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            SUM(IF(seller_rank <= 10, total_revenue, 0)),
            MAX(overall_revenue)
        ),
        2
    ) AS top_10_sellers_share_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            SUM(IF(seller_rank <= 20, total_revenue, 0)),
            MAX(overall_revenue)
        ),
        2
    ) AS top_20_sellers_share_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            SUM(IF(seller_rank <= 50, total_revenue, 0)),
            MAX(overall_revenue)
        ),
        2
    ) AS top_50_sellers_share_pct,

    MIN(
        IF(
            cumulative_revenue >= overall_revenue * 0.80,
            seller_rank,
            NULL
        )
    ) AS sellers_needed_for_80pct_revenue

FROM ranked_sellers;