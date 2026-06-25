CREATE OR REPLACE VIEW stg_cards AS
WITH cleaned AS (
    SELECT
        card_id,
        customer_id,
        account_id,
        LOWER(card_type) AS card_type,
        CAST(created_at AS TIMESTAMP) AS created_at,
        LOWER(status) AS status,
        ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY created_at DESC) AS rn
    FROM raw_cards
    WHERE card_id IS NOT NULL
      AND card_id != 'CARD_NO_EXISTE'
      AND customer_id IS NOT NULL
      AND customer_id != 'CUST_NO_EXISTE'
      AND account_id IS NOT NULL
      AND account_id != 'ACC_NO_EXISTE'
)
SELECT
    card_id,
    customer_id,
    account_id,
    card_type,
    created_at,
    status
FROM cleaned
WHERE status IN ('active', 'inactive', 'blocked', 'expired')
  AND rn = 1;