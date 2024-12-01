import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

async def cycle(dut, n = 1):
    for i in range(n):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")

@cocotb.test()
async def hspi(dut):
    dut.htrdy.value = 0
    dut.user_field.value = 0xAAAAA
    dut.tx_data.value = 0
    dut.tx_data_valid.value = 0

    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    await cycle(dut)

    dut.tx_data_valid.value = 1

    await cycle(dut, 10)

    dut.htrdy.value = 1

    await cycle(dut, 512)








