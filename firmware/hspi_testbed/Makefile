# Define variables
GHDL = ghdl
YOSYS = yosys
NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICEPROG = iceprog

SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

ITSY_LIB_DIR = ../itsy_lib/

TOP_LEVEL ?= hspi_testbed
VHDL_SOURCES = \
	$(wildcard $(ITSY_LIB_DIR)src/utilities/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/ice40hx/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/bram/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/adder/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/lfsr/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/fifo/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/rebuffer/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/multiplier/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/nco/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/spi/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/adc/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/lutfir/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/cic/cic_pkg.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/cic/integrator.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/cic/differentiator.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/cic/cic.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/delay/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/nco/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/crc16/*.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/hspi/hspi_pkg.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/hspi/hspi_rx.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/hspi/hspi_tx.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/hspi/hspi_buffered_txrx.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/controller/controller_pkg.vhdl) \
	$(wildcard $(ITSY_LIB_DIR)src/controller/controller_hspi.vhdl) \
	$(ITSY_LIB_DIR)src/pipeline/pipeline_pkg.vhdl \
	$(ITSY_LIB_DIR)src/pipeline/pipeline.vhdl \
	src/$(TOP_LEVEL).vhdl
PCF_FILE ?= $(TOP_LEVEL).pcf

JSON_FILE = build/top_level.json
ASC_FILE = build/top_level.asc
BIN_FILE = build/top_level.bin
CLOCK_CONSTRAINTS = clock_constraints.py

# Default target
all: $(BIN_FILE)

# Synthesize the design
$(JSON_FILE): $(VHDL_SOURCES) $(PCF_FILE) $(CLOCK_CONSTRAINTS)
	@mkdir -p build
	$(GHDL) -a --workdir=build $(VHDL_SOURCES) 
	cd build && $(YOSYS) -m /usr/lib/ghdl_yosys.so -p 'ghdl $(TOP_LEVEL); $(if $(VERILOG_SOURCES),read_verilog $(VERILOG_SOURCES);) synth_ice40 -json ../$(JSON_FILE)'

# Place and route
$(ASC_FILE): $(JSON_FILE) $(PCF_FILE)
	$(NEXTPNR) --hx8k --package ct256 --pcf $(PCF_FILE) --asc $(ASC_FILE) --json $(JSON_FILE) --pre-pack $(CLOCK_CONSTRAINTS)

# Generate bitstream
$(BIN_FILE): $(ASC_FILE)
	$(ICEPACK) $(ASC_FILE) $(BIN_FILE)

# Program FPGA
program_fpga: $(BIN_FILE)
	$(ICEPROG) $(BIN_FILE)

# Clean up
clean:
	rm -rf *.o *.acf *.json *.bin *.cf $(ASC_FILE) build

.PHONY: all clean program_fpga





