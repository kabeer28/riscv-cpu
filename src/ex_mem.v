`timescale 1ns / 1ps
`default_nettype none

module ex_mem (
    input wire clk,
    input wire reset,
    input wire regwrite_in,
    input wire memread_in,
    input wire memwrite_in,
    input wire memtoreg_in,
    input wire [31:0] alu_result_in,
    input wire [31:0] rs2_data_in,
    input wire [4:0] rd_in,
    output reg regwrite_out,
    output reg memread_out,
    output reg memwrite_out,
    output reg memtoreg_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0] rd_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regwrite_out <= 1'b0;
            memread_out <= 1'b0;
            memwrite_out <= 1'b0;
            memtoreg_out <= 1'b0;
            alu_result_out <= 32'b0;
            rs2_data_out <= 32'b0;
            rd_out <= 5'b0;
        end else begin
            regwrite_out <= regwrite_in;
            memread_out <= memread_in;
            memwrite_out <= memwrite_in;
            memtoreg_out <= memtoreg_in;
            alu_result_out <= alu_result_in;
            rs2_data_out <= rs2_data_in;
            rd_out <= rd_in;
        end
    end
endmodule

`default_nettype wire
