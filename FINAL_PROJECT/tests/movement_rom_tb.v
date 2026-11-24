`timescale 1ns / 1ps

module movement_rom_tb;
    reg [2:0] x = 0;
    reg [2:0] y = 0;
    reg [2:0] sample_id = 0;
    wire [3:0] movement;
    reg [3:0] expected [0:63];
    integer output_fd;
    integer i;
    integer failures = 0;

    MovementROM dut (.x(x), .y(y), .movement(movement));

    initial begin
        $dumpfile("data/movement_rom.vcd");
        $dumpvars(0, movement_rom_tb);
        $readmemh("data/expected_movement.hex", expected);
        output_fd = $fopen("data/movement_rom_sim.csv", "w");
        if (!output_fd) $fatal(1, "Cannot open ROM result CSV");
        $fdisplay(output_fd, "x,y,address,observed_bits,expected_bits,result");

        for (i = 0; i < 64; i = i + 1) begin
            x = i % 8;
            y = i / 8;
            #20;
            if (movement !== expected[i]) failures = failures + 1;
            $fdisplay(output_fd, "%0d,%0d,%0d,%04b,%04b,%s",
                      x, y, dut.address, movement, expected[i],
                      (movement === expected[i]) ? "PASS" : "FAIL");
        end

        sample_id = 1; x = 0; y = 0; #20;
        sample_id = 2; x = 1; y = 0; #20;
        sample_id = 3; x = 1; y = 1; #20;
        sample_id = 4; x = 7; y = 7; #20;

        $fclose(output_fd);
        if (failures) $fatal(1, "%0d ROM checks failed", failures);
        $display("PASS: MovementROM output matched map-derived values at all 64 coordinates");
        $finish;
    end
endmodule
