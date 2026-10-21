CREATE OR REPLACE VIEW
  `funnel-analysis-sql.o_list_eda.vw_customer_summary` AS

WITH customer_metrics AS (
  SELECT
    customer_unique_id,

    ARRAY_AGG(
      customer_state IGNORE NULLS
      ORDER BY order_purchase_timestamp DESC
      LIMIT 1
    )[SAFE_OFFSET(0)] AS latest_customer_state,

    MIN(DATE(order_purchase_timestamp)) AS first_order_date,
    MAX(DATE(order_purchase_timestamp)) AS last_order_date,

    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(DISTINCT IF(
      order_status = 'delivered',
      order_id,
      NULL
    )) AS delivered_orders,

    SUM(IF(
      order_status = 'delivered',
      total_revenue,
      NUMERIC '0'
    )) AS delivered_revenue

  FROM `funnel-analysis-sql.o_list_eda.vw_order_reporting`

  WHERE customer_unique_id IS NOT NULL

  GROUP BY customer_unique_id
)

SELECT
  *,

  CASE
    WHEN delivered_orders = 0 THEN '0 delivered orders'
    WHEN delivered_orders = 1 THEN '1 order'
    WHEN delivered_orders = 2 THEN '2 orders'
    ELSE '3+ orders'
  END AS purchase_frequency,

  SAFE_DIVIDE(
    delivered_revenue,
    delivered_orders
  ) AS revenue_per_delivered_order

FROM customer_metrics;