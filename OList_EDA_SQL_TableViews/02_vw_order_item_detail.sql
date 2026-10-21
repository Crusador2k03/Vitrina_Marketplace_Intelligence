CREATE OR REPLACE VIEW
  `funnel-analysis-sql.o_list_eda.vw_order_item_detail` AS

SELECT
  oi.order_id,
  oi.order_item_id,
  oi.product_id,
  oi.seller_id,

  DATE(o.order_purchase_timestamp) AS order_date,
  DATE_TRUNC(
    DATE(o.order_purchase_timestamp), MONTH
  ) AS order_month,

  o.order_status,
  o.delivery_performance,
  c.customer_state,

  COALESCE(
    NULLIF(TRIM(p.product_category_english), ''),
    'Unknown'
  ) AS product_category,

  p.product_category_name,
  p.product_weight_g,

  s.seller_city,
  s.seller_state,

  oi.price,
  oi.freight_value,
  oi.price + oi.freight_value AS item_total_revenue

FROM `funnel-analysis-sql.o_list_eda.order_items` AS oi

JOIN `funnel-analysis-sql.o_list_eda.orders` AS o
  ON oi.order_id = o.order_id

LEFT JOIN `funnel-analysis-sql.o_list_eda.products` AS p
  ON oi.product_id = p.product_id

LEFT JOIN `funnel-analysis-sql.o_list_eda.sellers` AS s
  ON oi.seller_id = s.seller_id

LEFT JOIN `funnel-analysis-sql.o_list_eda.customers` AS c
  ON o.customer_id = c.customer_id;