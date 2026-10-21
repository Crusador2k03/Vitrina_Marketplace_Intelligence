-- =========================================================
-- EDA 04: TOP PRODUCTS BY DELIVERED REVENUE
-- =========================================================

SELECT
    oi.product_id,

    COALESCE(
        NULLIF(TRIM(p.product_category_english), ''),
        'Unknown'
    ) AS product_category,

    COUNT(*) AS items_sold,

    COUNT(DISTINCT oi.order_id) AS delivered_orders,

    COUNT(DISTINCT oi.seller_id) AS sellers,

    ROUND(SUM(oi.price), 2) AS item_revenue,

    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,

    ROUND(SUM(oi.price + oi.freight_value), 2)
        AS total_revenue,

    ROUND(AVG(oi.price), 2) AS avg_item_price

FROM
    `funnel-analysis-sql.o_list_eda.order_items` AS oi

JOIN
    `funnel-analysis-sql.o_list_eda.orders` AS o
    ON oi.order_id = o.order_id

LEFT JOIN
    `funnel-analysis-sql.o_list_eda.products` AS p
    ON oi.product_id = p.product_id

WHERE
    o.order_status = 'delivered'

GROUP BY
    oi.product_id,
    product_category

ORDER BY
    total_revenue DESC

LIMIT 20;