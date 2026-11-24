`timescale 1ns / 1ps

module vga_timing_tb;
    localparam integer H_TOTAL = 800;
    localparam integer V_TOTAL = 525;
    localparam integer FRAME_PIXELS = H_TOTAL * V_TOTAL;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire h_sync;
    wire v_sync;
    wire [5:0] blockx;
    wire [5:0] blocky;

    time sys_t1, sys_t2, pixel_t1, pixel_t2, frame_t0;
    time line_period_ns, frame_period_ns;
    integer h_max, v_max;
    integer h_sync_pixels, v_sync_lines;
    integer block_width_pixels, block_height_lines;
    integer results_fd, events_fd;
    integer i;

    always #10 clk = ~clk;

    vga dut (
        .clk(clk),
        .rst_n(rst_n),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .blockx(blockx),
        .blocky(blocky)
    );

    task log_event(input integer pixel_index);
        begin
            $fdisplay(events_fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                      $time - frame_t0, pixel_index, dut.h_count,
                      dut.v_count, h_sync, v_sync, blockx, blocky);
        end
    endtask

    initial begin
        results_fd = $fopen("data/results/vga_timing_results.csv", "w");
        events_fd = $fopen("data/traces/vga_timing_events.csv", "w");
        if (!results_fd || !events_fd)
            $fatal(1, "Cannot open output CSV files; create the data directory first.");

        $fdisplay(results_fd, "test_item,measured_value,unit,expected_value,result");
        $fdisplay(events_fd, "time_ns,pixel_index,h_count,v_count,h_sync,v_sync,blockx,blocky");

        @(posedge clk); #1; sys_t1 = $time;
        @(posedge clk); #1; sys_t2 = $time;
        @(posedge dut.clk25); #1; pixel_t1 = $time;
        @(posedge dut.clk25); #1; pixel_t2 = $time;

        @(posedge dut.clk25); #1;
        frame_t0 = $time;
        if (dut.h_count !== 0 || dut.v_count !== 0)
            $fatal(1, "Reset did not align counters to zero.");
        h_max = 0;
        v_max = 0;
        h_sync_pixels = h_sync ? 1 : 0;
        v_sync_lines = v_sync ? 1 : 0;
        line_period_ns = 0;
        frame_period_ns = 0;
        block_width_pixels = 0;
        block_height_lines = 0;
        log_event(0);
        rst_n = 1'b1;

        for (i = 1; i <= FRAME_PIXELS; i = i + 1) begin
            @(posedge dut.clk25); #1;

            if (dut.h_count > h_max) h_max = dut.h_count;
            if (dut.v_count > v_max) v_max = dut.v_count;

            if (i < H_TOTAL && h_sync) h_sync_pixels = h_sync_pixels + 1;
            if (i < FRAME_PIXELS && dut.h_count == 0 && v_sync)
                v_sync_lines = v_sync_lines + 1;

            if (i == H_TOTAL) line_period_ns = $time - frame_t0;
            if (i == FRAME_PIXELS) frame_period_ns = $time - frame_t0;

            if (block_width_pixels == 0 && blockx == 1 && dut.v_count == 0)
                block_width_pixels = dut.h_count;
            if (block_height_lines == 0 && blocky == 1 && dut.h_count == 0)
                block_height_lines = dut.v_count;

            if (i == 15 || i == 16 || i == 95 || i == 96 ||
                i == 799 || i == 800 || i == 1599 || i == 1600 ||
                i == 12799 || i == 12800 || i == 419199 ||
                i == 419200 || i == FRAME_PIXELS)
                log_event(i);
        end

        $fdisplay(results_fd, "system_clock_period,%0d,ns,20,%s",
                  sys_t2 - sys_t1,
                  (sys_t2 - sys_t1 == 20) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "pixel_clock_period,%0d,ns,40,%s",
                  pixel_t2 - pixel_t1,
                  (pixel_t2 - pixel_t1 == 40) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "horizontal_counter_max,%0d,count,799,%s",
                  h_max, (h_max == 799) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "vertical_counter_max,%0d,count,524,%s",
                  v_max, (v_max == 524) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "horizontal_sync_pulse,%0d,pixel_clocks,96,%s",
                  h_sync_pixels, (h_sync_pixels == 96) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "vertical_sync_pulse,%0d,scan_lines,2,%s",
                  v_sync_lines, (v_sync_lines == 2) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "line_period,%0d,ns,32000,%s",
                  line_period_ns, (line_period_ns == 32000) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "frame_period,%0d,ns,16800000,%s",
                  frame_period_ns, (frame_period_ns == 16800000) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "block_width,%0d,pixels,16,%s",
                  block_width_pixels, (block_width_pixels == 16) ? "PASS" : "FAIL");
        $fdisplay(results_fd, "block_height,%0d,scan_lines,16,%s",
                  block_height_lines, (block_height_lines == 16) ? "PASS" : "FAIL");

        $fclose(results_fd);
        $fclose(events_fd);

        if (sys_t2 - sys_t1 != 20 || pixel_t2 - pixel_t1 != 40 ||
            h_max != 799 || v_max != 524 || h_sync_pixels != 96 ||
            v_sync_lines != 2 || line_period_ns != 32000 ||
            frame_period_ns != 16800000 || block_width_pixels != 16 ||
            block_height_lines != 16)
            $fatal(1, "VGA timing check failed. See data/results/vga_timing_results.csv.");

        $display("PASS: all VGA timing checks; measured data written to data/results/ and data/traces/");
        $finish;
    end
endmodule
