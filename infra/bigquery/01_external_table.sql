CREATE SCHEMA IF NOT EXISTS `YOUR_GCP_PROJECT.transport_raw`
OPTIONS(location = 'US');

CREATE OR REPLACE EXTERNAL TABLE `YOUR_GCP_PROJECT.transport_raw.trips`
OPTIONS (
  format = 'CSV',
  uris = ['gs://YOUR_BUCKET/transit/raw/*.csv'],
  skip_leading_rows = 1,
  autodetect = TRUE
);
