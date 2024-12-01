# Makefile

# defaults
SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd --ieee-asserts=disable
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += $(SRC_DIR)/rebuffer/rebuffer_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/rebuffer/rebuffer.vhdl
VHDL_SOURCES += $(SRC_DIR)/delay/delay_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/delay/delay.vhdl
VHDL_SOURCES += $(SRC_DIR)/adc/adc.vhdl
VHDL_SOURCES += $(SRC_DIR)/adder/adder_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/adder/pipelined_adder.vhdl
VHDL_SOURCES += $(SRC_DIR)/adc/adc_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/lutfir/lutfir.vhdl
VHDL_SOURCES += $(SRC_DIR)/lutfir/lutfir_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/utilities/utilities.vhdl
VHDL_SOURCES += $(SRC_DIR)/bram/bram_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/bram/bram.vhdl
VHDL_SOURCES += $(SRC_DIR)/nco/nco_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/nco/nco.vhdl
VHDL_SOURCES += $(SRC_DIR)/multiplier/multiplier_pkg.vhdl
VHDL_SOURCES += $(SRC_DIR)/multiplier/pipelined_multiplier.vhdl
VHDL_SOURCES += $(SRC_DIR)/cic/cic_pkg.vhdl $(SRC_DIR)/cic/cic.vhdl $(SRC_DIR)/cic/integrator.vhdl $(SRC_DIR)/cic/differentiator.vhdl
VHDL_SOURCES += $(SRC_DIR)/pipeline.vhdl

#
## TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = pipeline
#
## MODULE is the basename of the Python test file
MODULE = test
#

export PYTHONPATH := $(PWD)/../../../software:$(PYTHONPATH)

## include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

full:
	$(MAKE) sim SIM_ARGS='-gARG=1' MODULE=test TESTCASE=test1 