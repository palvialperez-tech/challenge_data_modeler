CREATE OR REPLACE TABLE fact_transaction AS
SELECT
    t.transaction_id,
    t.customer_id,
    t.card_id,
    t.merchant_id,
    t.transaction_date,
    CAST(t.amount AS DECIMAL) AS amount,   
    t.currency,
    CAST(t.installments AS INTEGER) AS installments,  
    t.transaction_status,
    t.transaction_type,
    c.risk_segment AS customer_risk_segment,
    m.merchant_category
FROM stg_transactions t
LEFT JOIN dim_customer c ON t.customer_id = c.customer_id
LEFT JOIN dim_merchant m ON t.merchant_id = m.merchant_id
WHERE t.transaction_status = 'approved';