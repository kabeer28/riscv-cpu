`timescale 1ns / 1ps
`default_nettype none

module top #(
    parameter IMEM_FILE = ""
) (
    input wire clk,
    input wire reset
);
    localparam OP_IMM = 7'b0010011;
    localparam OP     = 7'b0110011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
    localparam LUI    = 7'b0110111;
    localparam AUIPC  = 7'b0010111;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;

    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_SUB  = 4'b0110;
    localparam ALU_SLT  = 4'b0111;
    localparam ALU_XOR  = 4'b1000;
    localparam ALU_SLL  = 4'b1001;
    localparam ALU_SRL  = 4'b1010;
    localparam ALU_SRA  = 4'b1011;
    localparam ALU_SLTU = 4'b1100;

    localparam ALU_A_RS1  = 2'b00;
    localparam ALU_A_PC   = 2'b01;
    localparam ALU_A_ZERO = 2'b10;

    wire [31:0] pc_out, pc_plus4, pc_next, instruction;
    wire hazard_pc_write, pc_write, if_id_write, if_id_flush;

    wire [31:0] if_id_pc, if_id_instruction;
    wire [6:0] opcode, funct7;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j, alu_imm, control_imm;
    wire [31:0] rs1_data, rs2_data;
    reg regwrite, memread, memwrite, memtoreg, branch, jump, jump_reg;
    reg alu_src_imm;
    reg [3:0] alu_ctrl;
    reg [1:0] alu_a_sel;
    reg uses_rs1, uses_rs2;
    wire control_stall, kill_controls;

    wire [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data;
    wire [31:0] id_ex_imm_i, id_ex_imm_b;
    wire [4:0] id_ex_rd, id_ex_rs1, id_ex_rs2;
    wire [2:0] id_ex_funct3;
    wire [3:0] id_ex_alu_ctrl;
    wire [1:0] id_ex_alu_a_sel;
    wire id_ex_regwrite, id_ex_memread, id_ex_memwrite;
    wire id_ex_memtoreg, id_ex_branch, id_ex_jump, id_ex_jump_reg;
    wire id_ex_alu_src_imm;
    wire [1:0] forward_a, forward_b;
    reg [31:0] forwarded_rs1, forwarded_rs2;
    reg [31:0] alu_a;
    wire [31:0] alu_b, alu_result, execute_result;
    reg branch_condition;
    wire branch_taken, redirect_taken;
    wire [31:0] branch_target, jump_target, redirect_target;

    wire [31:0] ex_mem_alu_result, ex_mem_rs2_data;
    wire [4:0] ex_mem_rd;
    wire ex_mem_regwrite, ex_mem_memread, ex_mem_memwrite, ex_mem_memtoreg;
    wire [31:0] mem_read_data;

    wire [31:0] mem_wb_read_data_out, mem_wb_alu_result_out;
    wire [4:0] mem_wb_rd_out;
    wire mem_wb_regwrite_out, mem_wb_memtoreg_out;
    wire [31:0] writeback_data;

    assign pc_plus4    = pc_out + 32'd4;
    assign pc_next     = redirect_taken ? redirect_target : pc_plus4;
    assign pc_write    = hazard_pc_write | redirect_taken;
    assign if_id_flush = redirect_taken;

    pc u_pc (
        .clk(clk), .reset(reset), .pc_write(pc_write),
        .pc_in(pc_next), .pc_out(pc_out)
    );

    instr_mem #(.MEM_FILE(IMEM_FILE)) u_imem (
        .addr(pc_out), .instruction(instruction)
    );

    if_id u_if_id (
        .clk(clk), .reset(reset), .if_id_write(if_id_write),
        .if_id_flush(if_id_flush), .pc_in(pc_out),
        .instruction_in(instruction), .pc_out(if_id_pc),
        .instruction_out(if_id_instruction)
    );

    assign opcode = if_id_instruction[6:0];
    assign rd      = if_id_instruction[11:7];
    assign funct3  = if_id_instruction[14:12];
    assign rs1     = if_id_instruction[19:15];
    assign rs2     = if_id_instruction[24:20];
    assign funct7  = if_id_instruction[31:25];
    assign imm_i   = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
    assign imm_s   = {{20{if_id_instruction[31]}}, if_id_instruction[31:25],
                      if_id_instruction[11:7]};
    assign imm_b   = {{19{if_id_instruction[31]}}, if_id_instruction[31],
                      if_id_instruction[7], if_id_instruction[30:25],
                      if_id_instruction[11:8], 1'b0};
    assign imm_u   = {if_id_instruction[31:12], 12'b0};
    assign imm_j   = {{11{if_id_instruction[31]}}, if_id_instruction[31],
                      if_id_instruction[19:12], if_id_instruction[20],
                      if_id_instruction[30:21], 1'b0};
    assign alu_imm = ((opcode == LUI) || (opcode == AUIPC)) ? imm_u :
                     (opcode == STORE) ? imm_s : imm_i;
    assign control_imm = (opcode == JAL) ? imm_j : imm_b;

    always @(*) begin
        regwrite = 1'b0;
        memread = 1'b0;
        memwrite = 1'b0;
        memtoreg = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        jump_reg = 1'b0;
        alu_src_imm = 1'b0;
        alu_ctrl = ALU_ADD;
        alu_a_sel = ALU_A_RS1;
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        case (opcode)
            OP_IMM: begin
                uses_rs1 = 1'b1;
                alu_src_imm = 1'b1;
                case (funct3)
                    3'b000: begin regwrite = 1'b1; alu_ctrl = ALU_ADD;  end
                    3'b010: begin regwrite = 1'b1; alu_ctrl = ALU_SLT;  end
                    3'b011: begin regwrite = 1'b1; alu_ctrl = ALU_SLTU; end
                    3'b100: begin regwrite = 1'b1; alu_ctrl = ALU_XOR;  end
                    3'b110: begin regwrite = 1'b1; alu_ctrl = ALU_OR;   end
                    3'b111: begin regwrite = 1'b1; alu_ctrl = ALU_AND;  end
                    3'b001: if (funct7 == 7'b0000000) begin
                        regwrite = 1'b1;
                        alu_ctrl = ALU_SLL;
                    end
                    3'b101: if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                        regwrite = 1'b1;
                        alu_ctrl = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
                    end
                    default: begin end
                endcase
            end
            OP: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: begin regwrite = 1'b1; alu_ctrl = ALU_ADD;  end
                    {7'b0100000, 3'b000}: begin regwrite = 1'b1; alu_ctrl = ALU_SUB;  end
                    {7'b0000000, 3'b001}: begin regwrite = 1'b1; alu_ctrl = ALU_SLL;  end
                    {7'b0000000, 3'b010}: begin regwrite = 1'b1; alu_ctrl = ALU_SLT;  end
                    {7'b0000000, 3'b011}: begin regwrite = 1'b1; alu_ctrl = ALU_SLTU; end
                    {7'b0000000, 3'b100}: begin regwrite = 1'b1; alu_ctrl = ALU_XOR;  end
                    {7'b0000000, 3'b101}: begin regwrite = 1'b1; alu_ctrl = ALU_SRL;  end
                    {7'b0100000, 3'b101}: begin regwrite = 1'b1; alu_ctrl = ALU_SRA;  end
                    {7'b0000000, 3'b110}: begin regwrite = 1'b1; alu_ctrl = ALU_OR;   end
                    {7'b0000000, 3'b111}: begin regwrite = 1'b1; alu_ctrl = ALU_AND;  end
                    default: begin end
                endcase
            end
            LOAD: begin
                uses_rs1 = 1'b1;
                if (funct3 == 3'b010) begin
                    regwrite = 1'b1;
                    memread = 1'b1;
                    memtoreg = 1'b1;
                    alu_src_imm = 1'b1;
                end
            end
            STORE: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                if (funct3 == 3'b010) begin
                    memwrite = 1'b1;
                    alu_src_imm = 1'b1;
                end
            end
            BRANCH: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: branch = 1'b1;
                    default: branch = 1'b0;
                endcase
            end
            LUI: begin
                regwrite = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel = ALU_A_ZERO;
            end
            AUIPC: begin
                regwrite = 1'b1;
                alu_src_imm = 1'b1;
                alu_a_sel = ALU_A_PC;
            end
            JAL: begin
                regwrite = 1'b1;
                jump = 1'b1;
            end
            JALR: begin
                uses_rs1 = 1'b1;
                if (funct3 == 3'b000) begin
                    regwrite = 1'b1;
                    jump = 1'b1;
                    jump_reg = 1'b1;
                    alu_src_imm = 1'b1;
                end
            end
            default: begin end
        endcase
    end

    regfile u_regfile (
        .clk(clk), .reset(reset), .regwrite(mem_wb_regwrite_out),
        .rs1(rs1), .rs2(rs2), .rd(mem_wb_rd_out),
        .writedata(writeback_data), .readdata1(rs1_data),
        .readdata2(rs2_data)
    );

    hazard_unit u_hazard (
        .id_ex_memread(id_ex_memread), .id_ex_rd(id_ex_rd),
        .if_id_rs1(rs1), .if_id_rs2(rs2),
        .if_id_uses_rs1(uses_rs1), .if_id_uses_rs2(uses_rs2),
        .pc_write(hazard_pc_write), .if_id_write(if_id_write),
        .control_stall(control_stall)
    );

    assign kill_controls = control_stall | redirect_taken;

    id_ex u_id_ex (
        .clk(clk), .reset(reset), .pc_in(if_id_pc),
        .rs1_data_in(rs1_data), .rs2_data_in(rs2_data),
        .imm_i_in(alu_imm), .imm_b_in(control_imm), .rd_in(rd),
        .rs1_in(rs1), .rs2_in(rs2), .funct3_in(funct3),
        .regwrite_in(kill_controls ? 1'b0 : regwrite),
        .memread_in(kill_controls ? 1'b0 : memread),
        .memwrite_in(kill_controls ? 1'b0 : memwrite),
        .memtoreg_in(kill_controls ? 1'b0 : memtoreg),
        .branch_in(kill_controls ? 1'b0 : branch),
        .jump_in(kill_controls ? 1'b0 : jump),
        .jump_reg_in(kill_controls ? 1'b0 : jump_reg),
        .alu_src_imm_in(kill_controls ? 1'b0 : alu_src_imm),
        .alu_a_sel_in(kill_controls ? ALU_A_RS1 : alu_a_sel),
        .alu_ctrl_in(kill_controls ? ALU_ADD : alu_ctrl),
        .pc_out(id_ex_pc), .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data), .imm_i_out(id_ex_imm_i),
        .imm_b_out(id_ex_imm_b), .rd_out(id_ex_rd),
        .rs1_out(id_ex_rs1), .rs2_out(id_ex_rs2),
        .funct3_out(id_ex_funct3),
        .regwrite_out(id_ex_regwrite), .memread_out(id_ex_memread),
        .memwrite_out(id_ex_memwrite), .memtoreg_out(id_ex_memtoreg),
        .branch_out(id_ex_branch), .jump_out(id_ex_jump),
        .jump_reg_out(id_ex_jump_reg), .alu_src_imm_out(id_ex_alu_src_imm),
        .alu_a_sel_out(id_ex_alu_a_sel),
        .alu_ctrl_out(id_ex_alu_ctrl)
    );

    forwarding_unit u_forwarding (
        .ex_mem_regwrite(ex_mem_regwrite), .ex_mem_memtoreg(ex_mem_memtoreg),
        .ex_mem_rd(ex_mem_rd), .mem_wb_regwrite(mem_wb_regwrite_out),
        .mem_wb_rd(mem_wb_rd_out), .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2), .forward_a(forward_a), .forward_b(forward_b)
    );

    always @(*) begin
        case (forward_a)
            2'b10: forwarded_rs1 = ex_mem_alu_result;
            2'b01: forwarded_rs1 = writeback_data;
            default: forwarded_rs1 = id_ex_rs1_data;
        endcase
        case (forward_b)
            2'b10: forwarded_rs2 = ex_mem_alu_result;
            2'b01: forwarded_rs2 = writeback_data;
            default: forwarded_rs2 = id_ex_rs2_data;
        endcase
    end

    always @(*) begin
        case (id_ex_alu_a_sel)
            ALU_A_PC: alu_a = id_ex_pc;
            ALU_A_ZERO: alu_a = 32'b0;
            default: alu_a = forwarded_rs1;
        endcase
    end

    assign alu_b = id_ex_alu_src_imm ? id_ex_imm_i : forwarded_rs2;

    alu u_alu (
        .A(alu_a), .B(alu_b), .ALUControl(id_ex_alu_ctrl),
        .Result(alu_result), .Zero()
    );

    always @(*) begin
        case (id_ex_funct3)
            3'b000: branch_condition = (forwarded_rs1 == forwarded_rs2);
            3'b001: branch_condition = (forwarded_rs1 != forwarded_rs2);
            3'b100: branch_condition = ($signed(forwarded_rs1) < $signed(forwarded_rs2));
            3'b101: branch_condition = ($signed(forwarded_rs1) >= $signed(forwarded_rs2));
            3'b110: branch_condition = (forwarded_rs1 < forwarded_rs2);
            3'b111: branch_condition = (forwarded_rs1 >= forwarded_rs2);
            default: branch_condition = 1'b0;
        endcase
    end

    assign branch_taken  = id_ex_branch && branch_condition;
    assign branch_target = id_ex_pc + id_ex_imm_b;
    assign jump_target = id_ex_jump_reg ?
                         ((forwarded_rs1 + id_ex_imm_i) & 32'hfffffffe) :
                         (id_ex_pc + id_ex_imm_b);
    assign redirect_taken = branch_taken | id_ex_jump;
    assign redirect_target = id_ex_jump ? jump_target : branch_target;
    assign execute_result = id_ex_jump ? (id_ex_pc + 32'd4) : alu_result;

    ex_mem u_ex_mem (
        .clk(clk), .reset(reset), .alu_result_in(execute_result),
        .rs2_data_in(forwarded_rs2), .rd_in(id_ex_rd),
        .regwrite_in(id_ex_regwrite), .memread_in(id_ex_memread),
        .memwrite_in(id_ex_memwrite), .memtoreg_in(id_ex_memtoreg),
        .alu_result_out(ex_mem_alu_result), .rs2_data_out(ex_mem_rs2_data),
        .rd_out(ex_mem_rd), .regwrite_out(ex_mem_regwrite),
        .memread_out(ex_mem_memread), .memwrite_out(ex_mem_memwrite),
        .memtoreg_out(ex_mem_memtoreg)
    );

    data_mem u_dmem (
        .clk(clk), .memread(ex_mem_memread), .memwrite(ex_mem_memwrite),
        .addr(ex_mem_alu_result), .writedata(ex_mem_rs2_data),
        .readdata(mem_read_data)
    );

    mem_wb u_mem_wb (
        .clk(clk), .reset(reset), .read_data_in(mem_read_data),
        .alu_result_in(ex_mem_alu_result), .rd_in(ex_mem_rd),
        .regwrite_in(ex_mem_regwrite), .memtoreg_in(ex_mem_memtoreg),
        .read_data_out(mem_wb_read_data_out),
        .alu_result_out(mem_wb_alu_result_out), .rd_out(mem_wb_rd_out),
        .regwrite_out(mem_wb_regwrite_out), .memtoreg_out(mem_wb_memtoreg_out)
    );

    assign writeback_data = mem_wb_memtoreg_out ?
                            mem_wb_read_data_out : mem_wb_alu_result_out;
endmodule

`default_nettype wire
