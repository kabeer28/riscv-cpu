`timescale 1ns / 1ps

module top (
    input wire clk,
    input wire reset
);
    // 
    // stage 1: instruction fetch (IF)
    // 

    wire [31:0] pc_out, pc_next, instruction;
    wire pc_write = 1'b1;

    assign pc_next = pc_out + 32'd4;

    pc u_pc (
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .pc_in(pc_next),
        .pc_out(pc_out)
    );

    instr_mem u_imem (
        .addr(pc_out),
        .instruction(instruction)
    );

    // IF/ID pipeline register

    wire [31:0] if_id_pc, if_id_instruction;

    if_id u_if_id (
        .clk(clk),
        .reset(reset),
        .pc_in(pc_out),
        .instruction_in(instruction),
        .pc_out(if_id_pc),
        .instruction_out(if_id_instruction)
    );

    // 
    // stage 2: instruction decode (ID)
    // 

    wire [6:0] opcode = if_id_instruction[6:0];
    wire [4:0] rd     = if_id_instruction[11:7];
    wire [2:0] funct3 = if_id_instruction[14:12];
    wire [4:0] rs1    = if_id_instruction[19:15];
    wire [4:0] rs2    = if_id_instruction[24:20];
    wire [6:0] funct7 = if_id_instruction[31:25];

    wire [31:0] imm_i = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
    wire [31:0] imm_b = {{19{if_id_instruction[31]}}, if_id_instruction[31],
                          if_id_instruction[7], if_id_instruction[30:25],
                          if_id_instruction[11:8], 1'b0};

    //control signals
    reg regwrite, memread, memwrite, memtoreg, branch, alu_src_imm;
    reg [3:0] alu_ctrl;

    localparam OP_IMM = 7'b0010011; // I-type
    localparam OP     = 7'b0110011; // R-type
    localparam LOAD   = 7'b0000011; // LW
    localparam STORE  = 7'b0100011; // SW
    localparam BRANCH = 7'b1100011; // BEQ, BNE, BLT

    localparam ALU_ADD = 4'b0010;
    localparam ALU_SUB = 4'b0110;
    localparam ALU_SLT = 4'b0111;

    always @(*) begin
        //defaults
        regwrite = 0; memread = 0; memwrite = 0;
        memtoreg = 0; branch = 0; alu_src_imm = 0; alu_ctrl = ALU_ADD;

        case (opcode)
            OP_IMM: begin // ADDI
                if (funct3 == 3'b000) begin
                    regwrite = 1;
                    alu_src_imm = 1;
                    alu_ctrl = ALU_ADD;
                end
            end
            OP: begin // ADD/SUB
                regwrite = 1;
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_ctrl = ALU_ADD;
                    {7'b0100000, 3'b000}: alu_ctrl = ALU_SUB;
                    {7'b0000000, 3'b010}: alu_ctrl = ALU_SLT;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            LOAD: begin // LW
                regwrite = 1; memread = 1; memtoreg = 1; alu_src_imm = 1;
            end
            STORE: begin // SW
                memwrite = 1; alu_src_imm = 1;
            end
            BRANCH: begin // BEQ, BNE, BLT
                branch = 1; alu_ctrl = ALU_SUB;
            end
        endcase
    end

    // register file

    wire [31:0] rs1_data, rs2_data;
    wire [31:0] debug_x5, debug_x6, debug_x7;

    regfile u_regfile (
        .clk(clk),
        .regwrite(mem_wb_regwrite_out),
        .rs1(rs1),
        .rs2(rs2),
        .rd(mem_wb_rd_out),
        .writedata(writeback_data),
        .readdata1(rs1_data),
        .readdata2(rs2_data),
        .debug_x5(debug_x5),
        .debug_x6(debug_x6),
        .debug_x7(debug_x7)
    );

    // ID/EX Pipeline Register
    wire [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm_i, id_ex_imm_b;
    wire [4:0] id_ex_rd, id_ex_rs1, id_ex_rs2;
    wire [2:0] id_ex_funct3;
    wire [6:0] id_ex_funct7;
    wire [3:0] id_ex_alu_ctrl;
    wire id_ex_regwrite, id_ex_memread, id_ex_memwrite, id_ex_memtoreg, id_ex_branch, id_ex_alu_src_imm;

    id_ex u_id_ex (
        .clk(clk),
        .reset(reset),
        .pc_in(if_id_pc),
        .rs1_data_in(rs1_data),
        .rs2_data_in(rs2_data),
        .imm_i_in(imm_i),
        .imm_b_in(imm_b),
        .rd_in(rd),
        .rs1_in(rs1),
        .rs2_in(rs2),
        .funct3_in(funct3),
        .funct7_in(funct7),
        .regwrite_in(regwrite),
        .memread_in(memread),
        .memwrite_in(memwrite),
        .memtoreg_in(memtoreg),
        .branch_in(branch),
        .alu_src_imm_in(alu_src_imm),
        .alu_ctrl_in(alu_ctrl),

        .pc_out(id_ex_pc),
        .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data),
        .imm_i_out(id_ex_imm_i),
        .imm_b_out(id_ex_imm_b),
        .rd_out(id_ex_rd),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .funct3_out(id_ex_funct3),
        .funct7_out(id_ex_funct7),
        .regwrite_out(id_ex_regwrite),
        .memread_out(id_ex_memread),
        .memwrite_out(id_ex_memwrite),
        .memtoreg_out(id_ex_memtoreg),
        .branch_out(id_ex_branch),
        .alu_src_imm_out(id_ex_alu_src_imm),
        .alu_ctrl_out(id_ex_alu_ctrl)
    );

    // 
    // stage 3: execute (EX)
    // 

    wire [31:0] alu_b = id_ex_alu_src_imm ? id_ex_imm_i : id_ex_rs2_data;
    wire [31:0] alu_result;
    wire alu_zero;

    alu u_alu (
        .A(id_ex_rs1_data),
        .B(alu_b),
        .ALUControl(id_ex_alu_ctrl),
        .Result(alu_result),
        .Zero(alu_zero)
    );

    wire branch_taken = id_ex_branch &&
                       ((id_ex_funct3 == 3'b000 && alu_zero) ||      // BEQ
                        (id_ex_funct3 == 3'b001 && !alu_zero) ||     // BNE
                        (id_ex_funct3 == 3'b100 && alu_result[0]));  // BLT

    wire [31:0] branch_target = id_ex_pc + id_ex_imm_b;

    // EX/MEM pipeline register

    wire [31:0] ex_mem_alu_result, ex_mem_rs2_data, ex_mem_branch_target;
    wire [4:0]  ex_mem_rd;
    wire ex_mem_regwrite, ex_mem_memread, ex_mem_memwrite, ex_mem_memtoreg, ex_mem_branch, ex_mem_branch_taken;

    ex_mem u_ex_mem (
        .clk(clk),
        .reset(reset),
        .alu_result_in(alu_result),
        .rs2_data_in(id_ex_rs2_data),
        .rd_in(id_ex_rd),
        .regwrite_in(id_ex_regwrite),
        .memread_in(id_ex_memread),
        .memwrite_in(id_ex_memwrite),
        .memtoreg_in(id_ex_memtoreg),
        .branch_in(id_ex_branch),
        .branch_target_in(branch_target),
        .branch_taken_in(branch_taken),

        .alu_result_out(ex_mem_alu_result),
        .rs2_data_out(ex_mem_rs2_data),
        .rd_out(ex_mem_rd),
        .regwrite_out(ex_mem_regwrite),
        .memread_out(ex_mem_memread),
        .memwrite_out(ex_mem_memwrite),
        .memtoreg_out(ex_mem_memtoreg),
        .branch_out(ex_mem_branch),
        .branch_target_out(ex_mem_branch_target),
        .branch_taken_out(ex_mem_branch_taken)
    );

    // 
    // stage 4: memory (MEM)
    // 

    wire [31:0] mem_read_data;

    data_mem u_dmem (
        .clk(clk),
        .memread(ex_mem_memread),
        .memwrite(ex_mem_memwrite),
        .addr(ex_mem_alu_result),
        .writedata(ex_mem_rs2_data),
        .readdata(mem_read_data)
    );

    // MEM/WB pipeline register

    wire [31:0] mem_wb_read_data_out, mem_wb_alu_result_out;
    wire [4:0]  mem_wb_rd_out;
    wire mem_wb_regwrite_out, mem_wb_memtoreg_out;

    mem_wb u_mem_wb (
        .clk(clk),
        .reset(reset),
        .read_data_in(mem_read_data),
        .alu_result_in(ex_mem_alu_result),
        .rd_in(ex_mem_rd),
        .regwrite_in(ex_mem_regwrite),
        .memtoreg_in(ex_mem_memtoreg),

        .read_data_out(mem_wb_read_data_out),
        .alu_result_out(mem_wb_alu_result_out),
        .rd_out(mem_wb_rd_out),
        .regwrite_out(mem_wb_regwrite_out),
        .memtoreg_out(mem_wb_memtoreg_out)
    );

    // 
    // stage 5: write back (WB)
    // 

    wire [31:0] writeback_data = mem_wb_memtoreg_out ?
                                 mem_wb_read_data_out :
                                 mem_wb_alu_result_out;

endmodule
