#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p data/results data/traces data/waveforms data/reference

run_tb() {
    local name="$1"
    shift
    local output
    iverilog -g2005 -s "$name" -o "/tmp/${name}_verify.out" "$@"
    output="$(vvp "/tmp/${name}_verify.out")"
    printf '%s\n' "$output"
    if [[ "$output" != *"PASS:"* ]]; then
        printf 'FAIL: %s did not report a completed test\n' "$name" >&2
        exit 1
    fi
}

python3 tests/scripts/check_movement_rom.py --code-dir code --out-dir data
python3 tests/scripts/check_maze_route.py
run_tb movement_rom_tb tests/testbenches/movement_rom_tb.v code/MovementROM.v
run_tb player_movement_tb tests/testbenches/player_movement_tb.v code/PosManager.v code/MovementROM.v
run_tb graphics_page_tb tests/testbenches/graphics_page_tb.v code/GramManager.v code/txtPageROM.v
run_tb victory_detection_tb tests/testbenches/victory_detection_tb.v code/PosManager.v code/MovementROM.v code/GramManager.v code/txtPageROM.v
run_tb vga_timing_tb tests/testbenches/vga_timing_tb.v code/vga.v
run_tb vga_waveform_tb tests/testbenches/vga_waveform_tb.v code/vga.v
run_tb integrated_game_tb tests/testbenches/integrated_game_tb.v code/*.v
python3 tests/scripts/build_verification_summary.py
