CREATE OR REPLACE VIEW stg_accounts AS
WITH cleaned AS (
    SELECT
        account_id,
        customer_id,
        LOWER(account_type) AS account_type,
        CAST(created_at AS TIMESTAMP) AS created_at,
        LOWER(status) AS status,
        ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_at DESC) AS rn
    FROM raw_accounts
    WHERE account_id IS NOT NULL
      AND account_id != 'ACC_NO_EXISTE'
      AND customer_id IS NOT NULL
      AND customer_id != 'CUST_NO_EXISTE'
)
SELECT
    account_id,
    customer_id,
    account_type,
    created_at,
    status
FROM cleaned
WHERE status IN ('active', 'inactive', 'blocked', 'closed')
  AND rn = 1;