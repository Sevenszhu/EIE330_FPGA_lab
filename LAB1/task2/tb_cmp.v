`timescale 1ns/1ps
module tb_cmp;
    reg A;
    reg B;
    wire GT;
    wire EQ;
    wire LT;
    integer errors;
    
    cmp #(.INVERSE_INPUT(1),.INVERSE_OUT(1)) test (.A(A),.B(B),.GT(GT),.EQ(EQ),.LT(LT));
    
initial begin
    $dumpfile("wave_cmp.vcd");
    $dumpvars(0, tb_cmp);
    errors=0;
    $display("A B | GT EQ LT");
    A=0; B=0; #1 $display("%b %b |  %b  %b  %b",A,B,GT,EQ,LT); if ({GT,EQ,LT} !== 3'b101) errors=errors+1;
    #1 A=0; B=1; #1 $display("%b %b |  %b  %b  %b",A,B,GT,EQ,LT); if ({GT,EQ,LT} !== 3'b011) errors=errors+1;
    #1 A=1; B=0; #1 $display("%b %b |  %b  %b  %b",A,B,GT,EQ,LT); if ({GT,EQ,LT} !== 3'b110) errors=errors+1;
    #1 A=1; B=1; #1 $display("%b %b |  %b  %b  %b",A,B,GT,EQ,LT); if ({GT,EQ,LT} !== 3'b101) errors=errors+1;
    if (errors == 0)
        $display("PASS: cmp");
    else
        $display("FAIL: cmp, errors=%0d",errors);
    #1 ;
    $finish;
    end
endmodule
