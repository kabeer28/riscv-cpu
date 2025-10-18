module ex_mem (
    input clk,
    input reset,

    //control signals
    input regwrite_in,
    input memread_in,
    input memwrite_in,
    input memtoreg_in,
    input branch_in,

    //data signals
    input [31:0] branch_target_in,
    input branch_taken_in,
    input [31:0] alu_result_in,
    input [31:0] rs2_data_in,
    input [4:0] rd_in,

    //outputs
    output reg regwrite_out,
    output reg memread_out,
    output reg memwrite_out,
    output reg memtoreg_out,
    output reg branch_out,

    output reg [31:0] branch_target_out,
    output reg branch_taken_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0] rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regwrite_out     <= 0;
            memread_out      <= 0;
            memwrite_out     <= 0;
            memtoreg_out     <= 0;
            branch_out       <= 0;

            branch_target_out<= 0;
            branch_taken_out <= 0;
            alu_result_out   <= 0;
            rs2_data_out     <= 0;
            rd_out           <= 0;
        end else begin
            regwrite_out     <= regwrite_in;
            memread_out      <= memread_in;
            memwrite_out     <= memwrite_in;
            memtoreg_out     <= memtoreg_in;
            branch_out       <= branch_in;

            branch_target_out<= branch_target_in;
            branch_taken_out <= branch_taken_in;
            alu_result_out   <= alu_result_in;
            rs2_data_out     <= rs2_data_in;
            rd_out           <= rd_in;
        end
    end
endmodule
