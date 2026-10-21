-- ==============================================================
-- EDA 03: PRODUCT CATEGORY PERFORMANCE AND CUSTOMER SATISFACTION
-- Grain: one row per product category.
-- ==============================================================


WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM
        `funnel-analysis-sql.o_list_eda.reviews`
    GROUP BY
        order_id
),

order_category AS (
    SELECT
        oi.order_id,
        COALESCE(
            NULLIF(TRIM(p.product_category_english), ''),
            'Unknown'
        ) AS product_category,
        COUNT(*) AS items_sold,
        SUM(oi.price) AS item_revenue,
        SUM(oi.freight_value) AS freight_revenue,
        SUM(oi.price + oi.freight_value) AS total_revenue
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
        oi.order_id,
        product_category
),

category_revenue AS (
    SELECT
        product_category,
        SUM(items_sold) AS items_sold,
        COUNT(*) AS delivered_orders,
        SUM(item_revenue) AS item_revenue,
        SUM(freight_revenue) AS freight_revenue,
        SUM(total_revenue) AS total_revenue
    FROM
        order_category
    GROUP BY
        product_category
),

category_satisfaction AS (
    SELECT
        oc.product_category,
        COUNT(*) AS orders_with_reviews,
        AVG(r.avg_review_score) AS avg_review_score,
        100 * SAFE_DIVIDE(
            COUNTIF(r.avg_review_score <= 2),
            COUNT(*)
        ) AS low_review_share_pct,
        100 * SAFE_DIVIDE(
            COUNTIF(r.avg_review_score >= 4),
            COUNT(*)
        ) AS high_review_share_pct
    FROM
        order_category AS oc
    JOIN
        review_by_order AS r
        ON oc.order_id = r.order_id
    GROUP BY
        oc.product_category
)

SELECT
    cr.product_category,
    cr.items_sold,
    cr.delivered_orders,
    ROUND(cr.item_revenue, 2) AS item_revenue,
    ROUND(cr.freight_revenue, 2) AS freight_revenue,
    ROUND(cr.total_revenue, 2) AS total_revenue,
    ROUND(
        100 * SAFE_DIVIDE(
            cr.total_revenue,
            SUM(cr.total_revenue) OVER ()
        ),
        2
    ) AS revenue_share_pct,
    ROUND(
        SAFE_DIVIDE(cr.total_revenue, cr.delivered_orders),
        2
    ) AS revenue_per_category_order,
    COALESCE(cs.orders_with_reviews, 0) AS orders_with_reviews,
    ROUND(cs.avg_review_score, 2) AS avg_review_score,
    ROUND(cs.low_review_share_pct, 2) AS low_review_share_pct,
    ROUND(cs.high_review_share_pct, 2) AS high_review_share_pct
FROM
    category_revenue AS cr
LEFT JOIN
    category_satisfaction AS cs
    ON cr.product_category = cs.product_category
ORDER BY
    cr.total_revenue DESC;
