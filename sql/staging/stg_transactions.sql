CREATE OR REPLACE VIEW stg_transactions AS
WITH cleaned AS (
    SELECT
        transaction_id,
        customer_id,
        card_id,
        merchant_id,
        CAST(transaction_date AS TIMESTAMP) AS transaction_date,
        amount,
        currency,
        installments,
        LOWER(transaction_status) AS transaction_status,
        LOWER(transaction_type) AS transaction_type,
        ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_date DESC) AS rn
    FROM raw_transactions
    WHERE transaction_id IS NOT NULL
      AND transaction_id NOT LIKE 'TXN999999%'
      AND customer_id IS NOT NULL
      AND customer_id != 'CUST_NO_EXISTE'
      AND card_id IS NOT NULL
      AND card_id != 'CARD_NO_EXISTE'
      AND merchant_id IS NOT NULL
      AND merchant_id != 'MERC_NO_EXISTE'
)
SELECT
    transaction_id,
    customer_id,
    card_id,
    merchant_id,
    transaction_date,
    amount,
    currency,
    installments,
    transaction_status,
    transaction_type
FROM cleaned
WHERE transaction_date IS NOT NULL
  AND transaction_date <= CAST(CURRENT_TIMESTAMP AS TIMESTAMP)
  AND transaction_status IN ('approved', 'reversed', 'rejected', 'pending')
  AND transaction_type IN ('purchase', 'refund', 'withdrawal')
  AND rn = 1;