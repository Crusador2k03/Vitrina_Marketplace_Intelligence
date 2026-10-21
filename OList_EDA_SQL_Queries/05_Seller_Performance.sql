-- =========================================================
-- EDA 05: SELLER PERFORMANCE
-- =========================================================

WITH seller_metrics AS (
    SELECT
        oi.seller_id,

        COUNT(*) AS items_sold,

        COUNT(DISTINCT oi.order_id) AS delivered_orders,

        COUNT(DISTINCT oi.product_id) AS distinct_products,

        SUM(oi.price) AS item_revenue,

        SUM(oi.freight_value) AS freight_revenue,

        SUM(oi.price + oi.freight_value) AS total_revenue,

        AVG(oi.price) AS avg_item_price

    FROM
        `funnel-analysis-sql.o_list_eda.order_items` AS oi

    JOIN
        `funnel-analysis-sql.o_list_eda.orders` AS o
        ON oi.order_id = o.order_id

    WHERE
        o.order_status = 'delivered'

    GROUP BY
        oi.seller_id
)

SELECT
    sm.seller_id,
    s.seller_state,
    s.seller_city,

    sm.items_sold,
    sm.delivered_orders,
    sm.distinct_products,

    ROUND(sm.item_revenue, 2) AS item_revenue,
    ROUND(sm.freight_revenue, 2) AS freight_revenue,
    ROUND(sm.total_revenue, 2) AS total_revenue,

    ROUND(sm.avg_item_price, 2) AS avg_item_price,

    ROUND(
        SAFE_DIVIDE(
            sm.total_revenue,
            sm.delivered_orders
        ),
        2
    ) AS revenue_per_delivered_order,

    ROUND(
        100 * SAFE_DIVIDE(
            sm.total_revenue,
            SUM(sm.total_revenue) OVER ()
        ),
        2
    ) AS revenue_share_pct

FROM
    seller_metrics AS sm

LEFT JOIN
    `funnel-analysis-sql.o_list_eda.sellers` AS s
    ON sm.seller_id = s.seller_id

ORDER BY
    sm.total_revenue DESC

LIMIT 20;