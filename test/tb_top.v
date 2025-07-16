module tb_top;
  reg clk = 0, reset = 0;
  always #5 clk = ~clk;

  top uut (
    .clk(clk),
    .reset(reset)
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_top);
    reset = 1; #10; reset = 0;
    #100;
    $finish;
  end
endmodule
