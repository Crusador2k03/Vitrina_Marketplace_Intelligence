-- =====================================================================
-- EDA 07: CUSTOMER REPEAT-PURCHASE AND REVENUE CONTRIBUTION
-- =====================================================================

WITH order_value AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS total_revenue
    FROM
        `funnel-analysis-sql.o_list_eda.order_items`
    GROUP BY
        order_id
),

customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        COALESCE(v.total_revenue, NUMERIC '0') AS order_revenue
    FROM
        `funnel-analysis-sql.o_list_eda.orders` AS o
    JOIN
        `funnel-analysis-sql.o_list_eda.customers` AS c
        ON o.customer_id = c.customer_id
    LEFT JOIN
        order_value AS v
        ON o.order_id = v.order_id
    WHERE
        o.order_status = 'delivered'
),

customer_summary AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS delivered_orders,
        SUM(order_revenue) AS customer_revenue
    FROM
        customer_orders
    GROUP BY
        customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        customer_revenue,
        CASE
            WHEN delivered_orders = 1 THEN '1 order'
            WHEN delivered_orders = 2 THEN '2 orders'
            ELSE '3+ orders'
        END AS purchase_frequency
    FROM
        customer_summary
)

SELECT
    purchase_frequency,

    COUNT(*) AS customer_count,

    ROUND(
        100 * SAFE_DIVIDE(
            COUNT(*),
            SUM(COUNT(*)) OVER ()
        ),
        2
    ) AS customer_share_pct,

    SUM(delivered_orders) AS delivered_orders,

    ROUND(
        SUM(customer_revenue),
        2
    ) AS total_revenue,

    ROUND(
        100 * SAFE_DIVIDE(
            SUM(customer_revenue),
            SUM(SUM(customer_revenue)) OVER ()
        ),
        2
    ) AS revenue_share_pct,

    ROUND(
        AVG(customer_revenue),
        2
    ) AS avg_revenue_per_customer,

    ROUND(
        SAFE_DIVIDE(
            SUM(customer_revenue),
            SUM(delivered_orders)
        ),
        2
    ) AS revenue_per_delivered_order

FROM
    customer_segments

GROUP BY
    purchase_frequency

ORDER BY
    CASE purchase_frequency
        WHEN '1 order' THEN 1
        WHEN '2 orders' THEN 2
        WHEN '3+ orders' THEN 3
    END;
