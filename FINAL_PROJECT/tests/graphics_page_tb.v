`timescale 1ns / 1ps

module graphics_page_tb;
    reg clk = 1'b0;
    reg reboot = 1'b1;
    reg manual_sw = 1'b0;
    reg win = 1'b0;
    reg [5:0] blockx = 0, blocky = 0, playerPos = 0;
    wire swpage = manual_sw | win;
    wire [15:0] rgb;
    integer page_fd, graphics_fd, checks;

    GramManager dut (.swpage(swpage), .clk(clk), .reboot(reboot),
                     .blockx(blockx), .blocky(blocky),
                     .playerPos(playerPos), .rgb(rgb));
    always #10 clk = ~clk;

    task page_sample(input [127:0] event_name, input [1:0] expected_page);
        begin
            if (dut.page !== expected_page)
                $fatal(1, "Page %0s: expected %0d, observed %0d",
                       event_name, expected_page, dut.page);
            $fdisplay(page_fd, "%0d,%0s,%0d,%0d,%0d,%0d,%0d",
                      $time, event_name, manual_sw, win, swpage,
                      dut.page, expected_page);
            checks = checks + 1;
        end
    endtask

    task check_pixel(input [127:0] case_name, input [1:0] expected_page,
                     input [5:0] bx, input [5:0] by,
                     input [15:0] expected_rgb);
        begin
            blockx = bx;
            blocky = by;
            #1;
            if (dut.page !== expected_page || rgb !== expected_rgb)
                $fatal(1, "Graphics %0s: page %0d RGB %h, expected %0d %h",
                       case_name, dut.page, rgb, expected_page, expected_rgb);
            $fdisplay(graphics_fd, "%0s,%0d,%0d,%0d,%0d,%0d,%0d,%04h,%04h,PASS",
                      case_name, dut.page, blockx, blocky,
                      dut.maze_gram.on_maze, dut.maze_gram.maze_address,
                      dut.text_pixel, rgb, expected_rgb);
            checks = checks + 1;
        end
    endtask

    task switch_to(input [1:0] next_page);
        integer j;
        begin
            @(negedge clk); manual_sw = 1'b1;
            @(posedge clk); #1; page_sample("switch_edge", next_page);
            for (j = 0; j < 3; j = j + 1) begin
                @(posedge clk); #1; page_sample("switch_held", next_page);
            end
            @(negedge clk); manual_sw = 1'b0;
            @(posedge clk); #1; page_sample("switch_release", next_page);
        end
    endtask

    task reset_to_start;
        begin
            @(negedge clk); reboot = 1'b1;
            @(posedge clk); #1; page_sample("reset", 2'd0);
            @(negedge clk); reboot = 1'b0;
            @(posedge clk); #1; page_sample("reset_release", 2'd0);
        end
    endtask

    initial begin
        page_fd = $fopen("data/page_state_cases.csv", "w");
        graphics_fd = $fopen("data/graphics_cases.csv", "w");
        if (!page_fd || !graphics_fd) $fatal(1, "Cannot open test result CSVs");
        $fdisplay(page_fd, "time_ns,event,manual_sw,win,swpage,page,expected_page");
        $fdisplay(graphics_fd, "case,page,blockx,blocky,on_maze,maze_address,text_pixel,rgb,expected_rgb,result");
        $dumpfile("data/graphics_page.vcd");
        $dumpvars(0, graphics_page_tb);
        checks = 0;

        repeat (2) @(posedge clk);
        #1; page_sample("initial_reset", 2'd0);
        check_pixel("maze_glyph_on", 2'd0, 6'd17, 6'd14, 16'hFFFF);
        check_pixel("maze_glyph_off", 2'd0, 6'd16, 6'd14, 16'h0000);
        @(negedge clk); reboot = 1'b0;
        @(posedge clk); #1; page_sample("reset_release", 2'd0);

        switch_to(2'd1);
        check_pixel("player_red", 2'd1, 6'd25, 6'd13, 16'hF800);
        check_pixel("path_white", 2'd1, 6'd26, 6'd13, 16'hFFFF);
        check_pixel("wall_black", 2'd1, 6'd30, 6'd13, 16'h0000);
        check_pixel("outside_black", 2'd1, 6'd24, 6'd13, 16'h0000);

        @(negedge clk); win = 1'b1;
        @(posedge clk); #1; page_sample("win_edge", 2'd2);
        repeat (3) begin
            @(posedge clk); #1; page_sample("win_held", 2'd2);
        end
        @(negedge clk); win = 1'b0;
        @(posedge clk); #1; page_sample("win_release", 2'd2);
        switch_to(2'd3);
        switch_to(2'd0);

        switch_to(2'd1);
        switch_to(2'd2);
        reset_to_start();
        switch_to(2'd1);
        reset_to_start();
        switch_to(2'd1);
        switch_to(2'd2);
        switch_to(2'd3);
        reset_to_start();

        $fclose(page_fd);
        $fclose(graphics_fd);
        $display("PASS: graphics and page checks (%0d assertions)", checks);
        $finish;
    end
endmodule
