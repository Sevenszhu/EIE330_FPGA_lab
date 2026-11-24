`timescale 1ns / 1ps

module vga_waveform_tb;
    localparam integer FRAME_PIXELS = 800 * 525;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire h_sync, v_sync;
    wire [5:0] blockx, blocky;
    integer fd, i, sample_count;
    vga dut (.clk(clk), .rst_n(rst_n), .h_sync(h_sync),
             .v_sync(v_sync), .blockx(blockx), .blocky(blocky));
    always #10 clk = ~clk;

    task sample(input integer pixel_index);
        begin
            $fdisplay(fd, "pixel,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                      $time, pixel_index, dut.h_count, dut.v_count,
                      clk, dut.clk25, h_sync, v_sync, blockx, blocky);
            sample_count = sample_count + 1;
        end
    endtask

    initial begin
        fd = $fopen("data/traces/vga_waveform_samples.csv", "w");
        if (!fd) $fatal(1, "Cannot open VGA sample CSV");
        $fdisplay(fd, "kind,time_ns,pixel_index,h_count,v_count,clk,clk25,h_sync,v_sync,blockx,blocky");
        sample_count = 0;
        repeat (16) begin
            @(posedge clk or negedge clk); #1;
            $fdisplay(fd, "clock,%0d,-1,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                      $time, dut.h_count, dut.v_count, clk, dut.clk25,
                      h_sync, v_sync, blockx, blocky);
        end
        @(posedge dut.clk25); #1;
        if (dut.h_count !== 0 || dut.v_count !== 0)
            $fatal(1, "Reset counter alignment failed");
        sample(0);
        rst_n = 1'b1;

        for (i = 1; i <= FRAME_PIXELS; i = i + 1) begin
            @(posedge dut.clk25); #1;
            if (i <= 112 || (i >= 789 && i <= 811) ||
                i == 16 || i == 12800 ||
                (dut.h_count == 0 &&
                 (dut.v_count <= 3 || dut.v_count >= 522)) ||
                i >= FRAME_PIXELS - 3)
                sample(i);
        end
        if (dut.h_count !== 0 || dut.v_count !== 0 ||
            h_sync !== 1'b1 || v_sync !== 1'b1)
            $fatal(1, "Frame wrap failed");
        $fclose(fd);
        $display("PASS: VGA waveform checkpoints captured (%0d pixel samples)", sample_count);
        $finish;
    end
endmodule
