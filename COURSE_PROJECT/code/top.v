module top (
    input  wire        clk,
    input  wire        rstn,
    input  wire        up,
    input  wire        down,
    input  wire        left,
    input  wire        right,
    input  wire        sw,
    output wire        h_sync,
    output wire        v_sync,
    output wire [15:0] rgb
);
    wire up_event;
    wire down_event;
    wire left_event;
    wire right_event;
    wire swpage;
    wire win;
    wire [5:0] playerPos;
    wire [2:0] x;
    wire [2:0] y;
    wire [3:0] dir;
    wire [5:0] blockx;
    wire [5:0] blocky;

    NegedgeManager key_manager (
        .clk(clk),
        .rstn(rstn),
        .up(up),
        .down(down),
        .left(left),
        .right(right),
        .sw(sw),
        .up_out(up_event),
        .down_out(down_event),
        .left_out(left_event),
        .right_out(right_event),
        .swpage(swpage)
    );

    PosManager position (
        .clk(clk),
        .rstn(rstn),
        .playerPos(playerPos),
        .up(up_event),
        .down(down_event),
        .left(left_event),
        .right(right_event),
        .x(x),
        .y(y),
        .dir(dir),
        .win(win)
    );

    MovementROM maze_rom (
        .x(x),
        .y(y),
        .movement(dir)
    );

    vga video_timing (
        .clk(clk),
        .rst_n(rstn),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .blockx(blockx),
        .blocky(blocky)
    );

    GramManager graphics (
        .swpage(swpage | win),
        .clk(clk),
        .reboot(~rstn),
        .blockx(blockx),
        .blocky(blocky),
        .playerPos(playerPos),
        .rgb(rgb)
    );
endmodule
