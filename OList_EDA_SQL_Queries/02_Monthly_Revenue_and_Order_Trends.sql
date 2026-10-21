-- =========================================================
-- EDA 02: MONTHLY REVENUE AND ORDER TRENDS
-- =========================================================

WITH order_value AS (
    -- Aggregate items before joining to orders.
    -- This prevents duplicated revenue from one-to-many joins.
    SELECT
        order_id,
        SUM(price) AS item_revenue,
        SUM(freight_value) AS freight_revenue,
        SUM(price + freight_value) AS total_revenue
    FROM
        `funnel-analysis-sql.o_list_eda.order_items`
    GROUP BY
        order_id
),

monthly_metrics AS (
    SELECT
        DATE_TRUNC(
            DATE(o.order_purchase_timestamp),
            MONTH
        ) AS order_month,

        COUNT(DISTINCT o.order_id) AS total_orders,

        COUNTIF(
            o.order_status = 'delivered'
        ) AS delivered_orders,

        COUNTIF(
            o.order_status = 'canceled'
        ) AS canceled_orders,

        SUM(
            IF(
                o.order_status = 'delivered',
                COALESCE(v.item_revenue, NUMERIC '0'),
                NUMERIC '0'
            )
        ) AS item_revenue,

        SUM(
            IF(
                o.order_status = 'delivered',
                COALESCE(v.freight_revenue, NUMERIC '0'),
                NUMERIC '0'
            )
        ) AS freight_revenue,

        SUM(
            IF(
                o.order_status = 'delivered',
                COALESCE(v.total_revenue, NUMERIC '0'),
                NUMERIC '0'
            )
        ) AS total_revenue

    FROM
        `funnel-analysis-sql.o_list_eda.orders` AS o

    LEFT JOIN
        order_value AS v
        ON o.order_id = v.order_id

    GROUP BY
        order_month
),

monthly_with_previous AS (
    SELECT
        *,
        LAG(total_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue,

        LAG(total_orders) OVER (
            ORDER BY order_month
        ) AS previous_month_orders

    FROM monthly_metrics
)

SELECT
    order_month,
    total_orders,
    delivered_orders,
    canceled_orders,

    ROUND(item_revenue, 2) AS item_revenue,
    ROUND(freight_revenue, 2) AS freight_revenue,
    ROUND(total_revenue, 2) AS total_revenue,

    ROUND(
        SAFE_DIVIDE(total_revenue, delivered_orders),
        2
    ) AS delivered_order_aov,

    ROUND(
        total_revenue - previous_month_revenue,
        2
    ) AS revenue_change,

    ROUND(
        100 * SAFE_DIVIDE(
            total_revenue - previous_month_revenue,
            previous_month_revenue
        ),
        2
    ) AS revenue_growth_pct,

    ROUND(
        100 * SAFE_DIVIDE(
            total_orders - previous_month_orders,
            previous_month_orders
        ),
        2
    ) AS order_growth_pct

FROM monthly_with_previous
ORDER BY order_month;