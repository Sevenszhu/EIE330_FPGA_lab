`timescale 1ns/1ps

module runningLED_tb;

    reg        clk;
    reg        rst_n;
    wire [3:0] led;
    wire [24:0] debug_counter;

    runningLED #(
        .INIT_LED_HIZ    (1'b1),
        .INVERSE_OUTPUT (1'b1)
    ) dut (
        .clk   (clk),
        .rst_n         (rst_n),
        .led           (led),
        .debug_counter (debug_counter)
    );


    always #10 clk = ~clk;

    initial begin
        $dumpfile("runningLED_tb.vcd");
        $dumpvars(0, rst_n, led, debug_counter, dut.state);
        clk   = 1'b0;
        rst_n = 1'b0;
        #25;
        rst_n = 1'b1;
        #(64'd3100000000);
        $finish;
    end

endmodule
