`timescale 1ns / 1ps

module integrated_game_tb;
    localparam [3:0] UP = 4'b1000, DOWN = 4'b0100,
                     LEFT = 4'b0010, RIGHT = 4'b0001;

    reg clk = 1'b0;
    reg rstn = 1'b0;
    reg up = 1'b1;
    reg down = 1'b1;
    reg left = 1'b1;
    reg right = 1'b1;
    reg sw = 1'b1;
    wire h_sync;
    wire v_sync;
    wire [15:0] rgb;
    reg [3:0] route [0:25];
    reg [5:0] route_position [0:25];
    reg [4:0] selected;
    integer i;
    integer rise_count = 0;
    integer trace_fd;
    integer result_fd;

    always #10 clk = ~clk;

    top dut (
        .clk(clk), .rstn(rstn),
        .up(up), .down(down), .left(left), .right(right), .sw(sw),
        .h_sync(h_sync), .v_sync(v_sync), .rgb(rgb)
    );

    always @(posedge clk) begin
        if (rstn && |dut.position.key_rise)
            rise_count = rise_count + 1;
    end

    task record;
        input [8*32-1:0] event_name;
        input integer step;
        begin
            $fdisplay(trace_fd, "%0d,%0s,%0d,%0d,%0d,%0d,%05b,%0d,%0d",
                      $time, event_name, step, dut.playerPos,
                      dut.graphics.page, dut.win, dut.key_manager.handling,
                      dut.key_manager.stage, dut.key_manager.ColdDownCount);
        end
    endtask

    task press;
        input [4:0] raw_pressed;
        input [4:0] expected_key;
        input [5:0] target;
        input add_bounce;
        input [8*32-1:0] event_name;
        input integer step;
        integer rise_before;
        integer remaining_cycles;
        integer win_cycle;
        time pressed_at;
        time released_at;
        begin
            rise_before = rise_count;
            @(negedge clk);
            {up, down, left, right, sw} = ~raw_pressed;
            @(posedge clk); #1;
            pressed_at = $time;
            if (dut.key_manager.handling !== expected_key ||
                dut.key_manager.stage !== 2'd1) begin
                $display("FAIL: %0s key selection", event_name);
                $finish;
            end

            remaining_cycles = 4;
            if (add_bounce) begin
                @(negedge clk); {up, down, left, right, sw} = 5'b11111;
                @(posedge clk); #1;
                @(negedge clk); {up, down, left, right, sw} = ~raw_pressed;
                @(posedge clk); #1;
                if (dut.key_manager.handling !== expected_key ||
                    dut.key_manager.stage !== 2'd1) begin
                    $display("FAIL: %0s bounce changed selected key", event_name);
                    $finish;
                end
                remaining_cycles = 2;
            end

            repeat (remaining_cycles) @(posedge clk);
            #1;
            if (dut.playerPos !== target) begin
                $display("FAIL: %0s expected position %0d, got %0d",
                         event_name, target, dut.playerPos);
                $finish;
            end
            if (raw_pressed[0] == 1'b0 && rise_count != rise_before + 1) begin
                $display("FAIL: %0s produced %0d movement events",
                         event_name, rise_count - rise_before);
                $finish;
            end
            if (raw_pressed[0] == 1'b1 && rise_count != rise_before) begin
                $display("FAIL: switch key produced a movement event");
                $finish;
            end
            record(event_name, step);

            if (target == 6'd63) begin
                if (dut.win !== 1'b1 || dut.graphics.page !== 2'd1) begin
                    $display("FAIL: goal did not assert win on the gameplay page");
                    $finish;
                end
                record("goal_win_asserted", step);
                for (win_cycle = 1; win_cycle <= 5; win_cycle = win_cycle + 1) begin
                    @(posedge clk); #1;
                    if (win_cycle < 5 &&
                        (dut.playerPos !== 6'd63 || dut.win !== 1'b1 ||
                         dut.position.win_count !== win_cycle ||
                         dut.graphics.page !== 2'd2)) begin
                        $display("FAIL: victory hold cycle %0d", win_cycle);
                        $finish;
                    end
                    if (win_cycle == 1) record("end_page_selected", step);
                    if (win_cycle == 5) begin
                        if (dut.playerPos !== 6'd0 || dut.win !== 1'b0 ||
                            dut.graphics.page !== 2'd2) begin
                            $display("FAIL: victory position reset");
                            $finish;
                        end
                        record("position_reset", step);
                    end
                end
            end

            wait (dut.key_manager.stage == 2'd2);
            #1;
            if ($time - pressed_at != 50_000_000 ||
                dut.key_manager.handling !== expected_key) begin
                $display("FAIL: %0s cooldown duration", event_name);
                $finish;
            end
            record("cooldown_complete", step);

            @(negedge clk); {up, down, left, right, sw} = 5'b11111;
            @(posedge clk); #1;
            released_at = $time;
            if (dut.key_manager.stage !== 2'd3) begin
                $display("FAIL: %0s release detection", event_name);
                $finish;
            end
            if (add_bounce) begin
                @(negedge clk); {up, down, left, right, sw} = ~raw_pressed;
                @(posedge clk); #1;
                if (dut.key_manager.stage !== 2'd2 ||
                    dut.key_manager.ColdDownCount !== 22'd0) begin
                    $display("FAIL: %0s release bounce did not restart waiting", event_name);
                    $finish;
                end
                @(negedge clk); {up, down, left, right, sw} = 5'b11111;
                @(posedge clk); #1;
                released_at = $time;
                if (dut.key_manager.stage !== 2'd3) begin
                    $display("FAIL: %0s second release was not detected", event_name);
                    $finish;
                end
            end
            wait (dut.key_manager.stage == 2'd0);
            #1;
            if ($time - released_at != 50_000_000 ||
                dut.key_manager.handling !== 5'b00000) begin
                $display("FAIL: %0s stable release duration", event_name);
                $finish;
            end
            if (rise_count != rise_before + (raw_pressed[0] == 1'b0)) begin
                $display("FAIL: %0s repeated movement event", event_name);
                $finish;
            end
            record("ready_for_next_key", step);
        end
    endtask

    initial begin
        #3_500_000_000;
        $display("FAIL: integrated simulation timed out");
        $finish;
    end

    initial begin
        route[0]=RIGHT; route[1]=RIGHT; route[2]=RIGHT; route[3]=RIGHT;
        route[4]=DOWN;  route[5]=DOWN;  route[6]=LEFT;  route[7]=DOWN;
        route[8]=LEFT;  route[9]=DOWN;  route[10]=LEFT; route[11]=DOWN;
        route[12]=DOWN; route[13]=DOWN; route[14]=RIGHT;route[15]=RIGHT;
        route[16]=UP;   route[17]=RIGHT;route[18]=UP;   route[19]=UP;
        route[20]=RIGHT;route[21]=RIGHT;route[22]=DOWN; route[23]=DOWN;
        route[24]=DOWN; route[25]=RIGHT;

        route_position[0]=1;  route_position[1]=2;  route_position[2]=3;
        route_position[3]=4;  route_position[4]=12; route_position[5]=20;
        route_position[6]=19; route_position[7]=27; route_position[8]=26;
        route_position[9]=34; route_position[10]=33;route_position[11]=41;
        route_position[12]=49;route_position[13]=57;route_position[14]=58;
        route_position[15]=59;route_position[16]=51;route_position[17]=52;
        route_position[18]=44;route_position[19]=36;route_position[20]=37;
        route_position[21]=38;route_position[22]=46;route_position[23]=54;
        route_position[24]=62;route_position[25]=63;

        trace_fd = $fopen("data/traces/integrated_game_trace.csv", "w");
        result_fd = $fopen("data/results/integrated_game_results.csv", "w");
        if (!trace_fd || !result_fd) begin
            $display("FAIL: cannot open integrated result files");
            $finish;
        end
        $fdisplay(trace_fd,
                  "time_ns,event,step,playerPos,page,win,handling,stage,ColdDownCount");
        $fdisplay(result_fd, "test_id,test_function,expected,observed,result");

        repeat (2) @(posedge clk);
        #1;
        if (dut.playerPos !== 6'd0 || dut.graphics.page !== 2'd0 ||
            dut.key_manager.stage !== 2'd0) begin
            $display("FAIL: T01 reset state");
            $finish;
        end
        $fdisplay(result_fd, "T01,Reset,start page and position 0,page 0 position 0,PASS");
        record("reset_start", 0);
        @(negedge clk); rstn = 1'b1;

        press(5'b11000, 5'b10000, 6'd0, 1'b0,
              "priority_up_over_down", 0);
        $fdisplay(result_fd, "T03,Button priority,Up wins simultaneous Up and Down,handling 10000,PASS");

        press(5'b00001, 5'b00001, 6'd0, 1'b0,
              "start_to_gameplay", 0);
        if (dut.graphics.page !== 2'd1) begin
            $display("FAIL: T10 start page transition");
            $finish;
        end

        for (i = 0; i < 26; i = i + 1) begin
            case (route[i])
                UP: selected = 5'b10000;
                DOWN: selected = 5'b01000;
                LEFT: selected = 5'b00100;
                RIGHT: selected = 5'b00010;
                default: begin
                    $display("FAIL: invalid route step %0d", i + 1);
                    $finish;
                end
            endcase
            press({route[i], 1'b0}, selected, route_position[i],
                  (i == 0), "route_move", i + 1);
            if (i == 0)
                $fdisplay(result_fd, "T02,Button debounce,bounce yields one movement event,one event and position 1,PASS");
            if (i < 25 && dut.graphics.page !== 2'd1) begin
                $display("FAIL: gameplay page changed early at step %0d", i + 1);
                $finish;
            end
        end

        if (dut.playerPos !== 6'd0 || dut.graphics.page !== 2'd2 ||
            dut.win !== 1'b0) begin
            $display("FAIL: final end state");
            $finish;
        end
        $fdisplay(result_fd, "T05,Valid movement,26 legal moves reach goal,position 63 observed before reset,PASS");
        $fdisplay(result_fd, "T10,Page transition,start gameplay end,page sequence 0 1 2,PASS");
        $fdisplay(result_fd, "T12,Victory detection,win asserted at goal,win 1 at position 63,PASS");
        $fdisplay(result_fd, "T13,Position reset,return to start after victory,position 0 after five cycles,PASS");
        record("end_idle_retained", 26);

        $fclose(trace_fd);
        $fclose(result_fd);
        $display("PASS: full game completed in 26 moves with real cooldown and release intervals");
        $finish;
    end
endmodule
