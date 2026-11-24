import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def rows(filename):
    with (DATA / filename).open(newline="") as handle:
        return list(csv.DictReader(handle))


def require(condition, message):
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def main():
    integrated = {row["test_id"]: row for row in rows("integrated_game_results.csv")}
    movement = rows("player_movement_cases.csv")
    movement_by_id = {row["case_id"]: row for row in movement}
    rom_static = rows("movement_static_check.csv")
    rom_sim = rows("movement_rom_sim.csv")
    vga = rows("vga_timing_results.csv")
    vga_samples = rows("vga_waveform_samples.csv")
    graphics = rows("graphics_cases.csv")
    route = rows("maze_route_results.csv")

    for test_id in ("T01", "T02", "T03", "T05", "T10", "T12", "T13"):
        require(test_id in integrated and integrated[test_id]["result"] == "PASS",
                f"{test_id} integrated result")
    require(len(rom_static) == len(rom_sim) == 64 and
            all(row["result"] == "PASS" for row in rom_static + rom_sim),
            "T04 ROM checks")
    require(movement_by_id["2"]["result"] == "PASS" and
            movement_by_id["2"]["final_pos"] == "1", "T06 wall collision")
    require(all(movement_by_id[index]["result"] == "PASS" and
                movement_by_id[index]["final_pos"] == expected
                for index, expected in (("3", "0"), ("4", "0"),
                                        ("5", "7"), ("6", "56"))),
            "T07 boundary checks")
    require(len(vga) == 10 and all(row["result"] == "PASS" for row in vga),
            "T08 VGA timing")
    require(any(row["pixel_index"] == "420000" and
                row["h_count"] == row["v_count"] == "0"
                for row in vga_samples), "T08 VGA frame-wrap waveform")
    require(len(graphics) >= 6 and
            all(row["result"] == "PASS" and row["rgb"] == row["expected_rgb"]
                for row in graphics), "T09 RGB output")
    require(len(route) == 1 and route[0]["result"] == "PASS" and
            route[0]["route_length"] == route[0]["shortest_length"] == "26" and
            route[0]["final_position"] == "63", "T11 shortest route")

    summary = [
        ("T01", "Reset", "Initial state restored", "data/integrated_game_results.csv"),
        ("T02", "Button debounce", "No repeated accepted input", "data/integrated_game_trace.csv"),
        ("T03", "Button priority", "One selected direction", "data/integrated_game_results.csv"),
        ("T04", "ROM consistency", "All 64 cells match", "data/movement_static_check.csv; data/movement_rom_sim.csv"),
        ("T05", "Valid movement", "Position updated", "data/integrated_game_trace.csv"),
        ("T06", "Wall collision", "Position unchanged", "data/player_movement_cases.csv"),
        ("T07", "Boundary protection", "No coordinate overflow", "data/player_movement_cases.csv"),
        ("T08", "VGA timing", "Correct timing counts", "data/vga_timing_results.csv; data/vga_waveform_samples.csv"),
        ("T09", "RGB output", "Correct pixel color", "data/graphics_cases.csv"),
        ("T10", "Page transition", "Correct page sequence", "data/integrated_game_trace.csv"),
        ("T11", "Maze solvability", "A valid shortest route exists", "data/maze_route_results.csv"),
        ("T12", "Victory detection", "Win signal asserted", "data/integrated_game_trace.csv"),
        ("T13", "Position reset", "Return to (0,0)", "data/integrated_game_trace.csv"),
    ]
    with (DATA / "verification_summary.csv").open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(("Test ID", "Test Function", "Expected Result", "Result", "Evidence"))
        writer.writerows((test_id, function, expected, "Pass", evidence)
                         for test_id, function, expected, evidence in summary)
    print("PASS: verification summary contains 13 checked results")


if __name__ == "__main__":
    main()
