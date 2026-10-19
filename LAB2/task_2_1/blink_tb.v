`timescale 1ns/1ps

module blink_tb;

    reg  clk;
    reg  rst_n;
    wire led;
    wire [24:0] debug_counter;

    blink #(
        .INIT_LED_HIZ(1'b1)
    ) dut (
        .clk   (clk),
        .rst_n         (rst_n),
        .led           (led),
        .debug_counter (debug_counter)
    );
    always #10 clk = ~clk;

    initial begin
        $dumpfile("blink_tb.vcd");
        $dumpvars(0, rst_n, led, debug_counter);
        clk   = 1'b0;
        rst_n = 1'b0;
        #25;
        rst_n = 1'b1;
        #(64'd3100000000);
        $finish;
    end

endmodule
