# RISC-V Pipelined CPU (in Verilog)

This project is a 32-bit RISC-V CPU built from scratch in Verilog. It's designed to support the RV32I instruction set and is being built step-by-step, starting with a single-cycle CPU, and progressing toward a fully pipelined processor.

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

## 📁 Project Structure

riscv_cpu/
├── src/ # Verilog modules (ALU, regfile, pc, etc.)
├── test/ # Testbenches
├── test/hex/ # Assembled .hex files from RARS
├── README.md
└── .gitignore


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
