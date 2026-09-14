`timescale 1ns / 1ps
`default_nettype none

module regfile (
    input clk,
    input reset,
    input regwrite,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] writedata,
    output [31:0] readdata1,
    output [31:0] readdata2
);
    reg [31:0] registers[0:31];
    integer i;

    // Read (combinational)
    assign readdata1 = (rs1 == 0) ? 32'd0 : registers[rs1];
    assign readdata2 = (rs2 == 0) ? 32'd0 : registers[rs2];
    // Write (synchronous)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else if (regwrite && rd != 0) begin
            registers[rd] <= writedata;
        end
    end
endmodule

`default_nettype wire
