CREATE OR REPLACE VIEW stg_campaign_events AS
WITH cleaned AS (
    SELECT
        event_id,
        campaign_id,
        customer_id,
        CAST(event_date AS TIMESTAMP) AS event_date,
        LOWER(event_type) AS event_type,
        LOWER(channel) AS channel,
        ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_date DESC) AS rn
    FROM raw_campaign_events
    WHERE event_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND customer_id != 'CUST_NO_EXISTE'
      AND campaign_id IS NOT NULL
      AND campaign_id != 'CMP_NO_EXISTE'
)
SELECT
    event_id,
    campaign_id,
    customer_id,
    event_date,
    event_type,
    channel
FROM cleaned
WHERE event_type IN ('sent', 'opened', 'clicked')
  AND rn = 1;