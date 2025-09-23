`timescale 1ns / 1ps

module top (
    input  wire clk,
    input  wire reset
);
    // -------------------------
    // Program Counter & Fetch
    // -------------------------
    wire [31:0] pc_out;
    wire [31:0] pc_next = pc_out + 32'd4;
    wire        pc_write = 1'b1;  // always advance for now

    pc u_pc (
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .pc_in(pc_next),
        .pc_out(pc_out)
    );

    wire [31:0] instruction;
    instr_mem u_imem (
        .addr(pc_out),
        .instruction(instruction)
    );

    // -------------------------
    // IF/ID Pipeline Register
    // -------------------------
    wire [31:0] pc_id;
    wire [31:0] instr_id;

    if_id u_if_id (
        .clk(clk),
        .reset(reset),
        .pc_in(pc_out),
        .instruction_in(instruction),
        .pc_out(pc_id),
        .instruction_out(instr_id)
    );

    // -------------------------
    // Decode stage
    // -------------------------
    wire [6:0]  opcode = instr_id[6:0];
    wire [4:0]  rd     = instr_id[11:7];
    wire [2:0]  funct3 = instr_id[14:12];
    wire [4:0]  rs1    = instr_id[19:15];
    wire [4:0]  rs2    = instr_id[24:20];
    wire [6:0]  funct7 = instr_id[31:25];

    // I-type immediate (sign-extended)
    wire [31:0] imm_i  = {{20{instr_id[31]}}, instr_id[31:20]};

    // Opcodes
    localparam OP_IMM = 7'b0010011; // ADDI, etc.
    localparam OP     = 7'b0110011; // ADD, SUB, etc.

    // ALU control encodings
    localparam ALU_AND = 4'b0000;
    localparam ALU_OR  = 4'b0001;
    localparam ALU_ADD = 4'b0010;
    localparam ALU_SUB = 4'b0110;
    localparam ALU_SLT = 4'b0111;
    localparam ALU_XOR = 4'b1000;
    localparam ALU_SLL = 4'b1001;

    // Decode → control
    reg        regwrite_r;
    reg [3:0]  alu_ctrl_r;
    reg        alu_src_imm_r;

    always @(*) begin
        regwrite_r    = 1'b0;
        alu_ctrl_r    = ALU_ADD;
        alu_src_imm_r = 1'b0;

        case (opcode)
            OP_IMM: begin
                if (funct3 == 3'b000) begin
                    regwrite_r    = 1'b1;     // ADDI
                    alu_ctrl_r    = ALU_ADD;
                    alu_src_imm_r = 1'b1;
                end
            end
            OP: begin
                if (funct3 == 3'b000) begin
                    regwrite_r = 1'b1;
                    if (funct7 == 7'b0100000)
                        alu_ctrl_r = ALU_SUB; // SUB
                    else
                        alu_ctrl_r = ALU_ADD; // ADD
                    alu_src_imm_r = 1'b0;
                end
            end
            default: begin
                regwrite_r    = 1'b0;
                alu_ctrl_r    = ALU_ADD;
                alu_src_imm_r = 1'b0;
            end
        endcase
    end

    // -------------------------
    // Register File
    // -------------------------
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] writeback_data;
    wire [31:0] debug_x5, debug_x6, debug_x7;

    regfile u_regfile (
        .clk(clk),
        .regwrite(regwrite_ex),  // note: from EX stage now
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd_ex),              // from EX stage
        .writedata(writeback_data),
        .readdata1(rs1_data),
        .readdata2(rs2_data),
        .debug_x5(debug_x5),
        .debug_x6(debug_x6),
        .debug_x7(debug_x7)
    );

    // -------------------------
    // ID/EX Pipeline Register
    // -------------------------
    wire        regwrite_ex, memread_ex, memwrite_ex, memtoreg_ex, alu_src_imm_ex;
    wire [3:0]  alu_ctrl_ex;
    wire [31:0] pc_ex, rs1_data_ex, rs2_data_ex, imm_ex;
    wire [4:0]  rs1_ex, rs2_ex, rd_ex;

    id_ex u_id_ex (
        .clk(clk),
        .reset(reset),

        // control
        .regwrite_in(regwrite_r),
        .memread_in(1'b0),   // not hooked yet
        .memwrite_in(1'b0),  // not hooked yet
        .memtoreg_in(1'b0),  // not hooked yet
        .alu_ctrl_in(alu_ctrl_r),
        .alu_src_imm_in(alu_src_imm_r),

        // data
        .pc_in(pc_id),
        .rs1_data_in(rs1_data),
        .rs2_data_in(rs2_data),
        .imm_in(imm_i),

        // register numbers
        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),

        // outputs
        .regwrite_out(regwrite_ex),
        .memread_out(memread_ex),
        .memwrite_out(memwrite_ex),
        .memtoreg_out(memtoreg_ex),
        .alu_ctrl_out(alu_ctrl_ex),
        .alu_src_imm_out(alu_src_imm_ex),
        .pc_out(pc_ex),
        .rs1_data_out(rs1_data_ex),
        .rs2_data_out(rs2_data_ex),
        .imm_out(imm_ex),
        .rs1_out(rs1_ex),
        .rs2_out(rs2_ex),
        .rd_out(rd_ex)
    );

    // -------------------------
    // Execute Stage (ALU)
    // -------------------------
    wire [31:0] alu_b = (alu_src_imm_ex) ? imm_ex : rs2_data_ex;
    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .A(rs1_data_ex),
        .B(alu_b),
        .ALUControl(alu_ctrl_ex),
        .Result(alu_result),
        .Zero(alu_zero)
    );

    // -------------------------
    // Writeback
    // -------------------------
    assign writeback_data = alu_result;

endmodule
