`timescale 1ns/1ps
`default_nettype none
// Simple word-addressed data memory: supports lw/sw (funct3=010).
module data_mem (
    input  wire        clk,
    input  wire        memwrite,
    input  wire        memread,
    input  wire [31:0] addr,        // byte address from ALU (uses addr[9:2])
    input  wire [31:0] writedata,   // store data (from rs2)
    output reg  [31:0] readdata     // load data (to regfile)
);
    // 1 KB = 256 words (adjust as you like)
    reg [31:0] dmem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            dmem[i] = 32'b0;
    end

    // Combinational read (word-aligned)
    always @(*) begin
        if (memread)
            readdata = dmem[addr[9:2]];
        else
            readdata = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (memwrite)
            dmem[addr[9:2]] <= writedata;
    end
endmodule

`default_nettype wire
