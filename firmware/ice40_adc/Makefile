# Define variables
GHDL = ghdl
YOSYS = yosys
NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICEPROG = iceprog

SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl

TOP_LEVEL ?= top_level
VHDL_SOURCES = \
	$(wildcard utilities/*.vhdl) \
	$(wildcard ice40hx/*.vhdl) \
	$(wildcard bram/*.vhdl) \
	$(wildcard deser/*.vhdl) \
	$(wildcard adder/*.vhdl) \
	$(wildcard adc/*.vhdl) \
	$(wildcard lutfir/*.vhdl) \
	$(TOP_LEVEL).vhdl
PCF_FILE ?= $(TOP_LEVEL).pcf

JSON_FILE = build/top_level.json
ASC_FILE = build/top_level.asc
BIN_FILE = build/top_level.bin

# Default target
all: $(BIN_FILE)

# Synthesize the design
$(JSON_FILE): $(VHDL_SOURCES)
	@mkdir -p build
	$(GHDL) -a --workdir=build $(VHDL_SOURCES) 
	cd build && $(YOSYS) -m /usr/lib/ghdl_yosys.so -p 'ghdl $(TOP_LEVEL); $(if $(VERILOG_SOURCES),read_verilog $(VERILOG_SOURCES);) synth_ice40 -json ../$(JSON_FILE)'

# Place and route
$(ASC_FILE): $(JSON_FILE) $(PCF_FILE)
	$(NEXTPNR) --hx8k --package ct256 --pcf $(PCF_FILE) --asc $(ASC_FILE) --json $(JSON_FILE) --pcf-allow-unconstrained --freq 150

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




