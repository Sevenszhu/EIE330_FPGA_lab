`timescale 1ns / 1ps

module top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        btn,
    output wire        hsync,
    output wire        vsync,
    output wire [15:0] rgb
);

wire       pluse;
wire [6:0] blockx;
wire [5:0] blocky;

debounce g_debounce (
    .btn   (btn),
    .clk   (clk),
    .rst_n (rst_n),
    .pluse (pluse)
);

vga g_vga (
    .clk    (clk),
    .rst_n  (1),
    .h_sync (hsync),
    .v_sync (vsync),
    .blockx (blockx),
    .blocky (blocky)
);

GramManager g_gram_manager (
    .sw     (pluse),
    .clk    (clk),
    .reboot (rst_n),
    .blockx (blockx),
    .blocky (blocky),
    .rgb    (rgb)
);

endmodule
