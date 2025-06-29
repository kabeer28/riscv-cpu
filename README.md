# NOVA-1: RISC-V CPU (in Verilog)

NOVA-1 is a 32-bit RISC-V CPU built from scratch in Verilog. It's designed to support the RV32I instruction set and is being built step-by-step, starting with a single-cycle CPU, and progressing toward a fully pipelined processor.

NOVA-1 represents the first step in building a custom, next-generation RISC-V CPU from the ground up.

---

## ✅ Features (Completed)

- ALU with arithmetic, logic, shift, and compare support
- Register file with two read ports and one write port
- Program Counter module with reset and stall control
- Instruction memory module that loads `.hex` files generated from RARS
- Modular codebase for reusability and scalability

---

## 🛠️ In Progress

- 5-stage pipelined datapath (IF, ID, EX, MEM, WB)
- Branch prediction (2-bit saturating counter)
- Hazard detection and data forwarding
- UART output to send results from CPU to PC

---

## 🧪 Test Programs

Assembly programs are written in [RARS](https://github.com/TheThirdOne/rars) and exported as `.hex` machine code. These are loaded into the CPU’s instruction memory for simulation.

---

<pre><code>## 🗂️ Project Structure ``` riscv_cpu/ ├── src/ # Verilog source files (alu.v, regfile.v, pc.v, instr_mem.v, top.v) ├── test/ # Testbenches │ ├── tb_alu.v │ ├── tb_pc.v ├── hex/ # Exported machine code from RARS │ └── program.hex ├── README.md └── .gitignore ``` </code></pre>

---

## 🚀 Goals

- ✅ Simulate instruction fetching using PC + instruction memory
- 🔄 Implement full pipelined execution
- 🔄 Support control flow instructions (jumps, branches)
- 🔄 Add waveform output using GTKWave
- 🔄 Synthesize on an FPGA (Nexys A7 or similar, maybe!)

---

## 💻 Contact

Kabeer Makkar – [@kabeermakkar](https://github.com/kabeermakkar)
