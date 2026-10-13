`timescale 1ns/1ps

// Bridge between the Simple VGA Simulator controls and the LAB1 comparator.
module DevelopmentBoard (
    input  wire        clk,
    input  wire        reset,
    input  wire        B2,
    input  wire        B3,
    input  wire        B4,
    input  wire        B5,
    output wire        h_sync,
    output wire        v_sync,
    output wire [15:0] rgb,
    output wire        led1,
    output wire        led2,
    output wire        led3,
    output wire        led4,
    output wire        led5
);

    // The GUI buttons and LEDs are active-low. These parameters convert the
    // physical levels while preserving the intended logical comparison.
    cmp #(
        .INVERSE_INPUT (1),
        .INVERSE_OUT   (1)
    ) dut (
        .A  (B2),
        .B  (B3),
        .GT (led1),
        .EQ (led2),
        .LT (led3)
    );

    assign led4 = 1'b1;
    assign led5 = 1'b1;

    // This DUT has no VGA output. Keep the display area black.
    assign h_sync = 1'b0;
    assign v_sync = 1'b0;
    assign rgb     = 16'h0000;

    wire _unused = &{1'b0, clk, reset, B4, B5};

endmodule
