module MovementROM (
    input  wire [2:0] x,
    input  wire [2:0] y,
    output wire [3:0] movement
);
    // Coordinates: x increases right, y increases down.
    // movement bits [3:0] = {up, down, left, right}.
    // A 1 permits movement to the adjacent cell.
    // # = wall, . = walkable, S = start (0,0), G = goal (7,7).
    // y=0: S....#..
    // y=1: .###....
    // y=2: #.#..#.#
    // y=3: ....#.##
    // y=4: ...#...#
    // y=5: #.##.#..
    // y=6: #.#..#.#
    // y=7: ....#..G
    // 64-bit walkable map for GramManager: bit (8*y+x) is 1 for a path.
    // 64'hEF5AD2772F5AF1DF

    // 64 cells x 4 movement bits = 256 bits.
    // Each 32-bit row is packed from x=7 to x=0.
    localparam [255:0] MOVEMENT_TABLE = {
        32'h2B10A3B1,  // y=7
        32'h0C0A50C0,  // y=6
        32'h2D0C00C0,  // y=5
        32'h06B50AF9,  // y=4
        32'h0040A7F5,  // y=3
        32'h080A5040,  // y=2
        32'hAF3D0008,  // y=1
        32'h65063335  // y=0
    };

    wire [7:0] address = {y, x, 2'b00};
    assign movement = MOVEMENT_TABLE[address +: 4];
endmodule
