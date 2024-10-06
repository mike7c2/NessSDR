# Makefile

# defaults
SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += ../../deser/deser.vhdl
VHDL_SOURCES += ../../deser/deser_pkg.vhdl
VHDL_SOURCES += ../../adc/adc.vhdl
VHDL_SOURCES += ../../adder/adder_pkg.vhdl
VHDL_SOURCES += ../../adder/pipelined_adder.vhdl
VHDL_SOURCES += ../../adc/adc_pkg.vhdl test_harness.vhdl
VHDL_SOURCES += ../../lutfir/lutfir.vhdl
VHDL_SOURCES += ../../lutfir/lutfir_pkg.vhdl
VHDL_SOURCES += ../../utilities/utilities.vhdl
VHDL_SOURCES += ../../bram/bram_pkg.vhdl
VHDL_SOURCES += ../../bram/bram.vhdl
VHDL_SOURCES += ../../nco/nco_pkg.vhdl
VHDL_SOURCES += ../../nco/nco.vhdl
VHDL_SOURCES += ../../multiplier/multiplier_pkg.vhdl
VHDL_SOURCES += ../../multiplier/pipelined_multiplier.vhdl











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