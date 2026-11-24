module PosManager (
    input  wire       clk,
    input  wire       rstn,
    output reg  [5:0] playerPos,
    input  wire       up,
    input  wire       down,
    input  wire       left,
    input  wire       right,
    output wire [2:0] x,
    output wire [2:0] y,
    input  wire [3:0] dir,
    output wire win
);
    reg [5:0] NextPlayerPos;
    reg [1:0] stage;
    reg [3:0] key_old;
    reg [3:0] requested_dir;
    reg       can_move;
    reg [2:0] win_count;

    wire [3:0] key_now = {up, down, left, right};
    wire [3:0] key_rise = key_now & ~key_old;

    assign x = playerPos[2:0];
    assign y = playerPos[5:3];
    // The goal signal stays high until the five-cycle return to start.
    assign win = (playerPos == 6'd63);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            playerPos     <= 6'd0;
            NextPlayerPos <= 6'd0;
            stage         <= 2'd0;
            key_old       <= 4'b0000;
            requested_dir <= 4'b0000;
            can_move      <= 1'b0;
            win_count     <= 3'd0;
        end else begin
            key_old <= key_now;

            if (win) begin
                if (win_count == 3'd4) begin
                    playerPos <= 6'd0;
                    NextPlayerPos <= 6'd0;
                    requested_dir <= 4'b0000;
                    can_move <= 1'b0;
                    win_count <= 3'd0;
                    stage <= 2'd0;
                end else begin
                    win_count <= win_count + 3'd1;
                end
            end else begin
                win_count <= 3'd0;
                case (stage)
                    2'd0: begin
                        if (|key_rise) begin
                            if (key_rise[3])
                                requested_dir <= 4'b1000;
                            else if (key_rise[2])
                                requested_dir <= 4'b0100;
                            else if (key_rise[1])
                                requested_dir <= 4'b0010;
                            else
                                requested_dir <= 4'b0001;
                            stage <= 2'd1;
                        end
                    end

                    2'd1: begin
                        can_move <= |(dir & requested_dir);
                        stage <= 2'd2;
                    end

                    2'd2: begin
                        NextPlayerPos <= playerPos;
                        if (can_move) begin
                            case (requested_dir)
                                4'b1000: NextPlayerPos <= {playerPos[5:3] - 3'd1, playerPos[2:0]};
                                4'b0100: NextPlayerPos <= {playerPos[5:3] + 3'd1, playerPos[2:0]};
                                4'b0010: NextPlayerPos <= {playerPos[5:3], playerPos[2:0] - 3'd1};
                                4'b0001: NextPlayerPos <= {playerPos[5:3], playerPos[2:0] + 3'd1};
                            endcase
                        end
                        stage <= 2'd3;
                    end

                    2'd3: begin
                        playerPos <= NextPlayerPos;
                        stage <= 2'd0;
                    end

                    default: begin
                        stage <= 2'd0;
                    end
                endcase
            end
        end
    end
endmodule
