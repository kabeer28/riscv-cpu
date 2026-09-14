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
| Memory | `LW`, `SW` |
| Branch | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |

Unsupported encodings have no architectural side effects. The core does not yet
claim full RV32I compatibility.

## Test

Install Icarus Verilog, then run:

```bash
make test
```

The tests are self-checking. The processor-level test runs one program that
covers back-to-back ALU dependencies, forwarded store data, a load-use stall,
taken and untaken branches, and signed branch comparison. GitHub Actions runs
the same suite on every push and pull request.

Generate a waveform for GTKWave with:

```bash
make trace
gtkwave build/nova_trace.vcd
```

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

## Remaining work

- Complete RV32I with `LUI`, `AUIPC`, `JAL`, `JALR`, and byte/halfword memory operations
- Add instruction-level differential tests against a reference model
- Synthesize and close timing on an FPGA target
- Add memory-mapped UART output
- Evaluate a branch predictor only after collecting baseline branch metrics

## Structure

```text
src/                  Processor RTL
test/                 Self-checking testbenches
.github/workflows/    Continuous integration
Makefile              Simulation, lint, and trace commands
```
