`timescale 1ns / 1ps

module id_ex (
    input  wire        clk,
    input  wire        reset,

    // Control signals
    input  wire        regwrite_in,
    input  wire        memread_in,
    input  wire        memwrite_in,
    input  wire        memtoreg_in,
    input  wire [3:0]  alu_ctrl_in,
    input  wire        alu_src_imm_in,

    // Data signals
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,

    // Register numbers
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,

    // Outputs
    output reg         regwrite_out,
    output reg         memread_out,
    output reg         memwrite_out,
    output reg         memtoreg_out,
    output reg  [3:0]  alu_ctrl_out,
    output reg         alu_src_imm_out,

    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out,

    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regwrite_out   <= 0;
            memread_out    <= 0;
            memwrite_out   <= 0;
            memtoreg_out   <= 0;
            alu_ctrl_out   <= 0;
            alu_src_imm_out<= 0;
            pc_out         <= 0;
            rs1_data_out   <= 0;
            rs2_data_out   <= 0;
            imm_out        <= 0;
            rs1_out        <= 0;
            rs2_out        <= 0;
            rd_out         <= 0;
        end else begin
            regwrite_out   <= regwrite_in;
            memread_out    <= memread_in;
            memwrite_out   <= memwrite_in;
            memtoreg_out   <= memtoreg_in;
            alu_ctrl_out   <= alu_ctrl_in;
            alu_src_imm_out<= alu_src_imm_in;
            pc_out         <= pc_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_out        <= imm_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
        end
    end
endmodule
