`timescale 1ns / 1ps

module victory_detection_tb;
    reg clk = 1'b0;
    reg rstn = 1'b0;
    localparam [3:0] UP = 4'b1000, DOWN = 4'b0100,
                     LEFT = 4'b0010, RIGHT = 4'b0001;
    reg [3:0] direction_event = 4'b0000;
    reg manual_sw = 1'b0;
    wire [5:0] playerPos;
    wire [2:0] x;
    wire [2:0] y;
    wire [3:0] dir;
    wire win;
    wire [15:0] rgb;
    wire swpage = manual_sw | win;
    integer waveform_fd;
    integer result_fd;
    integer hold_cycle;

    always #10 clk = ~clk;

    PosManager position (
        .clk(clk), .rstn(rstn), .playerPos(playerPos),
        .up(direction_event[3]), .down(direction_event[2]),
        .left(direction_event[1]), .right(direction_event[0]),
        .x(x), .y(y), .dir(dir), .win(win)
    );
    MovementROM movement_rom (.x(x), .y(y), .movement(dir));
    GramManager graphics (
        .swpage(swpage), .clk(clk), .reboot(~rstn),
        .blockx(6'd20), .blocky(6'd14), .playerPos(playerPos), .rgb(rgb)
    );

    always @(posedge clk) begin
        #1;
        if (rstn) begin
            $fdisplay(waveform_fd, "%0d,%0d,%0d,%0d,%0d,%0d,%04h",
                      $time - 1, position.stage, playerPos, win,
                      position.win_count, graphics.page, rgb);
        end
    end

    task automatic move(input [3:0] request, input [5:0] expected_position);
        begin
        @(negedge clk);
        if ((dir & request) === 4'b0000)
            $fatal(1, "ROM blocked route at cell %0d", playerPos);
        direction_event = request;
        @(negedge clk); direction_event = 4'b0000;
        repeat (3) @(posedge clk);
        #2;
        if (playerPos !== expected_position || graphics.page !== 2'd1)
            $fatal(1, "Route expected cell %0d on Gameplay, got cell %0d on page %0d",
                   expected_position, playerPos, graphics.page);
        end
    endtask

    initial begin
        $dumpfile("data/victory_detection.vcd");
        $dumpvars(0, victory_detection_tb);
        waveform_fd = $fopen("data/victory_detection_waveform.csv", "w");
        result_fd = $fopen("data/victory_detection_results.csv", "w");
        if (!waveform_fd || !result_fd)
            $fatal(1, "Cannot open victory verification result files");

        $fdisplay(waveform_fd,
                  "time_ns,stage,playerPos,win,win_count,page,rgb");
        $fdisplay(result_fd, "check,expected,observed,result");

        repeat (2) @(posedge clk);
        @(negedge clk); rstn = 1'b1;
        @(posedge clk); #2;
        if (graphics.page !== 2'd0 || playerPos !== 6'd0)
            $fatal(1, "Reset must select MAZE and place the player at the start");

        @(negedge clk); manual_sw = 1'b1;
        @(posedge clk); #2;
        if (graphics.page !== 2'd1)
            $fatal(1, "Manual switch did not select Gameplay");
        @(negedge clk); manual_sw = 1'b0;

        move(RIGHT, 1);  move(RIGHT, 2);  move(RIGHT, 3);  move(RIGHT, 4);
        move(DOWN, 12);  move(DOWN, 20);  move(LEFT, 19);  move(DOWN, 27);
        move(LEFT, 26);  move(DOWN, 34);  move(LEFT, 33);  move(DOWN, 41);
        move(DOWN, 49);  move(DOWN, 57);  move(RIGHT, 58); move(RIGHT, 59);
        move(UP, 51);    move(RIGHT, 52); move(UP, 44);    move(UP, 36);
        move(RIGHT, 37); move(RIGHT, 38); move(DOWN, 46);  move(DOWN, 54);
        move(DOWN, 62);  move(RIGHT, 63);

        if (win !== 1'b1 || position.win_count !== 3'd0 || rgb !== 16'h0000)
            $fatal(1, "Goal commit did not assert win on the Gameplay page");
        $fdisplay(result_fd, "goal_commit,63 and win=1,%0d and win=%0b,PASS",
                  playerPos, win);

        for (hold_cycle = 1; hold_cycle <= 5; hold_cycle = hold_cycle + 1) begin
            @(posedge clk); #2;
            if (hold_cycle < 5) begin
                if (playerPos !== 6'd63 || win !== 1'b1 ||
                    position.win_count !== hold_cycle[2:0] ||
                    graphics.page !== 2'd2 || rgb !== 16'hFFFF)
                    $fatal(1, "Victory hold cycle %0d is incorrect", hold_cycle);
            end else if (playerPos !== 6'd0 || win !== 1'b0 ||
                         position.win_count !== 3'd0 || graphics.page !== 2'd2) begin
                $fatal(1, "Five-cycle reset or retained END page failed");
            end
            if (hold_cycle == 1)
                $fdisplay(result_fd, "page_transition,2,%0d,PASS", graphics.page);
        end
        $fdisplay(result_fd, "position_reset,0,%0d,PASS", playerPos);
        $fdisplay(result_fd, "victory_hold_cycles,5,%0d,PASS", hold_cycle - 1);
        repeat (4) begin
            if (graphics.page !== 2'd2 || rgb !== 16'hFFFF ||
                win !== 1'b0 || playerPos !== 6'd0)
                $fatal(1, "END page or glyph changed after the position reset");
            @(posedge clk); #2;
        end
        $fdisplay(result_fd, "end_page_retention,2 and RGB=ffff,%0d and RGB=%04h,PASS",
                  graphics.page, rgb);

        $fclose(waveform_fd);
        $fclose(result_fd);
        $display("PASS: goal detection, page advance, five-cycle reset, END retention");
        $finish;
    end
endmodule
