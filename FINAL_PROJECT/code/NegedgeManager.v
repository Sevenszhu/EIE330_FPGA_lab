module NegedgeManager (
    input  wire clk,
    input  wire rstn,
    input  wire up,
    input  wire down,
    input  wire left,
    input  wire right,
    input  wire sw,
    output wire up_out,
    output wire down_out,
    output wire left_out,
    output wire right_out,
    output wire swpage
);
    reg [4:0] key_old;
    reg [4:0] handling;
    reg [21:0] ColdDownCount;
    reg [1:0] stage;


    wire [4:0] key_now = {up, down, left, right, sw};
    wire [4:0] key_fall = key_old & ~key_now;
    wire selected_key_high = |(handling & key_now);

    assign {up_out, down_out, left_out, right_out, swpage} = handling;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            key_old       <= 5'b11111;
            handling      <= 5'b00000;
            ColdDownCount <= 22'd0;
            stage         <= 2'd0;
        end else begin
            key_old <= key_now;

            case (stage)
                2'd0: begin
                    if (|key_fall) begin
                        stage <= 2'd1;
                        ColdDownCount <= 22'd0;

                        if (key_fall[4])
                            handling <= 5'b10000;
                        else if (key_fall[3])
                            handling <= 5'b01000;
                        else if (key_fall[2])
                            handling <= 5'b00100;
                        else if (key_fall[1])
                            handling <= 5'b00010;
                        else
                            handling <= 5'b00001;
                    end
                end

                2'd1: begin
                    if (ColdDownCount == 22'd2_499_999) begin
                        ColdDownCount <= 22'd0;
                        stage <= 2'd2;
                    end else begin
                        ColdDownCount <= ColdDownCount + 22'd1;
                    end
                end

                2'd2: begin
                    if (selected_key_high) begin
                        ColdDownCount <= 22'd0;
                        stage <= 2'd3;
                    end
                end

                2'd3: begin
                    if (!selected_key_high) begin
                        ColdDownCount <= 22'd0;
                        stage <= 2'd2;
                    end else if (ColdDownCount == 22'd2_499_999) begin
                        ColdDownCount <= 22'd0;
                        handling <= 5'b00000;
                        stage <= 2'd0;
                    end else begin
                        ColdDownCount <= ColdDownCount + 22'd1;
                    end
                end

                default: begin
                    ColdDownCount <= 22'd0;
                    handling <= 5'b00000;
                    stage <= 2'd0;
                end
            endcase
        end
    end
endmodule
