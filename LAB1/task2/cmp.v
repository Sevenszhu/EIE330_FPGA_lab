`timescale 1ns/1ps
module cmp #(
    parameter INVERSE_OUT   = 0,
    parameter INVERSE_INPUT = 0
)(
    input  wire A,
    input  wire B,
    output wire GT,
    output wire EQ,
    output wire LT
);

wire A_internal;
wire B_internal;
wire GT_internal;
wire EQ_internal;
wire LT_internal;

assign A_internal = A ^ INVERSE_INPUT;
assign B_internal = B ^ INVERSE_INPUT;

assign GT_internal = (A_internal > B_internal);
assign EQ_internal = (A_internal == B_internal);
assign LT_internal = (A_internal < B_internal);

assign GT = GT_internal ^ INVERSE_OUT;
assign EQ = EQ_internal ^ INVERSE_OUT;
assign LT = LT_internal ^ INVERSE_OUT;

endmodule
