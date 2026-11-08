

module debounce (
    input  wire btn,
    input  wire clk,
    input  wire rst_n,
    output wire pluse
);

reg [20:0] coldDownCount;
reg [1:0] stage;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage         <= 0;
        coldDownCount <= 0;
    end else begin
        case (stage)
            0: begin
                if (!btn) begin
                    stage         <= 1;
                    coldDownCount <= 0;
                end
            end
            1: begin
                if (coldDownCount == 21'd999999) begin
                    stage         <= 2;
                    coldDownCount <= 0;
                end else begin
                    coldDownCount <= coldDownCount + 1;
                end
            end

            2: begin
                if (btn)
                    stage <= 0;
            end

            default: begin
                stage         <= 0;
                coldDownCount <= 0;
            end
        endcase
    end
end

assign pluse = stage[0];

endmodule
