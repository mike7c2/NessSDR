# Makefile

# defaults
SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += $(SRC_DIR)/cic/cic.vhdl $(SRC_DIR)/cic/cic_pkg.vhdl $(SRC_DIR)/cic/differentiator.vhdl $(SRC_DIR)/cic/integrator.vhdl 
#
## TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = cic
#
## MODULE is the basename of the Python test file
MODULE = test
#

## include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
