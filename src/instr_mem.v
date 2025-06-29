module instr_mem (
    input [31:0] addr,            // PC input
    output [31:0] instruction     // output instruction
);
    reg [31:0] memory [0:255];    // 256 instructions = 1 KB of program memory

    assign instruction = memory[addr[9:2]]; // divide PC by 4 (right shift 2) to get index

    initial begin
        $readmemh("test/hex/fib.hex", memory); // load instructions from file
    end
endmodule
