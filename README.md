# Public Transport Data Warehouse

A portfolio-ready ELT project for turning public-transport trip records into tested route and service-day analytics. It includes a local, dependency-free reference pipeline, a dbt warehouse project for BigQuery, and a detailed delivery roadmap.

## What it answers

- Which routes have the highest arrival delays?
- What share of trips arrive within five minutes of schedule?
- How do trip volume, passenger counts, and service reliability change by day?

## Architecture

```text
Licensed public CSV / API
          |
          v
Google Cloud Storage (immutable raw files, date-partitioned)
          |
          v
BigQuery external/raw table --> dbt staging + quality tests
                                      |
                                      v
                           incremental route/day mart
                           (partitioned, clustered)
                                      |
                                      v
                         BI / scheduled SQL analysis
```

The local Python runner demonstrates the same contract and business metrics without requiring Google Cloud credentials.

## Quick start (local)

Requires Python 3.10 or newer; no third-party packages are needed.

```powershell
python -m pipeline run --input data\sample\trips.csv --output data\output
python -m unittest discover -s tests -v
```

Outputs:

- `bronze/trips.csv` — preserved copy of the input.
- `silver/trips.csv` — normalized, validated trips and calculated arrival delay.
- `silver/rejected.csv` — rejected rows with source row and validation reason.
- `gold/route_service_daily.csv` — daily route KPIs.
- `manifest.json` — run ID and source/accepted/rejected/aggregate counts.

The demo data is synthetic. Select and document a licensed public source before a real ingestion; no production dataset or Google Cloud project is included.

## Run dbt on BigQuery

Requirements: a configured Google Cloud project, billing, BigQuery permissions, and dbt with the BigQuery adapter.

1. Copy `profiles.yml.example` to `~/.dbt/profiles.yml` and set your project, dataset, and location.
2. Create the raw external table using `infra/bigquery/01_external_table.sql`, replacing the sample GCS URI and table names.
3. Install project dependencies and run:

```powershell
python -m pip install dbt-bigquery
dbt debug --project-dir dbt
dbt test --project-dir dbt
dbt build --project-dir dbt
```

Credentials should come from Application Default Credentials or a supported secure profile method; never put service-account keys in this repository.

## Project layout

```text
pipeline/                    Standard-library local reference ETL
tests/                       Unit and end-to-end tests
data/sample/                 Synthetic example trips
dbt/models/staging/          Typed trips and an invalid-row review model
dbt/models/marts/            Incremental route/day fact table
dbt/models/schema.yml        dbt data-quality tests and documentation
infra/bigquery/              Raw external table setup
docs/PROJECT_PLAN.md         Detailed requirements, phases, and acceptance criteria
```

## Data model

The mart grain is one row per `service_date` and `route_id`. It includes trip count, total passengers, total fare, average arrival delay, on-time trip count, and on-time percentage. On-time is defined as arrival delay <= 5 minutes. An overnight arrival belongs to the service date on which the trip departed.

## Ideal project roadmap

1. Choose a licensed, stable public dataset and record its schema, refresh cadence, license, and service-day/time-zone semantics.
2. Land original files in GCS with source URL, ingestion timestamp, checksum, and date/run partition; make ingestion idempotent.
3. Expose raw files as BigQuery external tables, then materialize typed dbt staging models.
4. Add dbt tests for required values, valid ranges, uniqueness, accepted route keys, and source-to-mart reconciliation.
5. Build incremental, date-partitioned and route-clustered marts, with a documented late-arriving-data window.
6. Publish dashboards or saved SQL queries for punctuality, volume, ridership, and fare trends.
7. Add freshness/failure alerts, cost budgets, CI, access controls, retention, and replay/backfill procedures.

## Privacy, licensing, and costs

Only synthetic records are checked in. Verify the source license and remove personal or vehicle-identifying information where required. BigQuery and GCS are paid services; use partition filters, dry runs, budget alerts, and lifecycle rules.

## License

MIT. See [LICENSE](LICENSE).
