`timescale 1ns / 1ps
`default_nettype none

module forwarding_unit (
    input  wire       ex_mem_regwrite,
    input  wire       ex_mem_memtoreg,
    input  wire [4:0] ex_mem_rd,
    input  wire       mem_wb_regwrite,
    input  wire [4:0] mem_wb_rd,
    input  wire [4:0] id_ex_rs1,
    input  wire [4:0] id_ex_rs2,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // A load's value is not available while it is in EX/MEM.
        if (ex_mem_regwrite && !ex_mem_memtoreg && (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1))
            forward_a = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs1))
            forward_a = 2'b01;

        if (ex_mem_regwrite && !ex_mem_memtoreg && (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2))
            forward_b = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs2))
            forward_b = 2'b01;
    end
endmodule

`default_nettype wire
