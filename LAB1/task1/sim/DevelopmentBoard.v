`timescale 1ns/1ps

// Bridge between the Simple VGA Simulator controls and the LAB1 full adder.
// Simulator buttons and LEDs are active-low; the adder uses active-high logic.
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

    wire sum;
    wire carry;

    adder dut (
        .A     (~B2),
        .B     (~B3),
        .C     (~B4),
        .O0    (sum),
        .carry (carry)
    );

    // LED1 shows the sum and LED2 shows the carry.
    assign led1 = ~sum;
    assign led2 = ~carry;
    assign led3 = 1'b1;
    assign led4 = 1'b1;
    assign led5 = 1'b1;

    // This DUT has no VGA output. Keep the display area black.
    assign h_sync = 1'b0;
    assign v_sync = 1'b0;
    assign rgb     = 16'h0000;

    // Unused simulator inputs are intentionally left unconnected to the DUT.
    wire _unused = &{1'b0, clk, reset, B5};

endmodule
