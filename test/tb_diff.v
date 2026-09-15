`timescale 1ns / 1ps

module tb_diff;
    reg clk;
    reg reset;
    reg [31:0] expected_registers [0:31];
    reg [31:0] expected_memory [0:255];
    integer failures;
    integer index;
    integer seed;

    top #(.IMEM_FILE("build/diff_program.hex")) uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        failures = 0;
        seed = 0;
        if (!$value$plusargs("SEED=%d", seed))
            seed = 0;

        $readmemh("build/diff_registers.hex", expected_registers);
        $readmemh("build/diff_memory.hex", expected_memory);

        #11;
        reset = 1'b0;
        repeat (600) @(posedge clk);
        #1;

        for (index = 0; index < 32; index = index + 1) begin
            if (uut.u_regfile.registers[index] !== expected_registers[index]) begin
                $display("FAIL seed=%0d x%0d expected=%08h got=%08h", seed,
                         index, expected_registers[index],
                         uut.u_regfile.registers[index]);
                failures = failures + 1;
            end
        end

        for (index = 0; index < 256; index = index + 1) begin
            if (uut.u_dmem.dmem[index] !== expected_memory[index]) begin
                $display("FAIL seed=%0d memory[%0d] expected=%08h got=%08h",
                         seed, index, expected_memory[index],
                         uut.u_dmem.dmem[index]);
                failures = failures + 1;
            end
        end

        if (failures == 0)
            $display("PASS tb_diff: seed=%0d architectural state matches", seed);
        else
            $fatal(1, "tb_diff: seed=%0d had %0d mismatch(es)", seed, failures);
        $finish;
    end
endmodule
