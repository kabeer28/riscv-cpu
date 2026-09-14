`timescale 1ns / 1ps
`default_nettype none

module hazard_unit (
    input wire        id_ex_memread,
    input wire [4:0]  id_ex_rd,
    input wire [4:0]  if_id_rs1,
    input wire [4:0]  if_id_rs2,
    input wire        if_id_uses_rs1,
    input wire        if_id_uses_rs2,
    output reg        pc_write,
    output reg        if_id_write,
    output reg        control_stall
);
    always @(*) begin
        // Default: no stall
        pc_write = 1'b1;
        if_id_write = 1'b1;
        control_stall = 1'b0;

        //detect load-use hazard
        if (id_ex_memread && (id_ex_rd != 5'd0) &&
           ((if_id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
            (if_id_uses_rs2 && (id_ex_rd == if_id_rs2)))) begin
            pc_write = 1'b0;          //freeze PC
            if_id_write = 1'b0;       //freeze IF/ID
            control_stall = 1'b1;     //insert NOP into the ID/EX
        end
    end
endmodule

`default_nettype wire
