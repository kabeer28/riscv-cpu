`timescale 1ns / 1ps

module tb_top;
    reg clk;
    reg reset;
    integer failures;
    integer stall_count;
    integer taken_branch_count;
`ifdef TRACE
    integer cycle;
`endif

    localparam [6:0] OP_IMM = 7'b0010011;
    localparam [6:0] OP     = 7'b0110011;
    localparam [6:0] LOAD   = 7'b0000011;
    localparam [6:0] STORE  = 7'b0100011;
    localparam [6:0] BRANCH = 7'b1100011;

    top uut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    function [31:0] enc_i;
        input [31:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        enc_i = {imm[11:0], rs1, funct3, rd, opcode};
    endfunction

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        enc_r = {funct7, rs2, rs1, funct3, rd, OP};
    endfunction

    function [31:0] enc_s;
        input [31:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], STORE};
    endfunction

    function [31:0] enc_b;
        input [31:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3,
                 imm[4:1], imm[11], BRANCH};
    endfunction

    task expect_reg;
        input [4:0] index;
        input [31:0] expected;
        begin
            if (uut.u_regfile.registers[index] !== expected) begin
                $display("FAIL x%0d expected=%h got=%h", index, expected,
                         uut.u_regfile.registers[index]);
                failures = failures + 1;
            end
        end
    endtask

    always @(posedge clk) begin
        if (!reset) begin
            if (uut.control_stall)
                stall_count = stall_count + 1;
            if (uut.branch_taken)
                taken_branch_count = taken_branch_count + 1;
        end
    end

`ifdef TRACE
    always @(posedge clk) begin
        if (reset) begin
            cycle = 0;
        end else begin
            cycle = cycle + 1;
            $display("TRACE cycle=%0d if_pc=%08h id_pc=%08h ex_pc=%08h stall=%b branch=%b fwd_a=%b fwd_b=%b wb_rd=x%0d wb_data=%08h",
                     cycle, uut.pc_out, uut.if_id_pc, uut.id_ex_pc,
                     uut.control_stall, uut.branch_taken, uut.forward_a,
                     uut.forward_b, uut.mem_wb_rd_out, uut.writeback_data);
        end
    end
`endif

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        failures = 0;
        stall_count = 0;
        taken_branch_count = 0;

`ifdef TRACE
        $dumpfile("build/nova_trace.vcd");
        $dumpvars(0, uut);
`endif

        #1;
        uut.u_imem.memory[0]  = enc_i(5, 0, 3'b000, 1, OP_IMM);
        uut.u_imem.memory[1]  = enc_i(7, 0, 3'b000, 2, OP_IMM);
        uut.u_imem.memory[2]  = enc_r(0, 2, 1, 3'b000, 3);
        uut.u_imem.memory[3]  = enc_s(0, 3, 0, 3'b010);
        uut.u_imem.memory[4]  = enc_i(0, 0, 3'b010, 4, LOAD);
        uut.u_imem.memory[5]  = enc_r(0, 1, 4, 3'b000, 5);
        uut.u_imem.memory[6]  = enc_b(8, 2, 1, 3'b100);
        uut.u_imem.memory[7]  = enc_i(99, 0, 3'b000, 6, OP_IMM);
        uut.u_imem.memory[8]  = enc_r(7'b0100000, 2, 5, 3'b000, 6);
        uut.u_imem.memory[9]  = enc_b(8, 1, 1, 3'b001);
        uut.u_imem.memory[10] = enc_i(42, 0, 3'b000, 7, OP_IMM);
        uut.u_imem.memory[11] = enc_b(8, 1, 1, 3'b000);
        uut.u_imem.memory[12] = enc_i(99, 0, 3'b000, 7, OP_IMM);
        uut.u_imem.memory[13] = enc_i(32'hffffffff, 0, 3'b000, 8, OP_IMM);
        uut.u_imem.memory[14] = enc_b(8, 0, 8, 3'b100);
        uut.u_imem.memory[15] = enc_i(99, 0, 3'b000, 9, OP_IMM);
        uut.u_imem.memory[16] = enc_i(9, 0, 3'b000, 9, OP_IMM);

        #11;
        reset = 1'b0;
        repeat (40) @(posedge clk);
        #1;

        expect_reg(1, 32'd5);
        expect_reg(2, 32'd7);
        expect_reg(3, 32'd12);
        expect_reg(4, 32'd12);
        expect_reg(5, 32'd17);
        expect_reg(6, 32'd10);
        expect_reg(7, 32'd42);
        expect_reg(8, 32'hffffffff);
        expect_reg(9, 32'd9);

        if (uut.u_dmem.dmem[0] !== 32'd12) begin
            $display("FAIL memory[0] expected=0000000c got=%h", uut.u_dmem.dmem[0]);
            failures = failures + 1;
        end
        if (stall_count !== 1) begin
            $display("FAIL expected 1 load-use stall, got %0d", stall_count);
            failures = failures + 1;
        end
        if (taken_branch_count !== 3) begin
            $display("FAIL expected 3 taken branches, got %0d", taken_branch_count);
            failures = failures + 1;
        end

        if (failures == 0)
            $display("PASS tb_top: forwarding, load stall, stores, and branches");
        else
            $fatal(1, "tb_top: %0d failure(s)", failures);
        $finish;
    end
endmodule
