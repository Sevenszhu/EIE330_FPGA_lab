#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
export LC_ALL=C
export TZ=UTC

iverilog -g2012 -s blink_tb -o blink_tb.vvp blink.v blink_tb.v
iverilog -g2012 -s runningLED_tb -o runningLED_tb.vvp runningLED.v runningLED_tb.v

vvp blink_tb.vvp &
blink_pid=$!
vvp runningLED_tb.vvp &
running_pid=$!
wait "$blink_pid"
wait "$running_pid"

# Icarus writes the wall-clock date into every VCD header. Replace only that
# fixed-width header field in place so identical simulations hash identically.
normalize_vcd_date() {
    python3 - "$1" <<'PY'
import mmap
import sys

path = sys.argv[1]
replacement = b"\tThu Jan  1 00:00:00 1970"

with open(path, "r+b") as vcd_file:
    with mmap.mmap(vcd_file.fileno(), 0) as mapped:
        header = mapped[:4096]
        marker = b"$date\n"
        start = header.find(marker)
        if start < 0:
            raise SystemExit(f"{path}: VCD $date header not found")
        start += len(marker)
        end = header.find(b"\n$end", start)
        if end < 0:
            raise SystemExit(f"{path}: malformed VCD $date header")
        if end - start != len(replacement):
            raise SystemExit(f"{path}: unexpected VCD date field width")
        mapped[start:end] = replacement
        mapped.flush()
PY
}

normalize_vcd_date blink_tb.vcd
normalize_vcd_date runningLED_tb.vcd

sha256sum blink_tb.vcd runningLED_tb.vcd | tee SHA256SUMS
