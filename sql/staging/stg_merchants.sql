CREATE OR REPLACE VIEW stg_merchants AS
WITH cleaned AS (
    SELECT
        merchant_id,
        merchant_name,
        LOWER(merchant_category) AS merchant_category,
        region,
        city,
        ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY merchant_name DESC) AS rn
    FROM raw_merchants
    WHERE merchant_id IS NOT NULL
      AND merchant_id != 'MERC_NO_EXISTE'
)
SELECT
    merchant_id,
    merchant_name,
    merchant_category,
    region,
    city
FROM cleaned
WHERE rn = 1;