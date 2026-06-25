CREATE OR REPLACE VIEW stg_campaigns AS
SELECT
    campaign_id,
    campaign_name,
    CAST(start_date AS DATE) AS start_date,
    CAST(end_date AS DATE) AS end_date,
    LOWER(campaign_type) AS campaign_type,
    LOWER(target_product) AS target_product
FROM raw_campaigns
WHERE campaign_id IS NOT NULL
  AND campaign_id != 'CMP_NO_EXISTE'
  AND start_date IS NOT NULL
  AND end_date IS NOT NULL
  AND start_date <= end_date;