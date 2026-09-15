`timescale 1ns/1ps
`default_nettype none
module data_mem (
    input  wire        clk,
    input  wire        memwrite,
    input  wire        memread,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] writedata,
    output reg  [31:0] readdata,
    output reg         misaligned
);
    reg [31:0] dmem [0:255];
    reg [31:0] word_data;
    reg [15:0] half_data;
    reg [7:0] byte_data;
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            dmem[i] = 32'b0;
    end

    always @(*) begin
        word_data = dmem[addr[9:2]];

        case (addr[1:0])
            2'b00: byte_data = word_data[7:0];
            2'b01: byte_data = word_data[15:8];
            2'b10: byte_data = word_data[23:16];
            default: byte_data = word_data[31:24];
        endcase
        half_data = addr[1] ? word_data[31:16] : word_data[15:0];

        misaligned = 1'b0;
        if (memread || memwrite) begin
            case (funct3)
                3'b001, 3'b101: misaligned = addr[0];
                3'b010: misaligned = |addr[1:0];
                default: misaligned = 1'b0;
            endcase
        end

        readdata = 32'b0;
        if (memread && !misaligned) begin
            case (funct3)
                3'b000: readdata = {{24{byte_data[7]}}, byte_data};
                3'b001: readdata = {{16{half_data[15]}}, half_data};
                3'b010: readdata = word_data;
                3'b100: readdata = {24'b0, byte_data};
                3'b101: readdata = {16'b0, half_data};
                default: readdata = 32'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (memwrite && !misaligned) begin
            case (funct3)
                3'b000: begin
                    case (addr[1:0])
                        2'b00: dmem[addr[9:2]][7:0]   <= writedata[7:0];
                        2'b01: dmem[addr[9:2]][15:8]  <= writedata[7:0];
                        2'b10: dmem[addr[9:2]][23:16] <= writedata[7:0];
                        2'b11: dmem[addr[9:2]][31:24] <= writedata[7:0];
                    endcase
                end
                3'b001: begin
                    if (addr[1])
                        dmem[addr[9:2]][31:16] <= writedata[15:0];
                    else
                        dmem[addr[9:2]][15:0] <= writedata[15:0];
                end
                3'b010: dmem[addr[9:2]] <= writedata;
                default: begin end
            endcase
        end
    end
endmodule

`default_nettype wire
