-- =========================================================
-- 01. OVERALL BUSINESS PERFORMANCE
-- =========================================================

WITH order_value AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS item_revenue,
        SUM(freight_value) AS freight_revenue,
        SUM(price + freight_value) AS total_order_value
    FROM
        `funnel-analysis-sql.o_list_eda.order_items`
    GROUP BY
        order_id
)

SELECT
    -- Order and customer metrics
    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNTIF(
        o.order_status = 'delivered'
    ) AS delivered_orders,

    COUNTIF(
        o.order_status = 'canceled'
    ) AS canceled_orders,

    COUNT(DISTINCT c.customer_unique_id)
        AS unique_customers,

    COUNT(DISTINCT IF(
        o.order_status = 'delivered',
        c.customer_unique_id,
        NULL
    )) AS customers_with_delivered_orders,

    -- Revenue metrics: delivered orders only
    ROUND(
        SUM(IF(
            o.order_status = 'delivered',
            COALESCE(v.item_revenue, NUMERIC '0'),
            NUMERIC '0'
        )),
        2
    ) AS delivered_item_revenue,

    ROUND(
        SUM(IF(
            o.order_status = 'delivered',
            COALESCE(v.freight_revenue, NUMERIC '0'),
            NUMERIC '0'
        )),
        2
    ) AS delivered_freight_revenue,

    ROUND(
        SUM(IF(
            o.order_status = 'delivered',
            COALESCE(v.total_order_value, NUMERIC '0'),
            NUMERIC '0'
        )),
        2
    ) AS delivered_revenue_including_freight,

    -- Average order value
    ROUND(
        SAFE_DIVIDE(
            SUM(IF(
                o.order_status = 'delivered',
                COALESCE(v.total_order_value, NUMERIC '0'),
                NUMERIC '0'
            )),
            COUNTIF(o.order_status = 'delivered')
        ),
        2
    ) AS delivered_order_aov,

    -- Fulfilled order metrics
    ROUND(
        SAFE_DIVIDE(
            SUM(IF(
                o.order_status = 'delivered',
                COALESCE(v.item_count, 0),
                0
            )),
            COUNTIF(o.order_status = 'delivered')
        ),
        2
    ) AS avg_items_per_delivered_order

FROM
    `funnel-analysis-sql.o_list_eda.orders` AS o

LEFT JOIN
    order_value AS v
    ON o.order_id = v.order_id

LEFT JOIN
    `funnel-analysis-sql.o_list_eda.customers` AS c
    ON o.customer_id = c.customer_id;