`timescale 1ns / 1ps

module if_id (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] pc_in,
    input  wire [31:0] instruction_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instruction_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out         <= 32'b0;
            instruction_out <= 32'b0;
        end else begin
            pc_out         <= pc_in;
            instruction_out <= instruction_in;
        end
    end
endmodule
