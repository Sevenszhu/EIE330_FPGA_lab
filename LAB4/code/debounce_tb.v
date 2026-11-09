`timescale 1ns/1ps

module debounce_tb;

reg  clk   = 0;
reg  btn   = 1;
reg  rst_n = 0;
wire pluse;
integer pulse_count = 0;

debounce dut (
    .btn   (btn),
    .clk   (clk),
    .rst_n (rst_n),
    .pluse (pluse)
);

always #10 clk = ~clk;  // 50 MHz
always @(posedge pluse) pulse_count = pulse_count + 1;

initial begin
    $dumpfile("debounce_tb.vcd");
    $dumpvars(0, debounce_tb);

    repeat (2) @(posedge clk);
    rst_n = 1;

    // 按下时产生几次机械毛刺。
    @(negedge clk) btn = 0;
    @(negedge clk) btn = 1;
    @(negedge clk) btn = 0;
    repeat (3) @(negedge clk);
    btn = 1;
    repeat (2) @(negedge clk);
    btn = 0;
    repeat (2) @(negedge clk);
    btn = 1;

    if (!pluse || pulse_count != 1) begin
        $display("FAIL: bounce caused a wrong pulse");
        $finish;
    end

    // 中间约 20 ms 不记录波形，避免 VCD 过大。
    $dumpoff;
    wait (dut.coldDownCount >= 21'd999990);
    $dumpon;
    wait (dut.stage == 2);
    @(posedge clk); #1;
    if (pluse || dut.stage != 0 || pulse_count != 1) begin
        $display("FAIL: cooldown did not finish correctly");
        $finish;
    end

    // 冷却结束后，下一次按下应再次触发。
    @(negedge clk) btn = 0;
    @(posedge clk); #1;
    if (!pluse || pulse_count != 2) begin
        $display("FAIL: second press was not detected");
        $finish;
    end

    // 多观察几个周期，再测试复位及复位后的空闲状态。
    repeat (20) @(posedge clk);
    @(negedge clk) begin
        btn   = 1;
        rst_n = 0;
    end
    repeat (5) @(posedge clk);
    #1;
    if (pluse || dut.stage != 0) begin
        $display("FAIL: reset failed");
        $finish;
    end

    @(negedge clk) rst_n = 1;
    repeat (10) @(posedge clk);
    #1;
    if (pluse || dut.stage != 0) begin
        $display("FAIL: idle state after reset is wrong");
        $finish;
    end

    $display("PASS: debounce glitches, cooldown and reset");
    $finish;
end

endmodule
