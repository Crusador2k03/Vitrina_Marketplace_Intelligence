CREATE OR REPLACE VIEW
  `funnel-analysis-sql.o_list_eda.vw_payment_detail` AS

SELECT
  p.order_id,
  p.payment_sequential,
  p.payment_type,
  p.payment_installments,
  p.payment_value,

  DATE(o.order_purchase_timestamp) AS order_date,
  DATE_TRUNC(
    DATE(o.order_purchase_timestamp), MONTH
  ) AS order_month,

  o.order_status,
  c.customer_state

FROM `funnel-analysis-sql.o_list_eda.payments` AS p

JOIN `funnel-analysis-sql.o_list_eda.orders` AS o
  ON p.order_id = o.order_id

LEFT JOIN `funnel-analysis-sql.o_list_eda.customers` AS c
  ON o.customer_id = c.customer_id;