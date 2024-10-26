import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer

async def clock_dut(dut, n=1):
    for i in range(n):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")

async def clock_spi(dut, d=[0], clk_ratio=2):
    for x in d:
        dut.sclk.value = 0
        dut.mosi.value = x
        await clock_dut(dut, clk_ratio)
        dut.sclk.value = 1
        await clock_dut(dut, clk_ratio)

@cocotb.test()
async def test(dut):

    dut.sclk.value = 0
    dut.mosi.value = 0
    dut.cs.value = 0
    dut.data_in.value = 0
    

    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    dut.sclk.value = 0
    dut.mosi.value = 0
    dut.cs.value = 0
    dut.data_in.value = 0xAA
    
    await clock_dut(dut,8)

    dut.cs.value = 1

    await clock_spi(dut,[0]*8)
    await clock_spi(dut,[1]*8)

    await clock_spi(dut,[0,1]*4)
