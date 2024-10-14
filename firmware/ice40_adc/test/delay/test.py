import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer

async def clock(dut):
    dut.clk = 0
    await Timer(1, units="ns")
    dut.clk = 1
    await Timer(1, units="ns")

@cocotb.test()
async def test(dut):

    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    dut.data_in.value = 0
    await clock(dut)
    dut.data_in.value = 1
    await clock(dut)
    dut.data_in.value = 2
    await clock(dut)
    dut.data_in.value = 3
    await clock(dut)
    dut.data_in.value = 3
    await clock(dut)
    dut.data_in.value = 2
    await clock(dut)
    dut.data_in.value = 1
    await clock(dut)
    dut.data_in.value = 0
    await clock(dut)

    await clock(dut)
    await clock(dut)
    await clock(dut)
    await clock(dut)
    await clock(dut)
    await clock(dut)
    await clock(dut)