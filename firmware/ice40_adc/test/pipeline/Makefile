# Makefile

# defaults
SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += ../../deser/deser.vhdl ../../deser/deser_pkg.vhdl ../../adc/adc.vhdl ../../adder/adder_pkg.vhdl ../../adder/pipelined_adder.vhdl ../../adc/adc_pkg.vhdl test_harness.vhdl ../../lutfir/lutfir.vhdl ../../lutfir/lutfir_pkg.vhdl ../../utilities/utilities.vhdl ../../bram/bram_pkg.vhdl ../../bram/bram.vhdl
#
## TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = test_harness
#
## MODULE is the basename of the Python test file
MODULE = test
#

export PYTHONPATH := $(PWD)/../../../software:$(PYTHONPATH)

## include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

full:
	$(MAKE) sim SIM_ARGS='-gARG=1' MODULE=test TESTCASE=test1