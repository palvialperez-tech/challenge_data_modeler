CREATE OR REPLACE TABLE fact_campaign_event AS
SELECT
    e.event_id,
    e.campaign_id,
    e.customer_id,
    e.event_date,
    e.event_type,
    e.channel,
    c.risk_segment AS customer_risk_segment,
    camp.start_date AS campaign_start_date,
    camp.end_date AS campaign_end_date
FROM stg_campaign_events e
LEFT JOIN dim_customer c ON e.customer_id = c.customer_id
LEFT JOIN dim_campaign camp ON e.campaign_id = camp.campaign_id;