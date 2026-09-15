`timescale 1ns / 1ps
`default_nettype none

module id_ex (
    input clk,
    input reset,

    //control signals
    input regwrite_in,
    input branch_in,
    input jump_in,
    input jump_reg_in,
    input memread_in,
    input memwrite_in,
    input memtoreg_in,
    input alu_src_imm_in,
    input [1:0] alu_a_sel_in,

    //data signals
    input [31:0] pc_in,
    input [31:0] rs1_data_in,
    input [31:0] rs2_data_in,
    input [31:0] imm_i_in,
    input [31:0] imm_b_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [2:0] funct3_in,
    input [3:0] alu_ctrl_in,

    //outputs
    output reg regwrite_out,
    output reg branch_out,
    output reg jump_out,
    output reg jump_reg_out,
    output reg memread_out,
    output reg memwrite_out,
    output reg memtoreg_out,
    output reg alu_src_imm_out,
    output reg [1:0] alu_a_sel_out,

    output reg [31:0] pc_out,
    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] imm_i_out,
    output reg [31:0] imm_b_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [2:0] funct3_out,
    output reg [3:0] alu_ctrl_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regwrite_out   <= 0;
            branch_out     <= 0;
            jump_out       <= 0;
            jump_reg_out   <= 0;
            memread_out    <= 0;
            memwrite_out   <= 0;
            memtoreg_out   <= 0;
            alu_src_imm_out<= 0;
            alu_a_sel_out  <= 0;

            pc_out         <= 0;
            rs1_data_out   <= 0;
            rs2_data_out   <= 0;
            imm_i_out      <= 0;
            imm_b_out      <= 0;
            rs1_out        <= 0;
            rs2_out        <= 0;
            rd_out         <= 0;
            funct3_out     <= 0;
            alu_ctrl_out   <= 0;
        end else begin
            regwrite_out   <= regwrite_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            jump_reg_out   <= jump_reg_in;
            memread_out    <= memread_in;
            memwrite_out   <= memwrite_in;
            memtoreg_out   <= memtoreg_in;
            alu_src_imm_out<= alu_src_imm_in;
            alu_a_sel_out  <= alu_a_sel_in;

            pc_out         <= pc_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_i_out      <= imm_i_in;
            imm_b_out      <= imm_b_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            alu_ctrl_out   <= alu_ctrl_in;
        end
    end
endmodule

`default_nettype wire
