"""Fetch historical USD exchange rates and load them into BigQuery.

Source: Frankfurter API (European Central Bank reference rates, no API key needed).
Run from the repo root:  python -m ingestion.fetch_rates
"""

import logging
import os
import time
from datetime import date

import pandas as pd
import requests
from google.cloud import bigquery

logger = logging.getLogger(__name__)

API_BASE_URL = os.getenv("FX_API_URL", "https://api.frankfurter.app")
BASE_CURRENCY = "USD"
TARGET_CURRENCIES = ("EUR", "GBP")
# The GA4 sample covers 2020-11-01 -> 2021-01-31. We start a few days earlier
# so the first days (a weekend) can be forward-filled with the last known rate.
DEFAULT_START = "2020-10-25"
DEFAULT_END = "2021-01-31"
RAW_TABLE = "raw_exchange_rates"

SCHEMA = [
    bigquery.SchemaField("rate_date", "DATE"),
    bigquery.SchemaField("base_currency", "STRING"),
    bigquery.SchemaField("currency", "STRING"),
    bigquery.SchemaField("rate", "FLOAT"),
    bigquery.SchemaField("loaded_at", "TIMESTAMP"),
]


def fetch_rates(
    start: str,
    end: str,
    base: str = BASE_CURRENCY,
    symbols: tuple[str, ...] = TARGET_CURRENCIES,
    retries: int = 3,
    backoff_seconds: float = 2.0,
) -> dict:
    """Call the API for a date range, retrying on network or HTTP errors."""
    if retries < 1:
        raise ValueError("retries must be >= 1")

    url = f"{API_BASE_URL}/{start}..{end}"
    params = {"from": base, "to": ",".join(symbols)}

    for attempt in range(1, retries + 1):
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as exc:
            if attempt == retries:
                logger.error("API call failed after %d attempts: %s", retries, exc)
                raise
            wait = backoff_seconds * attempt
            logger.warning(
                "Attempt %d/%d failed (%s), retrying in %.0fs", attempt, retries, exc, wait
            )
            time.sleep(wait)

    raise RuntimeError("Unreachable")  # keeps type checkers happy


def transform(payload: dict) -> pd.DataFrame:
    """Turn the API JSON into one row per (date, currency)."""
    rates = payload.get("rates") or {}
    if not rates:
        raise ValueError("API response contains no rates")

    base = payload["base"]
    rows = [
        {
            "rate_date": date.fromisoformat(day),
            "base_currency": base,
            "currency": currency,
            "rate": float(value),
        }
        for day, day_rates in rates.items()
        for currency, value in day_rates.items()
    ]
    df = pd.DataFrame(rows).sort_values(["rate_date", "currency"]).reset_index(drop=True)
    df["loaded_at"] = pd.Timestamp.now(tz="UTC")
    return df


def load_to_bigquery(
    df: pd.DataFrame,
    project_id: str,
    dataset: str,
    location: str = "US",
    table: str = RAW_TABLE,
) -> int:
    """Create the dataset if needed and replace the table with the DataFrame."""
    client = bigquery.Client(project=project_id, location=location)

    dataset_ref = bigquery.Dataset(f"{project_id}.{dataset}")
    dataset_ref.location = location
    client.create_dataset(dataset_ref, exists_ok=True)

    table_id = f"{project_id}.{dataset}.{table}"
    job_config = bigquery.LoadJobConfig(
        schema=SCHEMA,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()  # wait for the load job to finish

    logger.info("Loaded %d rows into %s", job.output_rows, table_id)
    return job.output_rows


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s - %(message)s",
    )

    project_id = os.getenv("GCP_PROJECT_ID")
    if not project_id:
        raise SystemExit("GCP_PROJECT_ID is not set. Load your .env first (see SETUP.md).")

    dataset = os.getenv("BQ_RAW_DATASET", "mkt_raw")
    location = os.getenv("BQ_LOCATION", "US")
    start = os.getenv("FX_START_DATE", DEFAULT_START)
    end = os.getenv("FX_END_DATE", DEFAULT_END)

    logger.info("Fetching %s rates from %s to %s", BASE_CURRENCY, start, end)
    payload = fetch_rates(start, end)
    df = transform(payload)
    logger.info("Transformed %d rows", len(df))
    load_to_bigquery(df, project_id, dataset, location)


if __name__ == "__main__":
    main()
