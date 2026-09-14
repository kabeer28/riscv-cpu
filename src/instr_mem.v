`timescale 1ns / 1ps
`default_nettype none

module instr_mem #(
    parameter MEM_FILE = ""
) (
    input [31:0] addr,            // PC input
    output [31:0] instruction     // output instruction
);
    reg [31:0] memory [0:255];    // 256 instructions = 1 KB of program memory

    assign instruction = memory[addr[9:2]]; // divide PC by 4 (right shift 2) to get index

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000013;
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, memory);
    end
endmodule

`default_nettype wire
