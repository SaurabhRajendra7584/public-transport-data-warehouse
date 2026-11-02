# Project plan: Public Transport Data Warehouse

## Goal

Build a reproducible ELT warehouse that converts licensed public trip data into reliable route/service-day metrics. Keep source records auditable, make transformations testable, and bound query and storage costs.

## Scope and user outcomes

- Route reliability comparisons by date and service period.
- Ridership and fare trends, subject to source coverage and licensing.
- Reproducible, tested transformations with source-to-mart reconciliation.
- Backfills and late-arriving source corrections without duplicate facts.

## Architecture and contracts

| Stage | Technology | Contract |
|---|---|---|
| Ingest | Scheduled Python/API or transfer job | Record source URI, checksum, ingestion time, and batch ID |
| Landing | GCS raw bucket | Immutable source files partitioned by ingestion date; lifecycle policy |
| Raw access | BigQuery external table | Stable column mapping; no silent type coercion |
| Staging | dbt + BigQuery | Typed fields, normalized IDs/timestamps, duplicate and invalid-row handling |
| Mart | dbt incremental table | One row per service date and route; partitioned by date, clustered by route |
| Consumption | BigQuery views / BI | Documented KPI definitions and partition-filtered query examples |

## Metrics

- `trip_count`: accepted unique trips in the service-day/route group.
- `total_passengers`: sum of non-negative passenger counts where provided.
- `total_fare`: sum of valid fare amounts where provided.
- `average_arrival_delay_minutes`: mean actual-minus-scheduled arrival time.
- `on_time_percentage`: trips arriving no more than five minutes late divided by accepted trips.

Data source semantics determine time zone, service-day boundary, cancellation treatment, and whether passenger/fare measures are complete. Confirm these before publishing comparisons.

## Quality and operations

1. Preserve raw files and metadata; reject schema surprises rather than silently dropping columns.
2. Enforce required IDs, valid dates/times, non-negative counts/fare, and uniqueness at the documented trip grain.
3. Track rejected rows and reasons; alert when rejection or source-volume thresholds are exceeded.
4. Reconcile accepted staging row counts to mart trip totals.
5. Reprocess a bounded lookback window for late corrections; deduplicate using a stable trip key.
6. Add source freshness checks, run audit records, retries, and replayable backfills.
7. Apply least-privilege GCP IAM, secrets management, dataset-level access, and retention.

## Delivery roadmap

### Phase 1 — Local reference (included)

- [x] Dependency-free CLI with Bronze/Silver/Gold CSV outputs.
- [x] Required field/type checks, duplicate handling, delay/on-time metrics, and manifest.
- [x] Synthetic sample dataset and automated tests.

### Phase 2 — BigQuery/dbt core (included)

- [x] BigQuery external-table setup template for GCS input.
- [x] Typed/deduplicated staging model.
- [x] Incremental route/service-day mart partitioned by date and clustered by route.
- [x] dbt schema tests and project/profile configuration template.

### Phase 3 — Real source ingestion

- [ ] Select a licensed dataset (for example an official transit-agency feed) and document update cadence and field definitions.
- [ ] Implement GCS ingestion with checksums, retries, idempotency, and run metadata.
- [ ] Provision GCS/BigQuery resources and configure IAM without checked-in keys.

### Phase 4 — Reliability and insights

- [ ] Add source freshness, volume anomaly, quality, and run-failure alerts.
- [ ] Add incremental backfill/late-data tests and source-to-mart reconciliation.
- [ ] Publish route performance dashboards or reviewed SQL analyses.
- [ ] Use BigQuery query plans to tune partition filters, clustering, and cost.

### Phase 5 — Release readiness

- [ ] CI for Python tests, dbt parse/build/test, linting, and dependency checks.
- [ ] Add environment-separated dev/prod datasets, deployment approvals, and rollback steps.
- [ ] Review licensing, privacy, retention, access, cost budgets, and recovery objectives.

## Acceptance criteria

- Every local input row is either accepted once or quarantined with a clear reason.
- Route/day totals reconcile to accepted staged trips.
- dbt tests enforce uniqueness and required dimensions for the published mart.
- Incremental re-runs and late corrections do not double-count trips.
- Cost-sensitive queries filter by the service-date partition.
- Source licensing and field/time semantics are documented before public deployment.

## Decisions to make before a real deployment

- Which city/agency and data feed? What license and refresh SLA?
- What is the stable trip key, and how are cancellations/revisions represented?
- Which time zone and service-day convention should apply?
- Are passenger counts and fares consistently populated, and may they be published?
- Which dashboard, user group, freshness objective, and monthly cost ceiling are required?
