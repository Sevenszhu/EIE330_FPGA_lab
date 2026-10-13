`timescale 1ns/1ps
module adder #(
    parameter INVERSE_OUT   = 0,
    parameter INVERSE_INPUT = 0
)(
    input  wire A,
    input  wire B,
    input  wire C,
    output wire O0,
    output wire carry
);

wire A_internal;
wire B_internal;
wire C_internal;

wire O0_internal;
wire carry_internal;

assign A_internal = A ^ INVERSE_INPUT;
assign B_internal = B ^ INVERSE_INPUT;
assign C_internal = C ^ INVERSE_INPUT;

assign O0_internal =
    A_internal ^ B_internal ^ C_internal;

assign carry_internal =
    (A_internal & B_internal) |
    (A_internal & C_internal) |
    (B_internal & C_internal);

assign O0    = O0_internal    ^ INVERSE_OUT;
assign carry = carry_internal ^ INVERSE_OUT;

endmodule
