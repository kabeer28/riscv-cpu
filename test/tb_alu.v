`timescale 1ns / 1ps

module tb_alu;
    reg [31:0] a, b;
    reg [3:0] control;
    wire [31:0] result;
    wire zero;
    integer failures;

    alu uut (.A(a), .B(b), .ALUControl(control), .Result(result), .Zero(zero));

    task check;
        input [3:0] op;
        input [31:0] lhs;
        input [31:0] rhs;
        input [31:0] expected;
        begin
            control = op;
            a = lhs;
            b = rhs;
            #1;
            if (result !== expected) begin
                $display("FAIL alu op=%b a=%h b=%h expected=%h got=%h",
                         op, lhs, rhs, expected, result);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        failures = 0;
        check(4'b0010, 32'd5, 32'd3, 32'd8);
        check(4'b0110, 32'd5, 32'd3, 32'd2);
        check(4'b0000, 32'hf0f0, 32'h0ff0, 32'h00f0);
        check(4'b0001, 32'hf000, 32'h0ff0, 32'hfff0);
        check(4'b1000, 32'hffaa, 32'h0ff0, 32'hf05a);
        check(4'b1001, 32'd1, 32'd5, 32'd32);
        check(4'b1010, 32'h80000000, 32'd4, 32'h08000000);
        check(4'b1011, 32'h80000000, 32'd4, 32'hf8000000);
        check(4'b0111, 32'hffffffff, 32'd1, 32'd1);
        check(4'b1100, 32'hffffffff, 32'd1, 32'd0);

        if (failures == 0)
            $display("PASS tb_alu");
        else
            $fatal(1, "tb_alu: %0d failure(s)", failures);
        $finish;
    end
endmodule
