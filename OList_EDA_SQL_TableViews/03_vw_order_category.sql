CREATE OR REPLACE VIEW
  `funnel-analysis-sql.o_list_eda.vw_order_category` AS

WITH review_totals AS (
  SELECT
    order_id,
    COUNT(*) AS review_count,
    AVG(review_score) AS avg_review_score
  FROM `funnel-analysis-sql.o_list_eda.reviews`
  GROUP BY order_id
),

category_orders AS (
  SELECT
    oi.order_id,

    DATE(o.order_purchase_timestamp) AS order_date,
    DATE_TRUNC(
      DATE(o.order_purchase_timestamp), MONTH
    ) AS order_month,

    c.customer_state,

    COALESCE(
      NULLIF(TRIM(p.product_category_english), ''),
      'Unknown'
    ) AS product_category,

    COUNT(*) AS items_sold,
    SUM(oi.price) AS item_revenue,
    SUM(oi.freight_value) AS freight_revenue,
    SUM(oi.price + oi.freight_value) AS total_revenue

  FROM `funnel-analysis-sql.o_list_eda.order_items` AS oi

  JOIN `funnel-analysis-sql.o_list_eda.orders` AS o
    ON oi.order_id = o.order_id

  LEFT JOIN `funnel-analysis-sql.o_list_eda.products` AS p
    ON oi.product_id = p.product_id

  LEFT JOIN `funnel-analysis-sql.o_list_eda.customers` AS c
    ON o.customer_id = c.customer_id

  WHERE o.order_status = 'delivered'

  GROUP BY
    oi.order_id,
    order_date,
    order_month,
    c.customer_state,
    product_category
)

SELECT
  co.*,
  r.review_count,
  r.avg_review_score

FROM category_orders AS co

LEFT JOIN review_totals AS r
  ON co.order_id = r.order_id;