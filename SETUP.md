# Setup guide: from zero to a running pipeline

Follow the steps in order. Commands are given for **macOS/Linux (bash/zsh)** and
**Windows (PowerShell)** when they differ. Commit your work after each step.

Tip: open this file in VS Code with **Ctrl+Shift+V** (Cmd+Shift+V on Mac) to read it
side by side with the terminal.

---

## Step 0 — Install the tools (once)

| Tool | Where | Check it works |
|---|---|---|
| Python **3.11** | python.org/downloads (Windows: tick "Add to PATH") | `python --version` |
| VS Code | code.visualstudio.com | — |
| Git | git-scm.com | `git --version` |
| Docker Desktop | docker.com/products/docker-desktop (start it after install) | `docker --version` |
| Google Cloud CLI | cloud.google.com/sdk/docs/install | `gcloud --version` |

You also need a GitHub account (you have: `qskenza`) and a Google account.

---

## Step 1 — Open the project in VS Code

1. Unzip `marketing-pipeline.zip` somewhere simple, e.g. `Documents/code/marketing-pipeline`.
2. VS Code → **File → Open Folder…** → select `marketing-pipeline`.
3. A popup offers to install the **recommended extensions** → click **Install All**
   (Python, Ruff, Docker, dbt Power User, YAML, GitHub Actions).
4. Open the integrated terminal: **Terminal → New Terminal** (or Ctrl+`).
   All commands below run in this terminal, from the project root.

---

## Step 2 — Google Cloud project

### 2.1 Create the project (in the browser)
1. Go to **console.cloud.google.com**.
2. Activate the **free trial** ($300 of credits for 90 days) — recommended.
   The BigQuery *sandbox* (no card) also works, but tables expire after 60 days.
3. Top bar → project selector → **New project** → name it `marketing-pipeline`.
4. Write down the **Project ID** (e.g. `marketing-pipeline-472315`). You'll use it everywhere.

### 2.2 Create a service account + key (in the VS Code terminal)
Replace `YOUR_PROJECT_ID` with your real Project ID in each command.

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable bigquery.googleapis.com

gcloud iam service-accounts create pipeline-sa --display-name="Marketing pipeline"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:pipeline-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID --member="serviceAccount:pipeline-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" --role="roles/bigquery.jobUser"

mkdir keys
gcloud iam service-accounts keys create keys/gcp-key.json --iam-account=pipeline-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

⚠️ `keys/` is in `.gitignore`. **Never** commit this file or paste it anywhere public.

---

## Step 3 — Python environment and `.env`

### 3.1 Virtual environment
macOS/Linux:
```bash
python3.11 -m venv .venv
source .venv/bin/activate
```
Windows (PowerShell):
```powershell
py -3.11 -m venv .venv
.venv\Scripts\Activate.ps1
```
If PowerShell blocks the script: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, then retry.

You should now see `(.venv)` at the start of the terminal line.
In VS Code: **Ctrl+Shift+P → "Python: Select Interpreter"** → choose `.venv`.

### 3.2 Install dependencies
```bash
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
```

### 3.3 Create your `.env`
macOS/Linux: `cp .env.example .env`  —  Windows: `Copy-Item .env.example .env`

Open `.env` in VS Code and fill in:
- `GCP_PROJECT_ID` → your Project ID
- `GOOGLE_APPLICATION_CREDENTIALS` → the **absolute** path to `keys/gcp-key.json`
  (right-click the file in VS Code's explorer → **Copy Path**; on Windows use `/` instead of `\`)

### 3.4 Load `.env` into the terminal
Do this **every time you open a new terminal**:

macOS/Linux: `source scripts/load_env.sh`  —  Windows: `. .\scripts\load_env.ps1`

---

## Step 4 — Explore the data (Phase 1)

1. Open `analysis/exploration.sql` in VS Code.
2. Go to **console.cloud.google.com/bigquery**, open a new query tab.
3. Copy/paste each query, run it, and read the results. Understand:
   - what an *event* is, which event types exist
   - how `event_params` (nested array) is read with `UNNEST`
   - the numbers of events/users (note them for your CV line)
4. In `README.md`, adjust the 4 business questions if you want.

```bash
git init
git add .
git commit -m "Project skeleton and data exploration"
```
(Before committing, run `git status` and check that **`.env` and `keys/` are NOT listed**.)

---

## Step 5 — Ingestion (Python)

1. Read `ingestion/fetch_rates.py` and `tests/test_fetch_rates.py` — make sure you
   understand every function (you'll be asked about it in interviews).
2. Lint and test:
```bash
ruff check .
pytest -v
```
   You can also run the tests from the VS Code **Testing** panel (flask icon on the left).
3. Run the ingestion for real:
```bash
python -m ingestion.fetch_rates
```
4. Check in the BigQuery console: dataset **`mkt_raw`** → table **`raw_exchange_rates`** → Preview.

```bash
git add . && git commit -m "Add exchange rate ingestion with tests"
```

---

## Step 6 — dbt transformations

```bash
cd dbt_project
dbt debug --profiles-dir .          # must end with "All checks passed!"
dbt build --profiles-dir . --target dev   # runs the 8 models + 27 tests
```
Check in BigQuery: a new dataset **`mkt_dev`** with your models.

Useful commands:
```bash
dbt run  --profiles-dir . -s fct_orders          # run a single model
dbt build --profiles-dir . -s +fct_orders        # a model and everything upstream
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .                  # opens the docs + lineage graph
```
In the docs site, click the blue **lineage** icon (bottom right) → take a **screenshot**
for your README. Stop the server with Ctrl+C, then go back to the root:
```bash
cd ..
git add . && git commit -m "Add dbt models and tests"
```

**Practice:** add one model yourself, e.g. `mart_top_products` (you'll need the `items`
array from GA4 and `UNNEST(items)`). This is what you'll talk about in interviews.

---

## Step 7 — Docker

Docker Desktop must be running.
```bash
docker build -t marketing-pipeline .
docker run --rm --env-file .env -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcp-key.json -v "${PWD}/keys/gcp-key.json:/secrets/gcp-key.json:ro" marketing-pipeline
```
(`${PWD}` works in both bash and PowerShell.) You should see the 2 steps finish with
"Pipeline finished successfully".

```bash
git add . && git commit -m "Dockerize the pipeline"
```

---

## Step 8 — Airflow

```bash
docker compose up --build -d
```
The first build takes a few minutes. Then get the admin password:
```bash
docker compose exec airflow cat /opt/airflow/standalone_admin_password.txt
```
1. Open **http://localhost:8080** → user `admin` + that password.
2. Find the DAG **`marketing_pipeline`** → toggle it **on** → click ▶ **Trigger DAG**.
3. Open **Graph** view: the 3 tasks should turn green. Click a task → **Logs** to see output.
4. Take a **screenshot** of the successful run.

Useful commands:
```bash
docker compose logs -f airflow     # see logs (Ctrl+C to quit)
docker compose down                # stop Airflow when you're done
```
```bash
git add . && git commit -m "Add Airflow orchestration"
```

---

## Step 9 — GitHub + CI/CD

### 9.1 Create the repo and secrets FIRST
1. github.com → **New repository** → name `marketing-pipeline`, **Public**, no README.
2. Repo → **Settings → Secrets and variables → Actions → New repository secret**:
   - `GCP_PROJECT_ID` → your Project ID
   - `GCP_SA_KEY` → open `keys/gcp-key.json` in VS Code, copy **the whole content**, paste

### 9.2 Push
```bash
git branch -M main
git remote add origin https://github.com/qskenza/marketing-pipeline.git
git push -u origin main
```
Go to the **Actions** tab: the **Deploy** workflow runs (ingestion + dbt on `mkt_prod`,
then publishes the Docker image to GitHub Packages).

### 9.3 Protect `main` and work like a team
1. **Settings → Branches → Add branch protection rule** (or **Rules → Rulesets**) on `main`:
   require a pull request and require status checks to pass (select the CI jobs).
2. From now on, work on branches:
```bash
git checkout -b feature/top-products
# ... make changes ...
git add .
git commit -m "Add top products mart"
git push -u origin feature/top-products
```
3. On GitHub, open a **Pull Request** → CI runs (ruff, pytest, dbt build on `mkt_ci`) →
   merge when green → Deploy runs automatically.
4. Back locally: `git checkout main && git pull`.

---

## Step 10 — Looker Studio dashboard

1. **lookerstudio.google.com** → **Create → Report** → connector **BigQuery**.
2. Select your project → dataset **`mkt_prod`** → `mart_channel_performance`.
3. Add charts: bar chart revenue_eur by channel, table with conversion_rate and
   avg_order_value_eur.
4. **Add data** → `mart_funnel_conversion`: funnel or bar chart of the step rates,
   with a filter control on `device_category`.
5. Share → **Anyone with the link can view**. Put the link and a screenshot in the README.

---

## Step 11 — Showcase

1. Fill the **Key insights** and **Screenshots** sections of `README.md` (screenshots in a `docs/` folder).
2. Add the project to **qskenza.github.io** and to your Data Engineer CV, e.g.:
   *"Built an end-to-end GCP marketing pipeline (Python, BigQuery, dbt, Airflow, Docker,
   GitHub Actions) processing X M e-commerce events"* — use the real number from Step 4.
3. Prepare a 2-minute oral pitch: problem → architecture → one insight → what you'd do next.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `GCP_PROJECT_ID is not set` | You opened a new terminal: reload `.env` (Step 3.4) |
| `dbt debug` fails on keyfile | `GOOGLE_APPLICATION_CREDENTIALS` must be an **absolute** path |
| `Access Denied` in BigQuery | Check both IAM roles from Step 2.2 are granted |
| `Not found: Dataset ...mkt_raw` in dbt | Run the ingestion (Step 5) first |
| `Cannot read and write in different locations` | All datasets must be in **US** (same as the GA4 public data) |
| Key creation blocked by an organization policy | Create the project under "No organization" |
| Airflow mounts a folder instead of the key | `keys/gcp-key.json` didn't exist when you started: `docker compose down`, create the key, restart |
| `bad interpreter` / `\r` error in Docker | The `.sh` file got Windows line endings: in VS Code, bottom-right click `CRLF` → `LF`, save |
| CI fails on `dbt build` | Check the two GitHub secrets, and that `mkt_raw` exists (run the ingestion once) |

Costs: the GA4 sample is small; you stay far below BigQuery's free 1 TB of queries per month.
