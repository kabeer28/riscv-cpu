module pc (
    input clk,
    input reset,
    input pc_write,               // used to stall PC if needed later
    input [31:0] pc_in,           // next PC value (usually PC + 4 or a branch target)
    output reg [31:0] pc_out      // current PC
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 32'd0;        // start at 0 on reset
        else if (pc_write)
            pc_out <= pc_in;        // update PC when allowed
    end
endmodule
