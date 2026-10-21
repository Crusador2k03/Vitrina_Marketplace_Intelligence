CREATE OR REPLACE VIEW
  `funnel-analysis-sql.o_list_eda.vw_dim_category` AS

SELECT DISTINCT
  COALESCE(
    NULLIF(TRIM(product_category_english), ''),
    'Unknown'
  ) AS product_category

FROM `funnel-analysis-sql.o_list_eda.products`;