#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

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

python3 tests/check_movement_rom.py --code-dir code --out-dir data
python3 tests/check_maze_route.py
run_tb movement_rom_tb tests/movement_rom_tb.v code/MovementROM.v
run_tb player_movement_tb tests/player_movement_tb.v code/PosManager.v code/MovementROM.v
run_tb graphics_page_tb tests/graphics_page_tb.v code/GramManager.v code/txtPageROM.v
run_tb victory_detection_tb tests/victory_detection_tb.v code/PosManager.v code/MovementROM.v code/GramManager.v code/txtPageROM.v
run_tb vga_timing_tb tests/vga_timing_tb.v code/vga.v
run_tb vga_waveform_tb tests/vga_waveform_tb.v code/vga.v
run_tb integrated_game_tb tests/integrated_game_tb.v code/*.v
python3 tests/build_verification_summary.py
