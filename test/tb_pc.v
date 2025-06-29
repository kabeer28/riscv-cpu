`timescale 1ns / 1ps
module tb_pc;

  reg clk, reset, stall;
  reg [31:0] next_pc;
  wire [31:0] pc;

  pc uut (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .next_pc(next_pc),
    .pc(pc)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    reset = 1;
    stall = 0;
    next_pc = 32'd0;

    #10 reset = 0;
    next_pc = 32'd4;
    #10;

    next_pc = 32'd8;
    #10;

    stall = 1;
    next_pc = 32'd12;
    #10;

    stall = 0;
    #10;

    $finish;
  end

endmodule
