"""Check every movement nibble against the maze map and write test vectors."""

import argparse
import csv
import re
from pathlib import Path


def read_constants(code_dir: Path):
    graphics = (code_dir / "GramManager.v").read_text(encoding="utf-8")
    rom = (code_dir / "MovementROM.v").read_text(encoding="utf-8")
    match = re.search(r"MAZE_MAP\s*=\s*64'h([0-9a-fA-F]+)", graphics)
    if match is None:
        raise ValueError("MAZE_MAP constant not found")
    maze_map = int(match.group(1), 16)
    rows = {int(row): int(value, 16) for value, row in
            re.findall(r"32'h([0-9a-fA-F]+)\s*,?\s*//\s*y=(\d)", rom)}
    if set(rows) != set(range(8)):
        raise ValueError("Movement table must contain rows y=0..7")
    return maze_map, rows


def expected_for_cell(maze_map: int, x: int, y: int) -> int:
    def path(nx: int, ny: int) -> bool:
        return 0 <= nx < 8 and 0 <= ny < 8 and bool((maze_map >> (8 * ny + nx)) & 1)

    if not path(x, y):
        return 0
    return (8 * path(x, y - 1) + 4 * path(x, y + 1)
            + 2 * path(x - 1, y) + path(x + 1, y))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--code-dir", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path,
                        default=Path(__file__).resolve().parents[1] / "data")
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    maze_map, rows = read_constants(args.code_dir)

    records = []
    expected_values = []
    for y in range(8):
        for x in range(8):
            actual = (rows[y] >> (4 * x)) & 0xF
            expected = expected_for_cell(maze_map, x, y)
            expected_values.append(expected)
            records.append((x, y, 4 * (8 * y + x), format(actual, "04b"),
                            format(expected, "04b"), "PASS" if actual == expected else "FAIL"))

    with (args.out_dir / "movement_static_check.csv").open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(("x", "y", "address", "rom_bits", "map_expected_bits", "result"))
        writer.writerows(records)
    (args.out_dir / "expected_movement.hex").write_text(
        "".join(f"{value:x}\n" for value in expected_values), encoding="ascii")

    failures = [row for row in records if row[-1] != "PASS"]
    print(f"Static map/table agreement: {64 - len(failures)}/64 cells")
    for x, y in ((0, 0), (1, 0), (1, 1), (7, 7)):
        row = records[8 * y + x]
        print(f"({x},{y}): address={row[2]}, ROM={row[3]}, expected={row[4]}")
    if failures:
        raise SystemExit(f"Mismatch at: {[(row[0], row[1]) for row in failures]}")


if __name__ == "__main__":
    main()
