import csv
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts/reference'))
from audit_network_capture import audit_capture, REQUIRED


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'capture.binetflow'

    def write(self, records):
        names = sorted(REQUIRED)
        with self.path.open('w', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=names)
            writer.writeheader()
            for record in records:
                row = dict.fromkeys(names, '')
                row.update(record)
                writer.writerow(row)

    def test_counts_roles_self_missing_and_hashes(self):
        self.write([
            dict(StartTime='bad', SrcAddr='private-A', DstAddr='private-B', Label='flow=To-Botnet'),
            dict(StartTime='', SrcAddr='private-B', DstAddr='private-B', Label='flow=From-Normal'),
            dict(StartTime='2011/08/16 10:00:00.123456', SrcAddr='private-A', DstAddr='private-B', Label='flow=Background'),
            dict(StartTime='2011/08/16 09:00:00.000000', SrcAddr='private-C', DstAddr='private-A', Label='flow=From-Normal'),
            dict(StartTime='', SrcAddr='dropped-private', DstAddr='', Label='flow=From-Botnet'),
        ])
        r = audit_capture(self.path)
        self.assertEqual(r['row_count'], 5)
        self.assertEqual(r['accepted_flow_count'], 4)
        self.assertEqual(r['missing_endpoint_rows'], 1)
        self.assertEqual(r['flow_class_counts_all_rows'], dict(malicious=2, benign=2, unknown=1))
        self.assertEqual(r['host_truth_counts'], dict(malicious=1, benign=1, unknown=1))
        self.assertEqual(r['eligible_host_count'], 2)
        self.assertEqual(r['eligible_host_truth_counts'], dict(malicious=1, benign=0, unknown=1))
        self.assertEqual(r['timestamps']['invalid'], 1)
        self.assertEqual(r['timestamps']['missing'], 2)
        self.assertEqual(r['timestamps']['minimum'], '2011-08-16T09:00:00')
        self.assertEqual(r['timestamps']['maximum'], '2011-08-16T10:00:00.123456')
        data = self.path.read_bytes()
        self.assertEqual(r['sha256'], hashlib.sha256(data).hexdigest())
        self.assertEqual(r['git_blob_sha1'], hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest())
        self.assertNotIn('private', str(r))
        self.assertFalse(r['detector_executed'])

    def test_self_flow_is_one_event(self):
        self.write([dict(SrcAddr='A', DstAddr='A')] * 2)
        r = audit_capture(self.path)
        self.assertEqual(r['host_count'], 1)
        self.assertEqual(r['eligible_host_count'], 0)

    def test_empty_header_only_missing_and_malformed(self):
        for content in ['', 'SrcAddr,DstAddr\nA,B\n', ','.join(sorted(REQUIRED)) + '\n',
                        ','.join(sorted(REQUIRED)) + '\nA\n']:
            with self.subTest(content=content):
                self.path.write_text(content)
                with self.assertRaises(ValueError):
                    audit_capture(self.path)


if __name__ == '__main__':
    unittest.main()
