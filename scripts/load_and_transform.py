#!/usr/bin/env python3
"""
Carga automática de CSVs y ejecución de modelos SQL con DuckDB.
"""

import duckdb
import pandas as pd
from pathlib import Path
import sys
import time

# Configuración de rutas
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / "data"
SQL_DIR = BASE_DIR / "sql"
STAGING_DIR = SQL_DIR / "staging"
MARTS_DIR = SQL_DIR / "marts"
OUTPUT_DIR = BASE_DIR / "outputs"

# Crear carpeta de salida si no existe
OUTPUT_DIR.mkdir(exist_ok=True)

# Conectar a DuckDB (en memoria, o usar archivo .db si se prefiere)
con = duckdb.connect(database=':memory:')

def load_csvs():
    """Carga todos los CSVs en tablas raw_*."""
    print("📂 Cargando archivos CSV...")
    csv_files = {
        "raw_customers": DATA_DIR / "raw_customers.csv",
        "raw_accounts": DATA_DIR / "raw_accounts.csv",
        "raw_cards": DATA_DIR / "raw_cards.csv",
        "raw_transactions": DATA_DIR / "raw_transactions.csv",
        "raw_merchants": DATA_DIR / "raw_merchants.csv",
        "raw_campaigns": DATA_DIR / "raw_campaigns.csv",
        "raw_campaign_events": DATA_DIR / "raw_campaign_events.csv",
    }
    for table_name, file_path in csv_files.items():
        if not file_path.exists():
            print(f"⚠️  Archivo no encontrado: {file_path}")
            continue
        # Leer con pandas para manejar mejor los tipos, luego registrar en DuckDB
        df = pd.read_csv(file_path, dtype=str)  # leer todo como string para limpieza posterior
        con.register(table_name, df)
        # Alternativamente: con.execute(f"CREATE OR REPLACE TABLE {table_name} AS SELECT * FROM df")
        print(f"   ✅ {table_name} cargado ({len(df)} filas)")

def execute_sql_files(directory, description):
    """Ejecuta todos los archivos .sql en un directorio en orden alfabético."""
    print(f"\n🔧 Ejecutando {description}...")
    sql_files = sorted(directory.glob("*.sql"))
    if not sql_files:
        print(f"   ⚠️  No se encontraron archivos en {directory}")
        return
    for sql_file in sql_files:
        print(f"   ▶️  {sql_file.name}")
        try:
            sql = sql_file.read_text(encoding='utf-8')
            con.execute(sql)
        except Exception as e:
            print(f"      ❌ Error en {sql_file.name}: {e}")
            # Opcional: detener ejecución
            # sys.exit(1)

def export_tables():
    """Exporta las tablas finales a CSVs en la carpeta outputs."""
    print("\n💾 Exportando tablas finales...")
    tables = [
        "dim_customer",
        "dim_merchant",
        "dim_campaign",
        "fact_transaction",
        "fact_campaign_event",
        "mart_campaign_conversion",
    ]
    for table in tables:
        try:
            df = con.execute(f"SELECT * FROM {table}").df()
            output_file = OUTPUT_DIR / f"{table}.csv"
            df.to_csv(output_file, index=False)
            print(f"   ✅ {table} exportado ({len(df)} filas) -> {output_file}")
        except Exception as e:
            print(f"   ❌ Error exportando {table}: {e}")

def quality_checks():
    """Ejecuta controles de calidad básicos y los guarda en un archivo."""
    print("\n🔍 Ejecutando controles de calidad...")
    checks = [
        ("Unicidad dim_customer",
         "SELECT customer_id, COUNT(*) FROM dim_customer GROUP BY customer_id HAVING COUNT(*) > 1"),
        ("Nulos en fact_transaction.customer_id",
         "SELECT COUNT(*) FROM fact_transaction WHERE customer_id IS NULL"),
        ("Integridad referencial fact_transaction -> dim_customer",
         "SELECT COUNT(*) FROM fact_transaction t LEFT JOIN dim_customer c ON t.customer_id = c.customer_id WHERE c.customer_id IS NULL"),
        ("Montos negativos en fact_transaction",
         "SELECT COUNT(*) FROM fact_transaction WHERE amount < 0"),
        ("Fechas futuras en fact_transaction",
         "SELECT COUNT(*) FROM fact_transaction WHERE transaction_date > CAST(CURRENT_TIMESTAMP AS TIMESTAMP)"),
        ("Eventos duplicados en fact_campaign_event",
         "SELECT event_id, COUNT(*) FROM fact_campaign_event GROUP BY event_id HAVING COUNT(*) > 1"),
        ("Estados no reconocidos en fact_transaction",
         "SELECT DISTINCT transaction_status FROM fact_transaction WHERE transaction_status NOT IN ('approved','reversed','rejected','pending')"),
    ]
    quality_report = []
    for desc, query in checks:
        try:
            result = con.execute(query).df()
            value = result.iloc[0, 0] if not result.empty else 0
            quality_report.append(f"{desc}: {value}")
        except Exception as e:
            quality_report.append(f"{desc}: ERROR - {str(e)}")
    
    # Escribir con UTF-8 para soportar emojis en el archivo
    report_file = OUTPUT_DIR / "quality_report.txt"
    report_file.write_text("\n".join(quality_report), encoding='utf-8')
    print(f"   ✅ Informe de calidad guardado en {report_file}")
    
    
def main():
    start_time = time.time()
    print("🚀 Iniciando proceso de carga y transformación...")
    load_csvs()
    execute_sql_files(STAGING_DIR, "scripts de staging")
    execute_sql_files(MARTS_DIR, "scripts de marts")
    export_tables()
    quality_checks()
    elapsed = time.time() - start_time
    print(f"\n✅ Proceso completado en {elapsed:.2f} segundos.")

if __name__ == "__main__":
    main()