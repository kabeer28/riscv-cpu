module mem_wb (
    input clk,
    input reset,

    //control signals
    input regwrite_in,
    input memtoreg_in,

    //data signals
    input [31:0] read_data_in,    // from data memory
    input [31:0] alu_result_in,   // from the ALU
    input [4:0]  rd_in,           // this is the destination register

    //outputs
    output reg regwrite_out,
    output reg memtoreg_out,
    output reg [31:0] read_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0]  rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regwrite_out   <= 0;
            memtoreg_out   <= 0;
            read_data_out  <= 0;
            alu_result_out <= 0;
            rd_out         <= 0;
        end else begin
            regwrite_out   <= regwrite_in;
            memtoreg_out   <= memtoreg_in;
            read_data_out  <= read_data_in;
            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;
        end
    end
endmodule
