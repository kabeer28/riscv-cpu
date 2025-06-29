# NOVA-1, a RISC-V Pipelined CPU

A 32-bit RISC-V processor written in Verilog, designed to support pipelining, branch prediction, UART output, and full execution of `.hex` binaries generated from RARS.

## 🔧 Features (Planned & In Progress)
- 5-stage pipelined datapath (IF, ID, EX, MEM, WB)
- Hazard handling (forwarding + stalls)
- 2-bit branch predictor
- UART serial output for debugging
- Instruction and data memory

## 🧱 Components
- ALU
- Register File
- Program Counter
- Instruction Memory
- Control Unit (WIP)

## 🧪 Tools
- Verilog (SystemVerilog)
- Verilator / GTKWave
- RARS (for `.asm` to `.hex`)
