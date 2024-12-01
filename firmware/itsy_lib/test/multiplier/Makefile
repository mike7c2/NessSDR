# Makefile

# defaults
SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += $(SRC_DIR)/multiplier/multiplier_pkg.vhdl $(SRC_DIR)/multiplier/pipelined_multiplier.vhdl $(SRC_DIR)/utilities/utilities.vhdl
#
## TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = pipelined_multiplier
#
## MODULE is the basename of the Python test file
MODULE = test
#

export PYTHONPATH := $(PWD)/../../../software:$(PYTHONPATH)

## include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
