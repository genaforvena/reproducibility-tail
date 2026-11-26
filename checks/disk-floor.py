#!/usr/bin/env python3
"""Disk detector for the spare drive this plant works on.

Exit 0 GREEN, 2 RED, anything else is a failed observation (UNKNOWN).
RED when the spare drive has under FLOOR_GIB free, or the plant's own scratch tree
is over CAP_GIB. The drive also holds swap and the host guard's /var/tmp probe, so
the plant must never be what fills it.
"""
import os
import shutil
import sys

DRIVE = "/mnt/mishe-scratch"
SCRATCH = "/mnt/mishe-scratch/reproducibility-tail"
FLOOR_GIB = 60
CAP_GIB = 20


def tree_bytes(path: str) -> int:
    total = 0
    for root, _dirs, files in os.walk(path):
        for name in files:
            try:
                total += os.lstat(os.path.join(root, name)).st_size
            except OSError:
                pass
    return total


def main() -> int:
    if not os.path.ismount(DRIVE):
        print(f"{DRIVE} is not a mountpoint", file=sys.stderr)
        return 3
    free = shutil.disk_usage(DRIVE).free / 2**30
    used = tree_bytes(SCRATCH) / 2**30 if os.path.isdir(SCRATCH) else 0.0
    print(f"free={free:.1f}GiB floor={FLOOR_GIB} scratch={used:.2f}GiB cap={CAP_GIB}")
    return 2 if free < FLOOR_GIB or used > CAP_GIB else 0


if __name__ == "__main__":
    sys.exit(main())
