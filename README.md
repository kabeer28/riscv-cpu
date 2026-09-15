# NOVA-1

NOVA-1 is a five-stage, 32-bit RISC-V processor written in Verilog. The current
core implements a verified RV32I subset and focuses on the pipeline mechanics:
forwarding, load-use stalls, control-hazard recovery, memory access, and
writeback.

## Pipeline

```text
IF -> ID -> EX -> MEM -> WB
```

- EX/MEM and MEM/WB operand forwarding
- One-cycle load-use interlock
- Branch resolution in EX with IF/ID and ID/EX flushing
- Separate 1 KiB instruction and data memories
- Register `x0` hardwired to zero

## Verified instructions

| Group | Instructions |
| --- | --- |
| Register ALU | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| Immediate ALU | `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`, `ANDI` |
| Upper immediate | `LUI`, `AUIPC` |
| Jump | `JAL`, `JALR` |
| Memory | `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW` |
| Branch | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |

Unsupported encodings have no architectural side effects. The core does not yet
claim full RV32I compatibility.

## Test

Install Icarus Verilog, then run:

```bash
make test
```

The tests are self-checking. Directed processor tests cover pipeline hazards,
control flow, and memory access. A deterministic differential test generates
programs from several seeds, executes them with an independent architectural
reference model, and compares every register and data-memory word against the
pipelined core. GitHub Actions runs the same suite on every push and pull
request.

Generate a waveform for GTKWave with:

```bash
make trace
gtkwave build/nova_trace.vcd
```

## Synthesis

Run a generic Yosys synthesis check with:

```bash
make synth
```

This elaborates the complete hierarchy, rejects inferred latches and structural
connectivity errors, and writes the generic netlist and resource report under
`build/`. Board-specific timing analysis still requires a selected FPGA,
pinout, clock constraint, and vendor flow.

## Loading a program

`top` and `instr_mem` accept a memory-file parameter. Pass a RARS-generated
hex file when instantiating the processor:

```verilog
top #(.IMEM_FILE("program.hex")) cpu (
    .clk(clk),
    .reset(reset)
);
```

When no file is supplied, instruction memory is initialized with RISC-V NOPs.

## Memory behavior

Halfword accesses must be two-byte aligned and word accesses must be four-byte
aligned. Until architectural traps are implemented, misaligned loads return zero
and misaligned stores are suppressed.

## Remaining work

- Select an FPGA target and add board-specific timing constraints
- Add memory-mapped UART output
- Evaluate a branch predictor only after collecting baseline branch metrics

## Structure

```text
src/                  Processor RTL
test/                 Self-checking testbenches
.github/workflows/    Continuous integration
Makefile              Simulation, lint, and trace commands
```
