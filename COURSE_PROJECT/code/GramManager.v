module GramManager (
    input  wire        swpage,
    input  wire        clk,
    input  wire        reboot,
    input  wire [5:0]  blockx,
    input  wire [5:0]  blocky,
    input  wire [5:0]  playerPos,
    output reg  [15:0] rgb
);
    reg [1:0] page;
    reg swpage_old;
    wire text_pixel;
    wire [15:0] maze_rgb;

    txtPageROM text_rom (
        .page(page),
        .blockx(blockx),
        .blocky(blocky),
        .pixel_on(text_pixel)
    );

    MazeGramManager maze_gram (
        .clk(clk),
        .blockx(blockx),
        .blocky(blocky),
        .playerPos(playerPos),
        .rgb(maze_rgb)
    );

    always @(posedge clk) begin
        if (reboot) begin
            page <= 2'd0;
            swpage_old <= swpage;
        end else begin
            swpage_old <= swpage;
            if (swpage && !swpage_old)
                page <= page + 2'd1;
        end
    end

    always @* begin
        if (page == 2'd1)
            rgb = maze_rgb;
        else if (text_pixel)
            rgb = 16'hFFFF;
        else
            rgb = 16'h0000;
    end
endmodule

module MazeGramManager (
    input  wire        clk,
    input  wire [5:0]  blockx,
    input  wire [5:0]  blocky,
    input  wire [5:0]  playerPos,
    output reg  [15:0] rgb
);
    // Bit (8*y+x) matches MovementROM: 1 is a path, 0 is a wall.
    localparam [63:0] MAZE_MAP = 64'hEF5AD2772F5AF1DF;

    wire on_maze = blockx >= 6'd25 && blockx < 6'd33 &&
                   blocky >= 6'd13 && blocky < 6'd21;
    wire [5:0] maze_x = blockx - 6'd25;
    wire [5:0] maze_y = blocky - 6'd13;
    wire [5:0] maze_address = {maze_y[2:0], maze_x[2:0]};

    always @* begin
        rgb = 16'h0000;
        if (on_maze) begin
            if (maze_address == playerPos)
                rgb = 16'hF800;
            else if (MAZE_MAP[maze_address])
                rgb = 16'hFFFF;
        end
    end
endmodule

