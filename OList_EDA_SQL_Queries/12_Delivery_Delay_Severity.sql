-- =========================================================
-- EDA 12: SEVERITY OF LATE DELIVERIES BY STATE
-- =========================================================

WITH state_delivery AS (
    SELECT
        c.customer_state,

        COUNT(*) AS eligible_deliveries,

        COUNTIF(
            DATE(o.order_delivered_customer_date)
                > o.order_estimated_delivery_date
        ) AS late_orders,

        AVG(
            IF(
                DATE(o.order_delivered_customer_date)
                    > o.order_estimated_delivery_date,
                DATE_DIFF(
                    DATE(o.order_delivered_customer_date),
                    o.order_estimated_delivery_date,
                    DAY
                ),
                NULL
            )
        ) AS avg_days_late,

        APPROX_QUANTILES(
            IF(
                DATE(o.order_delivered_customer_date)
                    > o.order_estimated_delivery_date,
                DATE_DIFF(
                    DATE(o.order_delivered_customer_date),
                    o.order_estimated_delivery_date,
                    DAY
                ),
                NULL
            ),
            100
        )[OFFSET(50)] AS median_days_late,

        APPROX_QUANTILES(
            IF(
                DATE(o.order_delivered_customer_date)
                    > o.order_estimated_delivery_date,
                DATE_DIFF(
                    DATE(o.order_delivered_customer_date),
                    o.order_estimated_delivery_date,
                    DAY
                ),
                NULL
            ),
            100
        )[OFFSET(90)] AS p90_days_late

    FROM
        `funnel-analysis-sql.o_list_eda.orders` AS o

    JOIN
        `funnel-analysis-sql.o_list_eda.customers` AS c
        ON o.customer_id = c.customer_id

    WHERE
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL

    GROUP BY
        c.customer_state
)

SELECT
    customer_state,
    eligible_deliveries,
    late_orders,

    ROUND(
        100 * SAFE_DIVIDE(
            late_orders,
            eligible_deliveries
        ),
        2
    ) AS late_delivery_rate_pct,

    ROUND(avg_days_late, 2) AS avg_days_late,
    median_days_late,
    p90_days_late

FROM
    state_delivery

ORDER BY
    late_orders DESC;