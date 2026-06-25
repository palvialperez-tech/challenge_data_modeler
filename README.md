# Challenge Data Modeler - 3 Cuotas Sin Interés

##  Descripción del Proyecto

Este proyecto implementa una capa analítica para medir el impacto, interacción y conversión de la campaña **"3 cuotas sin interés - mayo 2026"**. El objetivo es permitir que los equipos de Producto y Marketing analicen el desempeño de la campaña de forma autónoma y confiable, utilizando un modelo de datos simple, documentado y reutilizable.

La solución está construida con **Python + DuckDB** para ejecución local, pero está pensada para ser migrada a **BigQuery** en producción.

---

## 🚀 Cómo ejecutar o revisar la solución

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

##Estructura del Proyecto

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


📋 Supuestos tomados
Definición de conversión: Un cliente se considera convertido si fue impactado (recibió al menos un sent) y realizó al menos una transacción válida en 3 cuotas (installments = 3, status = 'approved', type = 'purchase') durante la vigencia de la campaña (entre start_date y end_date).

Transacciones válidas: Solo se consideran transacciones con transaction_status = 'approved' y transaction_type = 'purchase'. Las transacciones reversed, rejected, refund y withdrawal se excluyen del análisis de conversión y montos.

Granularidad del mart: mart_campaign_conversion tiene granularidad de campaña-cliente (1 fila por cada combinación), permitiendo análisis flexibles por segmento, región o categoría de comercio.

Cliente impactado: Se considera impactado a cualquier cliente con al menos un evento sent (enviado) de la campaña.

Cliente que interactuó: Cliente con al menos un evento opened (abrió) o clicked (hizo clic).

Duplicados: En caso de duplicados en tablas fuente, se toma el registro más reciente según la fecha de creación (created_at o event_date) usando ROW_NUMBER().

Fechas futuras: Se descartan transacciones y eventos con fecha futura a la fecha de ejecución.

🏗️ Decisiones de modelado
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



