`timescale 1ns/1ps

module GramManager_tb;

reg         clk    = 0;
reg         sw     = 0;
reg         reboot = 0;
reg  [6:0]  blockx = 0;
reg  [5:0]  blocky = 0;
wire [15:0] rgb;

GramManager dut (
    .sw     (sw),
    .clk    (clk),
    .reboot (reboot),
    .blockx (blockx),
    .blocky (blocky),
    .rgb    (rgb)
);

always #10 clk = ~clk;

task press_and_check;
    input [1:0] expected_page;
    begin
        @(negedge clk) sw = 1;
        @(posedge clk); #1;
        if (dut.pages != expected_page) begin
            $display("FAIL: expected page %0d, got %0d",
                     expected_page, dut.pages);
            $finish;
        end
        @(negedge clk) sw = 0;
        @(posedge clk); #1;
    end
endtask

initial begin
    $dumpfile("GramManager_tb.vcd");
    $dumpvars(0, GramManager_tb);

    repeat (2) @(posedge clk);
    reboot = 1;
    @(posedge clk); #1;

    press_and_check(1);
    press_and_check(2);
    press_and_check(0);

    // 保持高电平多个周期也只能切换一次。
    @(negedge clk) sw = 1;
    repeat (4) @(posedge clk);
    #1;
    if (dut.pages != 1) begin
        $display("FAIL: held switch changed page more than once");
        $finish;
    end
    @(negedge clk) sw = 0;
    @(posedge clk);

    // 低电平 reboot 应异步回到第 0 页。
    reboot = 0; #1;
    if (dut.pages != 0) begin
        $display("FAIL: reboot did not return to page 0");
        $finish;
    end

    $display("PASS: GramManager page sequence and reboot");
    $finish;
end

endmodule
