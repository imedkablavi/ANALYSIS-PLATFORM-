#!/usr/bin/env python3
"""Streaming provenance/label audit; no detector or MATLAB execution."""
import argparse
import collections
import csv
import datetime as dt
import hashlib
import json
from pathlib import Path

from network_flow_reference import label_ctu13

REQUIRED = {'StartTime', 'Dur', 'Proto', 'SrcAddr', 'Sport', 'Dir', 'DstAddr',
            'Dport', 'State', 'TotPkts', 'TotBytes', 'Label'}
CLASSES = ('malicious', 'benign', 'unknown')


def audit_capture(path, source_url='', min_events=3):
    """Read bounded byte chunks and CSV rows; retain only host counters in memory."""
    path = Path(path)
    if min_events < 1:
        raise ValueError('min_events must be positive')
    size = path.stat().st_size
    sha256 = hashlib.sha256()
    git = hashlib.sha1(f'blob {size}\0'.encode())
    with path.open('rb') as stream:
        while chunk := stream.read(1024 * 1024):
            sha256.update(chunk)
            git.update(chunk)
    labels = collections.Counter({k: 0 for k in CLASSES})
    events, malicious, benign = (collections.Counter() for _ in range(3))
    n_rows = invalid = missing = dropped = accepted = 0
    tmin = tmax = None
    with path.open(newline='', encoding='utf-8-sig') as stream:
        header = stream.readline()
        stream.seek(0)
        reader = csv.DictReader(stream, delimiter='\t' if '\t' in header else ',')
        if reader.fieldnames is None:
            raise ValueError('Capture is empty or has no header')
        reader.fieldnames = [name.strip() for name in reader.fieldnames]
        if len(set(reader.fieldnames)) != len(reader.fieldnames):
            raise ValueError('Duplicate column names')
        if REQUIRED - set(reader.fieldnames):
            raise ValueError('Missing required columns: ' + ', '.join(sorted(REQUIRED - set(reader.fieldnames))))
        for row in reader:
            n_rows += 1
            if None in row or any(value is None for value in row.values()):
                raise ValueError(f'Malformed record at data row {n_rows}')
            row = {key: value.strip() for key, value in row.items()}
            value = row['StartTime']
            if not value:
                missing += 1
            else:
                try:
                    time = dt.datetime.strptime(value, '%Y/%m/%d %H:%M:%S.%f')
                except ValueError:
                    invalid += 1
                else:
                    tmin = time if tmin is None else min(tmin, time)
                    tmax = time if tmax is None else max(tmax, time)
            cls, role = label_ctu13(row['Label'])
            labels[cls] += 1
            src, dst = row['SrcAddr'], row['DstAddr']
            if not src or not dst:
                dropped += 1
                continue
            accepted += 1
            events[src] += 1
            if src != dst:
                events[dst] += 1
            host = dst if role == 'dst' else src
            if cls == 'malicious':
                malicious[host] += 1
            elif cls == 'benign':
                benign[host] += 1
    if n_rows == 0:
        raise ValueError('Capture contains no data records')
    truth = collections.Counter({k: 0 for k in CLASSES})
    eligible = collections.Counter({k: 0 for k in CLASSES})
    for host, count in events.items():
        cls = 'malicious' if malicious[host] else 'benign' if benign[host] else 'unknown'
        truth[cls] += 1
        if count >= min_events:
            eligible[cls] += 1
    return {
        'audit_kind': 'independent_streaming_provenance_and_labels',
        'detector_executed': False, 'matlab_executed': False,
        'source_url': source_url, 'file_name': path.name, 'size_bytes': size,
        'sha256': sha256.hexdigest(), 'git_blob_sha1': git.hexdigest(),
        'row_count': n_rows, 'accepted_flow_count': accepted,
        'missing_endpoint_rows': dropped,
        'timestamps': {'minimum': tmin.isoformat() if tmin else None,
                       'maximum': tmax.isoformat() if tmax else None,
                       'missing': missing, 'invalid': invalid},
        'flow_class_counts_all_rows': dict(labels), 'host_count': len(events),
        'host_truth_counts': dict(truth), 'minimum_incident_events': min_events,
        'eligible_host_count': sum(eligible.values()),
        'eligible_host_truth_counts': dict(eligible),
        'label_rule': 'CTU-13 Botnet/Normal; To- labels attribute destination; malicious overrides benign; Background remains unknown',
        'timestamp_scope': 'all source rows; host counts exclude records missing either endpoint',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('file', type=Path)
    parser.add_argument('--source-url', default='')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = audit_capture(args.file, args.source_url)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
