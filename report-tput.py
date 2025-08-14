#!/usr/bin/env python3

# Extracts throughputs and summarizes them from a set of kvs server logs.
# Mostly thrown together with Claude from a draft awk script.

import os
import glob
import statistics

LOG_DIR = "./logs/latest"

total_throughput = 0.0

# Find all matching log files
log_files = sorted(glob.glob(os.path.join(LOG_DIR, "kvsserver-*.log")))

if not log_files:
    print("No matching log files found.")
    exit(0)

for log_path in log_files:
    node = os.path.basename(log_path).removeprefix("kvsserver-").removesuffix(".log")
    throughputs = []
    with open(log_path) as f:
        for line in f:
            if "ops/s" in line:
                parts = line.strip().split()
                try:
                    # Throughput value is the 2nd column in original awk ($2)
                    throughputs.append(float(parts[1]))
                except (IndexError, ValueError):
                    pass
    if throughputs:
        median_val = statistics.median(sorted(throughputs))
        print(f"{node} median {median_val:.0f} op/s")
        total_throughput += median_val
    else:
        print(f"{node} no ops/s data found")

print()
print(f"total {total_throughput:.0f} op/s")
