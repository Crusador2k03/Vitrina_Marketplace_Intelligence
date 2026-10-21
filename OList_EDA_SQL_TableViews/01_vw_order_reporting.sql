CREATE OR REPLACE VIEW
  `funnel-analysis-sql.o_list_eda.vw_order_reporting` AS

WITH item_totals AS (
  SELECT
    order_id,
    COUNT(*) AS items_sold,
    SUM(price) AS item_revenue,
    SUM(freight_value) AS freight_revenue,
    SUM(price + freight_value) AS total_revenue
  FROM `funnel-analysis-sql.o_list_eda.order_items`
  GROUP BY order_id
),

payment_totals AS (
  SELECT
    order_id,
    SUM(payment_value) AS payment_total
  FROM `funnel-analysis-sql.o_list_eda.payments`
  GROUP BY order_id
),

review_totals AS (
  SELECT
    order_id,
    COUNT(*) AS review_count,
    AVG(review_score) AS avg_review_score,
    LOGICAL_OR(has_written_feedback) AS has_written_feedback
  FROM `funnel-analysis-sql.o_list_eda.reviews`
  GROUP BY order_id
)

SELECT
  o.order_id,
  o.customer_id,
  c.customer_unique_id,
  c.customer_state,

  o.order_status,
  o.order_purchase_timestamp,
  DATE(o.order_purchase_timestamp) AS order_date,
  DATE_TRUNC(
    DATE(o.order_purchase_timestamp), MONTH
  ) AS order_month,

  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  o.delivery_performance,
  o.temporal_valid,
  o.purchase_to_delivery_days,
  o.delivery_delay_days,

  CASE
    WHEN o.order_delivered_customer_date IS NULL
      OR o.order_estimated_delivery_date IS NULL
      THEN NULL
    ELSE DATE_DIFF(
      DATE(o.order_delivered_customer_date),
      o.order_estimated_delivery_date,
      DAY
    )
  END AS calendar_delivery_delay_days,

  COALESCE(i.items_sold, 0) AS items_sold,
  COALESCE(i.item_revenue, NUMERIC '0') AS item_revenue,
  COALESCE(i.freight_revenue, NUMERIC '0') AS freight_revenue,
  COALESCE(i.total_revenue, NUMERIC '0') AS total_revenue,

  p.payment_total,

  r.review_count,
  r.avg_review_score,
  COALESCE(r.has_written_feedback, FALSE)
    AS has_written_feedback

FROM `funnel-analysis-sql.o_list_eda.orders` AS o

LEFT JOIN `funnel-analysis-sql.o_list_eda.customers` AS c
  ON o.customer_id = c.customer_id

LEFT JOIN item_totals AS i
  ON o.order_id = i.order_id

LEFT JOIN payment_totals AS p
  ON o.order_id = p.order_id

LEFT JOIN review_totals AS r
  ON o.order_id = r.order_id;