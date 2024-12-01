# Makefile
ITSY_LIB_DIR = ../../itsy_lib/src/
# defaults
SIM ?= ghdl
SIM_ARGS ?= --wave=waveform.ghw
TOPLEVEL_LANG ?= vhdl
#
VHDL_SOURCES += ../src/hspi_testbed.vhdl $(ITSY_LIB_DIR)/hspi/hspi_pkg.vhdl $(ITSY_LIB_DIR)/hspi/hspi_rx.vhdl $(ITSY_LIB_DIR)/hspi/hspi_tx.vhdl $(ITSY_LIB_DIR)/crc16/crc16_pkg.vhdl $(ITSY_LIB_DIR)/crc16/crc16.vhdl $(ITSY_LIB_DIR)/fifo/rw_clk_fifo.vhdl $(ITSY_LIB_DIR)/fifo/fifo_pkg.vhdl $(ITSY_LIB_DIR)/fifo/rw_clk_fifo_lfsr.vhdl $(ITSY_LIB_DIR)/ice40hx/ice40hx.vhdl $(ITSY_LIB_DIR)/utilities/utilities.vhdl $(ITSY_LIB_DIR)/hspi/hspi_buffered_txrx.vhdl
#
## TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = hspi_testbed
#
## MODULE is the basename of the Python test file
MODULE = test
#

export PYTHONPATH := $(PWD)/../../../software:$(PYTHONPATH)

## include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
