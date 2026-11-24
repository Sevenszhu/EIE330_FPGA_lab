module txtPageROM (
    input  wire [1:0] page,
    input  wire [5:0] blockx,
    input  wire [5:0] blocky,
    output wire       pixel_on
);
    // Seven rows of 5x7 glyphs, with one block between letters.
    // The 23-column text area spans blockx=17..39, blocky=14..20.
    reg [22:0] row_bits;
    wire [5:0] bit_index_full = 6'd39 - blockx;
    wire [4:0] bit_index = bit_index_full[4:0];

    always @* begin
        row_bits = 23'b0;
        case ({page, blocky})
            // Page 0: MAZE
            {2'd0, 6'd14}: row_bits = 23'b10001001110011111011111;
            {2'd0, 6'd15}: row_bits = 23'b11011010001000001010000;
            {2'd0, 6'd16}: row_bits = 23'b10101010001000010010000;
            {2'd0, 6'd17}: row_bits = 23'b10101011111000100011110;
            {2'd0, 6'd18}: row_bits = 23'b10001010001001000010000;
            {2'd0, 6'd19}: row_bits = 23'b10001010001010000010000;
            {2'd0, 6'd20}: row_bits = 23'b10001010001011111011111;
            // Page 2: END
            {2'd2, 6'd14}: row_bits = 23'b00011111010001011110000;
            {2'd2, 6'd15}: row_bits = 23'b00010000011001010001000;
            {2'd2, 6'd16}: row_bits = 23'b00010000010101010001000;
            {2'd2, 6'd17}: row_bits = 23'b00011110010011010001000;
            {2'd2, 6'd18}: row_bits = 23'b00010000010001010001000;
            {2'd2, 6'd19}: row_bits = 23'b00010000010001010001000;
            {2'd2, 6'd20}: row_bits = 23'b00011111010001011110000;
            // Page 3: MUST
            {2'd3, 6'd14}: row_bits = 23'b10001010001001111011111;
            {2'd3, 6'd15}: row_bits = 23'b11011010001010000000100;
            {2'd3, 6'd16}: row_bits = 23'b10101010001010000000100;
            {2'd3, 6'd17}: row_bits = 23'b10101010001001110000100;
            {2'd3, 6'd18}: row_bits = 23'b10001010001000001000100;
            {2'd3, 6'd19}: row_bits = 23'b10001010001000001000100;
            {2'd3, 6'd20}: row_bits = 23'b10001001110011110000100;
            default: row_bits = 23'b0;
        endcase
    end

    assign pixel_on = (blockx >= 6'd17 && blockx < 6'd40) ?
                      row_bits[bit_index] : 1'b0;
endmodule
