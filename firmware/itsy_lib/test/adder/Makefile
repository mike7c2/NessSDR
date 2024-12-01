SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd
TOPLEVEL_LANG ?= vhdl

VHDL_SOURCES += $(SRC_DIR)/adder/pipelined_adder.vhdl $(SRC_DIR)/utilities/utilities.vhdl 

TOPLEVEL = pipelined_adder
MODULE = test

include $(shell cocotb-config --makefiles)/Makefile.sim
