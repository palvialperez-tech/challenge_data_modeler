# Challenge Data Modeler - 3 Cuotas Sin Interés

##  Descripción del Proyecto

Este proyecto implementa una capa analítica para medir el impacto, interacción y conversión de la campaña **"3 cuotas sin interés - mayo 2026"**. El objetivo es permitir que los equipos de Producto y Marketing analicen el desempeño de la campaña de forma autónoma y confiable, utilizando un modelo de datos simple, documentado y reutilizable.

La solución está construida con **Python + DuckDB** para ejecución local, pero está pensada para ser migrada a **BigQuery** en producción.

---

##  Cómo ejecutar o revisar la solución

### Requisitos previos

- Python 3.9+
- Pip (gestor de paquetes)

### Instalación

1. Clona o descarga el repositorio:
   ```bash
   git clone <repositorio>
   cd challenge_data_modeler
Instala las dependencias:

bash
pip install -r requirements.txt
Coloca los archivos CSV en la carpeta data/:

raw_customers.csv

raw_accounts.csv

raw_cards.csv

raw_transactions.csv

raw_merchants.csv

raw_campaigns.csv

raw_campaign_events.csv

Ejecución
bash
python scripts/load_and_transform.py
Resultados
El script genera automáticamente la carpeta outputs/ con:

dim_customer.csv - Datos de clientes

dim_merchant.csv - Datos de comercios

dim_campaign.csv - Datos de campañas

fact_transaction.csv - Transacciones aprobadas con dimensiones enriquecidas

fact_campaign_event.csv - Eventos de campaña con dimensiones enriquecidas

mart_campaign_conversion.csv - Tabla principal de análisis: resumen por campaña y cliente (impacto, interacción, conversión, montos, ticket)

quality_report.txt - Informe de controles de calidad

## Estructura del Proyecto

challenge_data_modeler/
├── data/                          # Datos fuente (CSVs)
├── sql/
│   ├── staging/                   # Limpieza y estandarización
│   │   ├── stg_customers.sql
│   │   ├── stg_accounts.sql
│   │   ├── stg_cards.sql
│   │   ├── stg_transactions.sql
│   │   ├── stg_merchants.sql
│   │   ├── stg_campaigns.sql
│   │   └── stg_campaign_events.sql
│   └── marts/                     # Modelos dimensionales y de hechos
│       ├── dim_customer.sql
│       ├── dim_merchant.sql
│       ├── dim_campaign.sql
│       ├── fact_transaction.sql
│       ├── fact_campaign_event.sql
│       └── mart_campaign_conversion.sql
├── scripts/
│   └── load_and_transform.py     # Orquestador principal
├── outputs/                       # Resultados generados
├── requirements.txt
└── README.md


# Supuestos tomados
Definición de conversión: Un cliente se considera convertido si fue impactado (recibió al menos un sent) y realizó al menos una transacción válida en 3 cuotas (installments = 3, status = 'approved', type = 'purchase') durante la vigencia de la campaña (entre start_date y end_date).

Transacciones válidas: Solo se consideran transacciones con transaction_status = 'approved' y transaction_type = 'purchase'. Las transacciones reversed, rejected, refund y withdrawal se excluyen del análisis de conversión y montos.

Granularidad del mart: mart_campaign_conversion tiene granularidad de campaña-cliente (1 fila por cada combinación), permitiendo análisis flexibles por segmento, región o categoría de comercio.

Cliente impactado: Se considera impactado a cualquier cliente con al menos un evento sent (enviado) de la campaña.

Cliente que interactuó: Cliente con al menos un evento opened (abrió) o clicked (hizo clic).

Duplicados: En caso de duplicados en tablas fuente, se toma el registro más reciente según la fecha de creación (created_at o event_date) usando ROW_NUMBER().

Fechas futuras: Se descartan transacciones y eventos con fecha futura a la fecha de ejecución.

## Decisiones de modelado
Capa de Staging (Limpieza)
Aislamiento del origen: La capa staging aísla a la capa de negocio de los errores y cambios en los datos crudos.

Tipado explícito: Todas las fechas se convierten a DATE o TIMESTAMP. Los montos se convierten a DECIMAL.

Normalización: Estados y tipos se convierten a minúsculas (LOWER) para consistencia.

Eliminación de duplicados: Se usa ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ... DESC) para quedarse con el registro más reciente.

Filtrado de errores: Se eliminan IDs inválidos (CUST_NO_EXISTE, CARD_NO_EXISTE, etc.) y registros con datos inconsistentes.

Modelo Estrella (Marts)
Dimensiones: dim_customer, dim_merchant, dim_campaign - tablas desnormalizadas para facilitar el filtrado y la segmentación.

Hechos: fact_transaction y fact_campaign_event - tablas de eventos transaccionales y de interacción, enriquecidas con dimensiones clave para evitar joins innecesarios.

Mart de conversión: mart_campaign_conversion - tabla agregada a nivel de campaña-cliente que centraliza todas las métricas clave (impacto, interacción, conversión, montos, ticket). Esta es la tabla principal para el consumo de los equipos de negocio.

Reutilización
El modelo está diseñado para soportar múltiples campañas sin modificaciones. Solo se necesita agregar un nuevo campaign_id en dim_campaign.

Las consultas de negocio se pueden adaptar fácilmente cambiando el campaign_id en el filtro.

## 🔍 Problemas de calidad detectados

| Problema | Ejemplo | Acción tomada |
|----------|---------|---------------|
| IDs inválidos | `CUST_NO_EXISTE`, `CARD_NO_EXISTE`, `MERC_NO_EXISTE` | Filtrados en staging |
| Duplicados | Clientes, comercios, transacciones y eventos duplicados | Eliminados con `ROW_NUMBER()` (se toma el más reciente) |
| Fechas nulas o futuras | Transacciones con fecha `2030-01-01`, clientes con `birth_date` nulo | Filtrados en staging (fechas futuras descartadas) |
| Estados inconsistentes | `active`, `ACTIVE`, `ActiVe` | Normalizados a minúsculas (`LOWER`) |
| Montos negativos | Transacciones con `amount < 0` | Identificados en controles de calidad; excluidos de métricas de conversión (pueden ser `refund`) |
| Referencias rotas | Transacciones con `merchant_id` o `customer_id` inexistente | Filtrados en staging (integridad referencial) |
| Eventos con tipo inválido | `bounce` en `event_type` | Filtrados en staging (solo `sent`, `opened`, `clicked`) |



## Controles de calidad implementados
En el script scripts/load_and_transform.py, la función quality_checks() ejecuta 7 controles (más de los 5 requeridos) y guarda un reporte en outputs/quality_report.txt.

#	Control	Descripción
1	Unicidad de claves primarias	Verifica que no haya customer_id duplicados en dim_customer
2	Nulos en campos críticos	Cuenta customer_id nulos en fact_transaction
3	Integridad referencial	Verifica que todas las transacciones tengan un cliente válido en dim_customer
4	Montos negativos	Cuenta transacciones con amount < 0
5	Fechas fuera de rango	Cuenta transacciones con fecha futura a CURRENT_TIMESTAMP
6	Eventos duplicados	Verifica duplicados por event_id en fact_campaign_event
7	Estados no reconocidos	Lista transaction_status que no están en los valores permitidos

#  Preguntas al negocio
1.-¿Es cualquier transacción en 3 cuotas durante la campaña, o debe ser la primera transacción después del impacto?
2.-¿Que cliente se considera como tocado o impactado, solo si tiene un evento como "sent" o si hicieron click?
3.-¿Si un cliente fue impactado, queremos interactuar nuevamante con el cliente? realmente queremos ostigarlo, o dejaremos marca de impacto?
4.-¿Con que frecuencia debemos monitorear estos casos? que tan critico es para el negocio?
5.-¿Que probabilidad hay de tener estos eventos/campañas eventos repetidamente?

Qué haría distinto si esto pasara a producción en BigQuery
Usar dbt (Data Build Tool)

Versionar y testear automáticamente cada modelo SQL.

Generar documentación automática y comprobar la integridad referencial.

Implementar lógica incremental para cargas diarias.

Particionamiento y clustering

fact_transaction particionada por transaction_date y clusterizada por customer_id, merchant_id.

fact_campaign_event particionada por event_date y clusterizada por campaign_id, customer_id.

Reduce costos y mejora rendimiento.

Incrementalidad

Cargar solo nuevos datos en lugar de reconstruir toda la tabla cada día.

SCD Tipo 2 en dimensiones

dim_customer debe rastrear cambios históricos en risk_segment, region, etc.

Monitorización y alertas

Notificaciones automáticas si fallan los controles de calidad.

Panel de control de calidad en tiempo real.

Orquestación con Airflow/Cloud Composer

DAG que orqueste carga de CSVs desde GCS, ejecución de dbt, validaciones y exportación a tablas de consumo.

## Explicación breve para un equipo de Producto no técnico
Imagina que tienes una gran caja de herramientas desordenada con información de clientes, compras y campañas. Lo que hicimos fue ordenar esa caja en secciones claras y etiquetadas:

Dimensiones (como un "directorio" de datos):

dim_customer: información de cada cliente (edad, ciudad, segmento de riesgo).

dim_merchant: datos de cada comercio (categoría, ubicación).

dim_campaign: datos de cada campaña (fechas, tipo).

Hechos (como un "registro de eventos"):

fact_transaction: cada compra que hicieron los clientes.

fact_campaign_event: cada interacción de un cliente con una campaña (ej: abrió un correo, hizo clic).

Tabla de conversión (nuestra "joya"):

mart_campaign_conversion: un resumen por cliente y campaña que responde de un vistazo:

¿Este cliente fue impactado? (recibió la comunicación)

¿Interactuó? (abrió o hizo clic)

¿Compró en 3 cuotas? (convirtió)

¿Cuánto gastó? ¿Cuál fue su ticket promedio?

Con esta estructura, cualquier persona del equipo de Producto o Marketing puede responder preguntas como:

"¿Cuántos clientes vieron la campaña?"

"¿Qué segmento de riesgo convirtió mejor?"

"¿Qué comercios generaron más ventas en 3 cuotas?"

Sin necesidad de escribir SQL complejo ni pedir ayuda a ingenieros de datos. Todo está listo para usar en Excel, Google Sheets o cualquier herramienta de BI.


## Consultas de Negocio (Ejemplos)
1. ¿Cuántos clientes fueron impactados?
SELECT COUNT(DISTINCT customer_id) AS impacted_clients
FROM mart_campaign_conversion
WHERE campaign_id = 'CMP2026053CSI' AND is_impacted = 1;

2. ¿Cuántos clientes interactuaron?
SELECT COUNT(DISTINCT customer_id) AS interacted_clients
FROM mart_campaign_conversion
WHERE campaign_id = 'CMP2026053CSI' AND is_interacted = 1;

3. ¿Cuántos clientes convirtieron?
SELECT COUNT(DISTINCT customer_id) AS converted_clients
FROM mart_campaign_conversion
WHERE campaign_id = 'CMP2026053CSI' AND is_converted = 1;

4. ¿Cuál fue la tasa de conversión?
SELECT 
    SAFE_DIVIDE(
        COUNT(DISTINCT CASE WHEN is_converted=1 THEN customer_id END),
        COUNT(DISTINCT CASE WHEN is_impacted=1 THEN customer_id END)
    ) * 100 AS conversion_rate
FROM mart_campaign_conversion
WHERE campaign_id = 'CMP2026053CSI';

5. ¿Qué segmentos tuvieron mejor desempeño?
SELECT 
    c.risk_segment,
    COUNT(DISTINCT CASE WHEN m.is_impacted=1 THEN m.customer_id END) AS impacted,
    COUNT(DISTINCT CASE WHEN m.is_converted=1 THEN m.customer_id END) AS converted,
    SAFE_DIVIDE(
        COUNT(DISTINCT CASE WHEN m.is_converted=1 THEN m.customer_id END),
        COUNT(DISTINCT CASE WHEN m.is_impacted=1 THEN m.customer_id END)
    ) * 100 AS conversion_rate
FROM mart_campaign_conversion m
JOIN dim_customer c ON m.customer_id = c.customer_id
WHERE m.campaign_id = 'CMP2026053CSI'
GROUP BY c.risk_segment
ORDER BY conversion_rate DESC;

6. ¿Qué comercios concentraron mayor monto en 3 cuotas?
SELECT 
    m.merchant_name,
    SUM(t.amount) AS total_amount,
    COUNT(*) AS num_transactions,
    AVG(t.amount) AS avg_ticket
FROM fact_transaction t
JOIN dim_merchant m ON t.merchant_id = m.merchant_id
WHERE t.transaction_date BETWEEN '2026-05-05' AND '2026-05-25'
  AND t.installments = 3
  AND t.transaction_status = 'approved'
GROUP BY m.merchant_name
ORDER BY total_amount DESC
LIMIT 10;
