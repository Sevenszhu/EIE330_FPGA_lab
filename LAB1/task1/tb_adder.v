`timescale 1ns/1ps
module tb_adder;
    reg A;
    reg B;
    reg C;
    wire O0;
    wire carry;
    integer errors;
    
    adder #(.INVERSE_INPUT(1),.INVERSE_OUT(1)) test (.A(A),.B(B),.C(C),.O0(O0),.carry(carry));
    
initial begin
    $dumpfile("wave_adder.vcd");
    $dumpvars(0, tb_adder);
    errors=0;
    $display("A B C | O0 carry");
    A=0; B=0; C=0; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b00) errors=errors+1;
    #1 A=0; B=0; C=1; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b01) errors=errors+1;
    #1 A=0; B=1; C=0; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b01) errors=errors+1;
    #1 A=0; B=1; C=1; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b10) errors=errors+1;
    #1 A=1; B=0; C=0; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b01) errors=errors+1;
    #1 A=1; B=0; C=1; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b10) errors=errors+1;
    #1 A=1; B=1; C=0; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b10) errors=errors+1;
    #1 A=1; B=1; C=1; #1 $display("%b %b %b |  %b   %b",A,B,C,O0,carry); if ({carry,O0} !== 2'b11) errors=errors+1;
    if (errors == 0)
        $display("PASS: adder");
    else
        $display("FAIL: adder, errors=%0d",errors);
    #1 ;
    $finish;
    end
endmodule
