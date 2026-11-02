`timescale 1ns / 1ps

module vga (
    input  wire        clk,       
    input  wire        rst_n,
    input  wire        B2,
    output wire        h_sync,
    output wire        v_sync,
    output wire [15:0] rgb
);
    localparam [9:0] H_SYNC  = 10'd96;
    localparam [9:0] H_TOTAL = 10'd800;
    localparam [9:0] V_SYNC  = 10'd2;
    localparam [9:0] V_TOTAL = 10'd525;

    reg clk25 = 1'b0;
    always @(posedge clk) begin
        clk25 <= ~clk25;
    end

    reg [9:0] h_count;
    reg [9:0] v_count;
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

    reg [15:0] rgb565;

    localparam [15:0] BLACK = 16'h0000;
    localparam [15:0] WHITE = 16'hFFFF;

    assign blockx = h_count[9:3];
    assign blocky = v_count[8:3];

//字库直接ai转换，人手抄字库貌似不是一件很厉害的事情


    always @(*) begin
        rgb565 = BLACK;

        case ({blocky, blockx})
            // Row 0
            {6'd30, 7'd43}, {6'd30, 7'd48},
            {6'd30, 7'd51}, {6'd30, 7'd56},
            {6'd30, 7'd60}, {6'd30, 7'd61}, {6'd30, 7'd62},
            {6'd30, 7'd63},
            {6'd30, 7'd67}, {6'd30, 7'd68}, {6'd30, 7'd69},
            {6'd30, 7'd70}, {6'd30, 7'd71}, {6'd30, 7'd72}:
                rgb565 = WHITE;

            // Row 1
            {6'd31, 7'd43}, {6'd31, 7'd44}, {6'd31, 7'd47},
            {6'd31, 7'd48},
            {6'd31, 7'd51}, {6'd31, 7'd56},
            {6'd31, 7'd59}, {6'd31, 7'd64},
            {6'd31, 7'd69}, {6'd31, 7'd70}:
                rgb565 = WHITE;

            // Row 2
            {6'd32, 7'd43}, {6'd32, 7'd45}, {6'd32, 7'd46},
            {6'd32, 7'd48},
            {6'd32, 7'd51}, {6'd32, 7'd56},
            {6'd32, 7'd59},
            {6'd32, 7'd69}, {6'd32, 7'd70}:
                rgb565 = WHITE;

            // Row 3
            {6'd33, 7'd43}, {6'd33, 7'd48},
            {6'd33, 7'd51}, {6'd33, 7'd56},
            {6'd33, 7'd60}, {6'd33, 7'd61}, {6'd33, 7'd62},
            {6'd33, 7'd63},
            {6'd33, 7'd69}, {6'd33, 7'd70}:
                rgb565 = WHITE;

            // Row 4
            {6'd34, 7'd43}, {6'd34, 7'd48},
            {6'd34, 7'd51}, {6'd34, 7'd56},
            {6'd34, 7'd64},
            {6'd34, 7'd69}, {6'd34, 7'd70}:
                rgb565 = WHITE;

            // Row 5
            {6'd35, 7'd43}, {6'd35, 7'd48},
            {6'd35, 7'd51}, {6'd35, 7'd56},
            {6'd35, 7'd59}, {6'd35, 7'd64},
            {6'd35, 7'd69}, {6'd35, 7'd70}:
                rgb565 = WHITE;

            // Row 6
            {6'd36, 7'd43}, {6'd36, 7'd48},
            {6'd36, 7'd52}, {6'd36, 7'd53}, {6'd36, 7'd54},
            {6'd36, 7'd55},
            {6'd36, 7'd60}, {6'd36, 7'd61}, {6'd36, 7'd62},
            {6'd36, 7'd63},
            {6'd36, 7'd69}, {6'd36, 7'd70}:
                rgb565 = WHITE;

            default:
                rgb565 = BLACK;
        endcase
    end

    assign rgb = B2 ? rgb565 : BLACK;


endmodule
