-- =========================================================
-- EDA 08: PAYMENT METHOD ANALYSIS
-- Delivered orders only
-- =========================================================

WITH payment_metrics AS (
    SELECT
        p.payment_type,

        COUNT(*) AS payment_records,

        COUNT(DISTINCT p.order_id) AS orders_using_method,

        SUM(p.payment_value) AS recorded_payment_value,

        AVG(p.payment_value) AS avg_payment_record_value,

        AVG(
            IF(
                p.payment_type = 'credit_card',
                CAST(p.payment_installments AS FLOAT64),
                NULL
            )
        ) AS avg_credit_card_installments

    FROM
        `funnel-analysis-sql.o_list_eda.payments` AS p

    JOIN
        `funnel-analysis-sql.o_list_eda.orders` AS o
        ON p.order_id = o.order_id

    WHERE
        o.order_status = 'delivered'

    GROUP BY
        p.payment_type
)

SELECT
    payment_type,
    payment_records,
    orders_using_method,

    ROUND(recorded_payment_value, 2)
        AS recorded_payment_value,

    ROUND(
        100 * SAFE_DIVIDE(
            recorded_payment_value,
            SUM(recorded_payment_value) OVER ()
        ),
        2
    ) AS payment_value_share_pct,

    ROUND(avg_payment_record_value, 2)
        AS avg_payment_record_value,

    ROUND(avg_credit_card_installments, 2)
        AS avg_credit_card_installments

FROM
    payment_metrics

ORDER BY
    recorded_payment_value DESC;