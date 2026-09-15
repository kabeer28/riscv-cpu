`timescale 1ns / 1ps

module tb_memory;
    reg clk;
    reg reset;
    integer failures;
    integer stall_count;
    integer misaligned_count;

    localparam [6:0] OP_IMM = 7'b0010011;
    localparam [6:0] LUI    = 7'b0110111;
    localparam [6:0] LOAD   = 7'b0000011;
    localparam [6:0] STORE  = 7'b0100011;

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

    function [31:0] enc_s;
        input [31:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], STORE};
    endfunction

    function [31:0] enc_u;
        input [19:0] imm;
        input [4:0] rd;
        enc_u = {imm, rd, LUI};
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
            if (uut.mem_misaligned)
                misaligned_count = misaligned_count + 1;
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        failures = 0;
        stall_count = 0;
        misaligned_count = 0;

        #1;
        uut.u_dmem.dmem[0] = 32'h80ff7f01;
        uut.u_imem.memory[0]  = enc_i(0, 0, 3'b000, 1, LOAD);
        uut.u_imem.memory[1]  = enc_i(2, 0, 3'b000, 2, LOAD);
        uut.u_imem.memory[2]  = enc_i(3, 0, 3'b100, 3, LOAD);
        uut.u_imem.memory[3]  = enc_i(0, 0, 3'b001, 4, LOAD);
        uut.u_imem.memory[4]  = enc_i(2, 0, 3'b001, 5, LOAD);
        uut.u_imem.memory[5]  = enc_i(2, 0, 3'b101, 6, LOAD);
        uut.u_imem.memory[6]  = enc_i(8'hAA, 0, 3'b000, 10, OP_IMM);
        uut.u_imem.memory[7]  = enc_s(1, 10, 0, 3'b000);
        uut.u_imem.memory[8]  = enc_u(20'h00001, 11);
        uut.u_imem.memory[9]  = enc_i(12'h234, 11, 3'b000, 11, OP_IMM);
        uut.u_imem.memory[10] = enc_s(2, 11, 0, 3'b001);
        uut.u_imem.memory[11] = enc_i(0, 0, 3'b010, 7, LOAD);
        uut.u_imem.memory[12] = enc_i(1, 7, 3'b000, 12, OP_IMM);
        uut.u_imem.memory[13] = enc_i(32'hffffffff, 0, 3'b000, 13, OP_IMM);
        uut.u_imem.memory[14] = enc_s(0, 13, 0, 3'b000);
        uut.u_imem.memory[15] = enc_i(0, 0, 3'b100, 14, LOAD);
        uut.u_imem.memory[16] = enc_i(85, 0, 3'b000, 15, OP_IMM);
        uut.u_imem.memory[17] = enc_s(4, 15, 0, 3'b010);
        uut.u_imem.memory[18] = enc_i(4, 0, 3'b010, 16, LOAD);
        uut.u_imem.memory[19] = enc_s(1, 11, 0, 3'b001);
        uut.u_imem.memory[20] = enc_i(2, 0, 3'b010, 17, LOAD);

        #11;
        reset = 1'b0;
        repeat (45) @(posedge clk);
        #1;

        expect_reg(1, 32'h00000001);
        expect_reg(2, 32'hffffffff);
        expect_reg(3, 32'h00000080);
        expect_reg(4, 32'h00007f01);
        expect_reg(5, 32'hffff80ff);
        expect_reg(6, 32'h000080ff);
        expect_reg(7, 32'h1234aa01);
        expect_reg(12, 32'h1234aa02);
        expect_reg(14, 32'h000000ff);
        expect_reg(16, 32'h00000055);
        expect_reg(17, 32'h00000000);

        if (uut.u_dmem.dmem[0] !== 32'h1234aaff) begin
            $display("FAIL memory[0] expected=1234aaff got=%h", uut.u_dmem.dmem[0]);
            failures = failures + 1;
        end
        if (uut.u_dmem.dmem[1] !== 32'h00000055) begin
            $display("FAIL memory[1] expected=00000055 got=%h", uut.u_dmem.dmem[1]);
            failures = failures + 1;
        end
        if (stall_count !== 1) begin
            $display("FAIL expected 1 load-use stall, got %0d", stall_count);
            failures = failures + 1;
        end
        if (misaligned_count !== 2) begin
            $display("FAIL expected 2 misaligned accesses, got %0d", misaligned_count);
            failures = failures + 1;
        end

        if (failures == 0)
            $display("PASS tb_memory: subword loads, masked stores, and alignment");
        else
            $fatal(1, "tb_memory: %0d failure(s)", failures);
        $finish;
    end
endmodule
