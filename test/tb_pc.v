`timescale 1ns / 1ps

module tb_pc;
    reg clk;
    reg reset;
    reg pc_write;
    reg [31:0] pc_in;
    wire [31:0] pc_out;
    integer failures;

    pc uut (
        .clk(clk), .reset(reset), .pc_write(pc_write),
        .pc_in(pc_in), .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    task expect_pc;
        input [31:0] expected;
        begin
            #1;
            if (pc_out !== expected) begin
                $display("FAIL pc expected=%h got=%h", expected, pc_out);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        pc_write = 1'b1;
        pc_in = 32'd0;
        failures = 0;

        #2;
        expect_pc(32'd0);
        @(negedge clk);
        reset = 1'b0;
        pc_in = 32'd4;
        @(posedge clk);
        expect_pc(32'd4);

        @(negedge clk);
        pc_write = 1'b0;
        pc_in = 32'd8;
        @(posedge clk);
        expect_pc(32'd4);

        @(negedge clk);
        pc_write = 1'b1;
        @(posedge clk);
        expect_pc(32'd8);

        if (failures == 0)
            $display("PASS tb_pc");
        else
            $fatal(1, "tb_pc: %0d failure(s)", failures);
        $finish;
    end
endmodule
