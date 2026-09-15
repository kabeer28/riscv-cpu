IVERILOG ?= iverilog
VVP ?= vvp
YOSYS ?= yosys
GTKWAVE ?= gtkwave
BUILD_DIR := build
SOURCES := $(wildcard src/*.v)

.PHONY: test test-alu test-pc test-core test-upper test-jump test-memory test-diff trace wave lint synth clean

test: test-alu test-pc test-core test-upper test-jump test-memory test-diff

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test-alu: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_alu -o $(BUILD_DIR)/tb_alu $(SOURCES) test/tb_alu.v
	$(VVP) $(BUILD_DIR)/tb_alu

test-pc: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_pc -o $(BUILD_DIR)/tb_pc $(SOURCES) test/tb_pc.v
	$(VVP) $(BUILD_DIR)/tb_pc

test-core: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_top -o $(BUILD_DIR)/tb_top $(SOURCES) test/tb_top.v
	$(VVP) $(BUILD_DIR)/tb_top

test-upper: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_upper -o $(BUILD_DIR)/tb_upper $(SOURCES) test/tb_upper.v
	$(VVP) $(BUILD_DIR)/tb_upper

test-jump: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_jump -o $(BUILD_DIR)/tb_jump $(SOURCES) test/tb_jump.v
	$(VVP) $(BUILD_DIR)/tb_jump

test-memory: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_memory -o $(BUILD_DIR)/tb_memory $(SOURCES) test/tb_memory.v
	$(VVP) $(BUILD_DIR)/tb_memory

test-diff: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -s tb_diff -o $(BUILD_DIR)/tb_diff $(SOURCES) test/tb_diff.v
	@for seed in 1 7 19; do \
		python3 test/gen_diff.py --seed $$seed \
			--program $(BUILD_DIR)/diff_program.hex \
			--registers $(BUILD_DIR)/diff_registers.hex \
			--memory $(BUILD_DIR)/diff_memory.hex; \
		$(VVP) $(BUILD_DIR)/tb_diff +SEED=$$seed || exit 1; \
	done

trace: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -DTRACE -s tb_top -o $(BUILD_DIR)/tb_trace $(SOURCES) test/tb_top.v
	$(VVP) $(BUILD_DIR)/tb_trace
	@echo "Trace written to $(BUILD_DIR)/nova_trace.vcd"

wave: trace
	$(GTKWAVE) --dark $(BUILD_DIR)/nova_trace.vcd waves/nova.gtkw

lint:
	verilator --lint-only --Wall -Wno-fatal -Wno-PINCONNECTEMPTY \
		-Wno-UNUSEDSIGNAL $(SOURCES)

synth: | $(BUILD_DIR)
	$(YOSYS) -q -l $(BUILD_DIR)/synth.log -s scripts/synth.ys
	@tail -45 $(BUILD_DIR)/synth.stat

clean:
	rm -rf $(BUILD_DIR) wave.vcd
