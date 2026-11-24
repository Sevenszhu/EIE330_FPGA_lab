`timescale 1ns / 1ps

module player_movement_tb;
    reg clk = 0;
    reg rstn = 1;
    reg up = 0;
    reg down = 0;
    reg left = 0;
    reg right = 0;
    reg [2:0] case_id = 0;
    wire [5:0] playerPos;
    wire [2:0] x;
    wire [2:0] y;
    wire [3:0] dir;
    wire win;
    integer result_fd;

    always #10 clk = ~clk;

    PosManager position (
        .clk(clk), .rstn(rstn), .playerPos(playerPos),
        .up(up), .down(down), .left(left), .right(right),
        .x(x), .y(y), .dir(dir), .win(win)
    );
    MovementROM rom (.x(x), .y(y), .movement(dir));

    task automatic reset_position;
        begin
            @(negedge clk);
            rstn = 0;
            {up, down, left, right} = 4'b0000;
            @(negedge clk);
            rstn = 1;
            @(posedge clk); #1;
            if (playerPos !== 6'd0 || position.stage !== 2'd0)
                $fatal(1, "Reset did not restore the start position and idle stage");
        end
    endtask

    task automatic check_move(
        input integer test_id,
        input [3:0] request_bits,
        input [5:0] initial_pos,
        input [3:0] expected_dir,
        input expected_allow,
        input [5:0] expected_final
    );
        begin
            case_id = test_id;
            if (playerPos !== initial_pos || dir !== expected_dir)
                $fatal(1, "Case %0d: initial position or ROM data incorrect", test_id);

            @(negedge clk);
            {up, down, left, right} = request_bits;
            #1;
            if (position.key_rise !== request_bits)
                $fatal(1, "Case %0d: input rising edge not detected", test_id);

            @(posedge clk); #1;
            if (position.stage !== 2'd1 || position.requested_dir !== request_bits)
                $fatal(1, "Case %0d: input capture failed", test_id);

            @(posedge clk); #1;
            if (position.stage !== 2'd2 || position.can_move !== expected_allow)
                $fatal(1, "Case %0d: movement validation failed", test_id);

            @(posedge clk); #1;
            if (position.stage !== 2'd3 || position.NextPlayerPos !== expected_final)
                $fatal(1, "Case %0d: next-position calculation failed", test_id);

            @(posedge clk); #1;
            if (position.stage !== 2'd0 || playerPos !== expected_final)
                $fatal(1, "Case %0d: position commit failed", test_id);

            $fdisplay(result_fd, "%0d,%0d,%04b,%04b,%0d,%0d,%0d,PASS",
                      test_id, initial_pos, request_bits, expected_dir,
                      expected_allow, position.NextPlayerPos, playerPos);
            @(negedge clk);
            {up, down, left, right} = 4'b0000;
            repeat (2) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("data/waveforms/player_movement.vcd");
        $dumpvars(0, player_movement_tb);
        result_fd = $fopen("data/results/player_movement_cases.csv", "w");
        if (!result_fd) $fatal(1, "Cannot open position result CSV");
        $fdisplay(result_fd,
                  "case_id,initial_pos,requested_dir,rom_dir,can_move,next_pos,final_pos,result");

        #2 rstn = 0;
        #25 rstn = 1;
        repeat (2) @(posedge clk);
        #1;

        check_move(1, 4'b0001, 6'd0, 4'b0101, 1'b1, 6'd1);
        check_move(2, 4'b0100, 6'd1, 4'b0011, 1'b0, 6'd1);
        case_id = 0;
        reset_position();
        check_move(3, 4'b1000, 6'd0, 4'b0101, 1'b0, 6'd0);
        check_move(4, 4'b0010, 6'd0, 4'b0101, 1'b0, 6'd0);

        @(negedge clk);
        position.playerPos = 6'd7;
        position.NextPlayerPos = 6'd7;
        #1;
        check_move(5, 4'b0001, 6'd7, 4'b0110, 1'b0, 6'd7);

        @(negedge clk);
        position.playerPos = 6'd56;
        position.NextPlayerPos = 6'd56;
        #1;
        check_move(6, 4'b0100, 6'd56, 4'b0001, 1'b0, 6'd56);

        $fclose(result_fd);
        $display("PASS: valid, wall, and four boundary moves followed the four-stage FSM");
        $finish;
    end
endmodule
