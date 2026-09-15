IVERILOG ?= iverilog
VVP ?= vvp
BUILD_DIR := build
SOURCES := $(wildcard src/*.v)

.PHONY: test test-alu test-pc test-core test-upper test-jump trace lint clean

test: test-alu test-pc test-core test-upper test-jump

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

trace: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -DTRACE -s tb_top -o $(BUILD_DIR)/tb_trace $(SOURCES) test/tb_top.v
	$(VVP) $(BUILD_DIR)/tb_trace
	@echo "Trace written to $(BUILD_DIR)/nova_trace.vcd"

lint:
	verilator --lint-only --Wall -Wno-fatal -Wno-PINCONNECTEMPTY \
		-Wno-UNUSEDSIGNAL $(SOURCES)

clean:
	rm -rf $(BUILD_DIR) wave.vcd
