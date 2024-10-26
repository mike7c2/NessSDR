# Makefile

# defaults
SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += ../../cic/cic.vhdl ../../cic/cic_pkg.vhdl ../../cic/differentiator.vhdl ../../cic/integrator.vhdl 
#
## TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = cic
#
## MODULE is the basename of the Python test file
MODULE = test
#

## include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
