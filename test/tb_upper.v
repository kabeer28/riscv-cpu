`timescale 1ns / 1ps

module tb_upper;
    reg clk;
    reg reset;
    integer failures;

    localparam [6:0] OP_IMM = 7'b0010011;
    localparam [6:0] OP     = 7'b0110011;
    localparam [6:0] LUI    = 7'b0110111;
    localparam [6:0] AUIPC  = 7'b0010111;

    top uut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    function [31:0] enc_i;
        input [31:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        enc_i = {imm[11:0], rs1, funct3, rd, OP_IMM};
    endfunction

    function [31:0] enc_r;
        input [4:0] rs2;
        input [4:0] rs1;
        input [4:0] rd;
        enc_r = {7'b0000000, rs2, rs1, 3'b000, rd, OP};
    endfunction

    function [31:0] enc_u;
        input [19:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        enc_u = {imm, rd, opcode};
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

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        failures = 0;

        #1;
        uut.u_imem.memory[0] = enc_u(20'h12345, 10, LUI);
        uut.u_imem.memory[1] = enc_i(1, 10, 3'b000, 11);
        uut.u_imem.memory[2] = enc_u(20'h00001, 12, AUIPC);
        uut.u_imem.memory[3] = enc_r(11, 12, 13);

        #11;
        reset = 1'b0;
        repeat (12) @(posedge clk);
        #1;

        expect_reg(10, 32'h12345000);
        expect_reg(11, 32'h12345001);
        expect_reg(12, 32'h00001008);
        expect_reg(13, 32'h12346009);

        if (failures == 0)
            $display("PASS tb_upper: LUI, AUIPC, and dependent forwarding");
        else
            $fatal(1, "tb_upper: %0d failure(s)", failures);
        $finish;
    end
endmodule
