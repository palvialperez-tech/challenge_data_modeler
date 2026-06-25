CREATE OR REPLACE TABLE mart_campaign_conversion AS
WITH impacted_clients AS (
    SELECT DISTINCT campaign_id, customer_id
    FROM fact_campaign_event
    WHERE event_type = 'sent'
),
campaign_calendar AS (
    SELECT campaign_id, start_date, end_date
    FROM dim_campaign
),
converted_clients AS (
    SELECT DISTINCT t.customer_id, 'CMP2026053CSI' AS campaign_id
    FROM fact_transaction t
    CROSS JOIN campaign_calendar cc
    WHERE cc.campaign_id = 'CMP2026053CSI'
      AND t.transaction_date BETWEEN cc.start_date AND cc.end_date
      AND CAST(t.installments AS INTEGER) = 3
      AND t.transaction_status = 'approved'
      AND t.transaction_type = 'purchase'
),
campaign_metrics AS (
    SELECT
        i.campaign_id,
        i.customer_id,
        MAX(CASE WHEN e.event_type = 'sent' THEN 1 ELSE 0 END) AS is_impacted,
        MAX(CASE WHEN e.event_type IN ('opened', 'clicked') THEN 1 ELSE 0 END) AS is_interacted,
        MAX(CASE WHEN c.customer_id IS NOT NULL THEN 1 ELSE 0 END) AS is_converted,
        COALESCE(SUM(CASE WHEN t.transaction_status = 'approved' AND CAST(t.installments AS INTEGER) = 3 THEN CAST(t.amount AS DECIMAL) ELSE 0 END), 0) AS total_3csi_amount,
        COUNT(DISTINCT CASE WHEN t.transaction_status = 'approved' AND CAST(t.installments AS INTEGER) = 3 THEN t.transaction_id END) AS total_3csi_transactions
    FROM impacted_clients i
    LEFT JOIN fact_campaign_event e ON i.campaign_id = e.campaign_id AND i.customer_id = e.customer_id
    LEFT JOIN converted_clients c ON i.campaign_id = c.campaign_id AND i.customer_id = c.customer_id
    LEFT JOIN fact_transaction t ON i.customer_id = t.customer_id
        AND t.transaction_date BETWEEN (SELECT start_date FROM dim_campaign WHERE campaign_id = i.campaign_id)
                                   AND (SELECT end_date FROM dim_campaign WHERE campaign_id = i.campaign_id)
        AND t.transaction_status = 'approved'
        AND CAST(t.installments AS INTEGER) = 3
    GROUP BY i.campaign_id, i.customer_id
)
SELECT
    campaign_id,
    customer_id,
    is_impacted,
    is_interacted,
    is_converted,
    total_3csi_amount,
    total_3csi_transactions,
    CASE WHEN total_3csi_transactions > 0 THEN total_3csi_amount / total_3csi_transactions ELSE 0 END AS avg_ticket_3csi
FROM campaign_metrics;