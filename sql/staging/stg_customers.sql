CREATE OR REPLACE VIEW stg_customers AS
WITH cleaned AS (
    SELECT
        customer_id,
        CAST(created_at AS TIMESTAMP) AS created_at,
        CAST(birth_date AS DATE) AS birth_date,
        UPPER(gender) AS gender,
        region,
        city,
        LOWER(customer_status) AS customer_status,
        LOWER(risk_segment) AS risk_segment,
        income_range,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at DESC) AS rn
    FROM raw_customers
    WHERE customer_id IS NOT NULL
      AND customer_id != ''
      AND customer_id != 'CUST_NO_EXISTE'
)
SELECT
    customer_id,
    created_at,
    birth_date,
    gender,
    region,
    city,
    customer_status,
    risk_segment,
    income_range
FROM cleaned
WHERE birth_date IS NOT NULL
  AND birth_date <= CURRENT_DATE
  AND rn = 1;
