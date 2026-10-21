-- =====================================================================
-- EDA 11: REGIONAL DEMAND, DELIVERY PERFORMANCE & CUSTOMER SATISFACTION
-- Grain: one row per customer state
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

review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM
        `funnel-analysis-sql.o_list_eda.reviews`
    GROUP BY
        order_id
),

order_level AS (
    SELECT
        o.order_id,
        o.order_status,
        c.customer_state,
        c.customer_unique_id,
        COALESCE(v.total_revenue, NUMERIC '0') AS order_revenue,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        r.avg_review_score
    FROM
        `funnel-analysis-sql.o_list_eda.orders` AS o
    JOIN
        `funnel-analysis-sql.o_list_eda.customers` AS c
        ON o.customer_id = c.customer_id
    LEFT JOIN
        order_value AS v
        ON o.order_id = v.order_id
    LEFT JOIN
        review_by_order AS r
        ON o.order_id = r.order_id
),

regional_metrics AS (
    SELECT
        customer_state,

        COUNT(DISTINCT order_id) AS total_orders,
        COUNTIF(order_status = 'delivered') AS delivered_orders,
        COUNTIF(order_status = 'canceled') AS canceled_orders,

        COUNT(DISTINCT IF(
            order_status = 'delivered',
            customer_unique_id,
            NULL
        )) AS unique_delivered_customers,

        SUM(IF(
            order_status = 'delivered',
            order_revenue,
            NUMERIC '0'
        )) AS delivered_revenue,

        COUNTIF(
            order_status = 'delivered'
            AND order_delivered_customer_date IS NOT NULL
            AND order_estimated_delivery_date IS NOT NULL
        ) AS deliveries_with_valid_estimate,

        COUNTIF(
            order_status = 'delivered'
            AND order_delivered_customer_date IS NOT NULL
            AND order_estimated_delivery_date IS NOT NULL
            AND DATE(order_delivered_customer_date)
                > order_estimated_delivery_date
        ) AS late_deliveries,

        COUNTIF(
            order_status = 'delivered'
            AND avg_review_score IS NOT NULL
        ) AS orders_with_reviews,

        AVG(IF(
            order_status = 'delivered',
            avg_review_score,
            NULL
        )) AS avg_review_score,

        COUNTIF(
            order_status = 'delivered'
            AND avg_review_score IS NOT NULL
            AND avg_review_score <= 2
        ) AS low_review_orders

    FROM
        order_level
    GROUP BY
        customer_state
)

SELECT
    customer_state,

    -- Demand and order outcomes
    total_orders,
    delivered_orders,
    canceled_orders,
    unique_delivered_customers,

    -- Delivered revenue and contribution
    ROUND(delivered_revenue, 2) AS delivered_revenue,
    ROUND(
        SAFE_DIVIDE(delivered_revenue, delivered_orders),
        2
    ) AS delivered_order_aov,
    ROUND(
        100 * SAFE_DIVIDE(
            delivered_revenue,
            SUM(delivered_revenue) OVER ()
        ),
        2
    ) AS revenue_share_pct,
    ROUND(
        100 * SAFE_DIVIDE(canceled_orders, total_orders),
        2
    ) AS cancellation_rate_pct,

    -- Delivery reliability and contribution to late deliveries
    deliveries_with_valid_estimate,
    late_deliveries,
    ROUND(
        100 * SAFE_DIVIDE(
            late_deliveries,
            deliveries_with_valid_estimate
        ),
        2
    ) AS late_delivery_rate_pct,
    ROUND(
        100 * SAFE_DIVIDE(
            late_deliveries,
            SUM(late_deliveries) OVER ()
        ),
        2
    ) AS share_of_all_late_deliveries_pct,

    -- Customer satisfaction (review scores aggregated by order)
    orders_with_reviews,
    ROUND(avg_review_score, 2) AS avg_review_score,
    ROUND(
        100 * SAFE_DIVIDE(low_review_orders, orders_with_reviews),
        2
    ) AS low_review_share_pct

FROM
    regional_metrics
ORDER BY
    delivered_revenue DESC;
