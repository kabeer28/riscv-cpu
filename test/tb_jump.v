`timescale 1ns / 1ps

module tb_jump;
    reg clk;
    reg reset;
    integer failures;
    integer jump_count;

    localparam [6:0] OP_IMM = 7'b0010011;
    localparam [6:0] OP     = 7'b0110011;
    localparam [6:0] STORE  = 7'b0100011;
    localparam [6:0] JAL    = 7'b1101111;
    localparam [6:0] JALR   = 7'b1100111;

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
        input [4:0] rs2;
        input [4:0] rs1;
        input [4:0] rd;
        enc_r = {7'b0000000, rs2, rs1, 3'b000, rd, OP};
    endfunction

    function [31:0] enc_s;
        input [31:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], STORE};
    endfunction

    function [31:0] enc_j;
        input [31:0] imm;
        input [4:0] rd;
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, JAL};
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
        if (!reset && uut.id_ex_jump)
            jump_count = jump_count + 1;
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        failures = 0;
        jump_count = 0;

        #1;
        uut.u_imem.memory[0] = enc_j(8, 5);                       // jal x5, +8
        uut.u_imem.memory[1] = enc_i(99, 0, 3'b000, 1, OP_IMM); // flushed
        uut.u_imem.memory[2] = enc_i(1, 5, 3'b000, 2, OP_IMM);  // x2 = link + 1
        uut.u_imem.memory[3] = enc_i(25, 0, 3'b000, 3, OP_IMM); // bit 0 is cleared
        uut.u_imem.memory[4] = enc_i(0, 3, 3'b000, 6, JALR);    // jalr x6, 0(x3)
        uut.u_imem.memory[5] = enc_i(99, 0, 3'b000, 4, OP_IMM); // flushed
        uut.u_imem.memory[6] = enc_r(6, 5, 7);                   // x7 = x5 + x6
        uut.u_imem.memory[7] = enc_j(8, 0);                      // jal x0, +8
        uut.u_imem.memory[8] = enc_s(0, 2, 0, 3'b010);          // flushed store
        uut.u_imem.memory[9] = enc_s(0, 7, 0, 3'b010);          // committed store

        #11;
        reset = 1'b0;
        repeat (30) @(posedge clk);
        #1;

        expect_reg(1, 32'd0);
        expect_reg(2, 32'd5);
        expect_reg(3, 32'd25);
        expect_reg(4, 32'd0);
        expect_reg(5, 32'd4);
        expect_reg(6, 32'd20);
        expect_reg(7, 32'd24);
        if (uut.u_dmem.dmem[0] !== 32'd24) begin
            $display("FAIL memory[0] expected=00000018 got=%h", uut.u_dmem.dmem[0]);
            failures = failures + 1;
        end
        if (jump_count !== 3) begin
            $display("FAIL expected 3 jumps, got %0d", jump_count);
            failures = failures + 1;
        end

        if (failures == 0)
            $display("PASS tb_jump: JAL, JALR, link forwarding, and flushing");
        else
            $fatal(1, "tb_jump: %0d failure(s)", failures);
        $finish;
    end
endmodule
