"""Daily marketing pipeline: ingest exchange rates, then build and test dbt models."""

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

VENV_BIN = "/opt/airflow/pipeline_venv/bin"
PROJECT_DIR = "/opt/airflow/project"
DBT_DIR = f"{PROJECT_DIR}/dbt_project"
DBT_ARGS = "--profiles-dir . --target ${DBT_TARGET:-dev}"

default_args = {
    "owner": "kenza",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="marketing_pipeline",
    description="Exchange rates ingestion + dbt transformations on GA4 e-commerce data",
    default_args=default_args,
    schedule="@daily",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["marketing", "dbt", "bigquery"],
):
    ingest_exchange_rates = BashOperator(
        task_id="ingest_exchange_rates",
        bash_command=f"cd {PROJECT_DIR} && {VENV_BIN}/python -m ingestion.fetch_rates",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"cd {DBT_DIR} && {VENV_BIN}/dbt run {DBT_ARGS}",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_DIR} && {VENV_BIN}/dbt test {DBT_ARGS}",
    )

    ingest_exchange_rates >> dbt_run >> dbt_test
