`timescale 1ns / 1ps
module tb_alu;

  reg [31:0] A, B;
  reg [3:0] ALUControl;
  wire [31:0] Result;
  wire Zero;

  alu uut (
    .A(A), 
    .B(B), 
    .ALUControl(ALUControl), 
    .Result(Result), 
    .Zero(Zero)
  );

  initial begin
    A = 32'd5;
    B = 32'd3;

    ALUControl = 4'b0010; // ADD
    #10;
    $display("A + B = %d", Result);

    ALUControl = 4'b0110; // SUB
    #10;
    $display("A - B = %d", Result);

    ALUControl = 4'b0000; // AND
    #10;
    $display("A & B = %d", Result);

    $finish;
  end

endmodule
