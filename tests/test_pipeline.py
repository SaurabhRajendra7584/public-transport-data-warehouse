import csv
import tempfile
import unittest
from pathlib import Path

from pipeline.core import transform

ROOT = Path(__file__).resolve().parents[1]


class PipelineTests(unittest.TestCase):
    def test_sample_batch_creates_reconciled_route_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "output"
            manifest = transform(ROOT / "data" / "sample" / "trips.csv", output)

            self.assertEqual(manifest["input_rows"], 5)
            self.assertEqual(manifest["accepted_rows"], 4)
            self.assertEqual(manifest["rejected_rows"], 1)
            with (output / "gold" / "route_service_daily.csv").open(
                newline="", encoding="utf-8"
            ) as source:
                gold = list(csv.DictReader(source))
            self.assertEqual(gold[0]["trip_count"], "3")
            self.assertEqual(gold[0]["total_passengers"], "50")
            self.assertEqual(gold[0]["on_time_percentage"], "66.67")

    def test_overnight_arrival_delay_is_calculated_across_midnight(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "trips.csv"
            source.write_text(
                "trip_id,service_date,route_id,scheduled_departure,actual_departure,"
                "scheduled_arrival,actual_arrival,passenger_count,fare_amount\n"
                "N001,2025-01-15,N1,23:50,23:55,00:10,00:25,4,2.50\n",
                encoding="utf-8",
            )
            transform(source, root / "output")

            with (root / "output" / "silver" / "trips.csv").open(
                newline="", encoding="utf-8"
            ) as silver_file:
                row = next(csv.DictReader(silver_file))
            self.assertEqual(row["arrival_delay_minutes"], "15")


if __name__ == "__main__":
    unittest.main()
