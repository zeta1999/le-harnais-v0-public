#!/bin/bash
python3 - << 'PY'
from ranges import merge

def check(intervals, want):
    got = merge(intervals)
    if got != want:
        raise SystemExit(f"FAIL {intervals}: got {got}, want {want}")

check([], [])
check([[1, 1]], [[1, 1]])
check([[1, 3], [2, 4]], [[1, 4]])
check([[1, 5], [2, 3]], [[1, 5]])
check([[5, 6], [1, 2]], [[1, 2], [5, 6]])
check([[1, 2], [3, 4], [5, 6]], [[1, 6]])
check([[1, 2], [4, 5]], [[1, 2], [4, 5]])
print("ok")
PY
