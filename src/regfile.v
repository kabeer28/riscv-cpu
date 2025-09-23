module regfile (
    input clk,
    input regwrite,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] writedata,
    output [31:0] readdata1,
    output [31:0] readdata2,
    output [31:0] debug_x5,
    output [31:0] debug_x6,
    output [31:0] debug_x7
);
    reg [31:0] registers[0:31];
    integer i;

    // initialize registers to 0 at simulation start
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    // Read (combinational)
    assign readdata1 = (rs1 == 0) ? 32'd0 : registers[rs1];
    assign readdata2 = (rs2 == 0) ? 32'd0 : registers[rs2];
    assign debug_x5 = registers[5];
    assign debug_x6 = registers[6];
    assign debug_x7 = registers[7];

    // Write (synchronous)
    always @(posedge clk) begin
        if (regwrite && rd != 0)
            registers[rd] <= writedata;
    end
endmodule
