import csv
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
ROUTE = "RRRRDDLDLDLDDDRRURUURRDDDR"
DELTAS = {"R": (1, 0, 0b0001), "L": (-1, 0, 0b0010),
          "D": (0, 1, 0b0100), "U": (0, -1, 0b1000)}


def neighbor(position, direction, movement):
    x, y = position % 8, position // 8
    dx, dy, bit = DELTAS[direction]
    nx, ny = x + dx, y + dy
    if not (movement[position] & bit) or not (0 <= nx < 8 and 0 <= ny < 8):
        return None
    return 8 * ny + nx


def shortest_length(movement):
    queue = deque([(0, 0)])
    visited = {0}
    while queue:
        position, distance = queue.popleft()
        if position == 63:
            return distance
        for direction in DELTAS:
            next_position = neighbor(position, direction, movement)
            if next_position is not None and next_position not in visited:
                visited.add(next_position)
                queue.append((next_position, distance + 1))
    return None


def main():
    movement = [int(line, 16) for line in
                (DATA / "expected_movement.hex").read_text().splitlines()]
    if len(movement) != 64:
        raise ValueError("Expected movement data for 64 cells")

    position = 0
    records = []
    for step, direction in enumerate(ROUTE, 1):
        next_position = neighbor(position, direction, movement)
        if next_position is None:
            raise ValueError(f"Route is blocked at step {step}")
        records.append((step, direction, position % 8, position // 8,
                        next_position % 8, next_position // 8, "PASS"))
        position = next_position

    shortest = shortest_length(movement)
    passed = position == 63 and len(ROUTE) == shortest == 26
    with (DATA / "maze_route_trace.csv").open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(("step", "direction", "from_x", "from_y",
                         "to_x", "to_y", "result"))
        writer.writerows(records)
    with (DATA / "maze_route_results.csv").open("w", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(("route_length", "shortest_length", "final_position", "result"))
        writer.writerow((len(ROUTE), shortest, position, "PASS" if passed else "FAIL"))
    if not passed:
        raise SystemExit("Maze route did not match the shortest path length")
    print(f"PASS: supplied route reaches the goal in {len(ROUTE)} shortest moves")


if __name__ == "__main__":
    main()
