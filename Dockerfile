# Image that runs the full pipeline once: ingestion -> dbt build
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ingestion/ ingestion/
COPY dbt_project/ dbt_project/
COPY scripts/run_pipeline.sh .
RUN chmod +x run_pipeline.sh

# The GCP key is NOT baked into the image: mount it at runtime.
CMD ["./run_pipeline.sh"]
