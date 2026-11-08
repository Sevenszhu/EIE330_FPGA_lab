`timescale 1ns / 1ps

module vga (
    input  wire        clk,       
    input  wire        rst_n,
    output wire        h_sync,
    output wire        v_sync,
    output wire [6:0] blockx,
    output wire [5:0] blocky,
);
    localparam [9:0] H_SYNC  = 10'd96;
    localparam [9:0] H_TOTAL = 10'd800;
    localparam [9:0] V_SYNC  = 10'd2;
    localparam [9:0] V_TOTAL = 10'd525;

    reg clk25 = 1'b0;
    always @(posedge clk) begin
        clk25 <= ~clk25;
    end

    reg [9:0] h_count = 0;
	reg [9:0] v_count = 0;
//其实能放一个块，但是不方便
    always @(posedge clk25) begin
        if (!rst_n)
            h_count <= 10'd0;
        else if (h_count == (H_TOTAL - 1'b1))
            h_count <= 10'd0;
        else
            h_count <= h_count + 1'b1;
    end

    always @(posedge clk25) begin
        if (!rst_n)
            v_count <= 10'd0;
        else if (h_count == (H_TOTAL - 1'b1)) begin
            if (v_count == (V_TOTAL - 1'b1))
                v_count <= 10'd0;
            else
                v_count <= v_count + 1'b1;
        end
    end
    
    assign h_sync = (h_count < H_SYNC) ? 1'b1 : 1'b0;
    assign v_sync = (v_count < V_SYNC) ? 1'b1 : 1'b0;

    wire [6:0] blockx;
    wire [5:0] blocky;

    assign blockx = h_count[9:3];
    assign blocky = v_count[8:3];

endmodule




