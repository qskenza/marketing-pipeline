# Airflow image with our pipeline dependencies in a separate virtualenv
# (keeps dbt/BigQuery libraries from conflicting with Airflow's own packages).
FROM apache/airflow:2.10.5-python3.11

COPY requirements.txt /tmp/requirements.txt

# PIP_USER=false is needed: the Airflow image sets PIP_USER=true, which breaks venv installs.
RUN python -m venv /opt/airflow/pipeline_venv \
    && PIP_USER=false /opt/airflow/pipeline_venv/bin/pip install --no-cache-dir \
       -r /tmp/requirements.txt
