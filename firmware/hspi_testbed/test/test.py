import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

async def cycle(dut, n = 1):
    for i in range(n):
        dut.clk.value = 0
        dut.hspi_hrclk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        dut.hspi_hrclk.value = 1
        await Timer(1, units="ns")

async def hspi_send(dut, header, data):
    dut.hspi_hract.value = 1

    while dut.hspi_htack.value != 1:
        await cycle(dut)
    
    dut.hspi_hrvld.value = 1
    dut.hspi_data.value = header >> 16
    await cycle(dut)
    dut.hspi_data.value = header & 0xFFFF
    await cycle(dut)
    for d in data:
        dut.hspi_data.value = d
        await cycle(dut)
    dut.hspi_data.value = 0xAAAA
    await cycle(dut)
    dut.hspi_hrvld.value = 0
    dut.hspi_hract.value = 0
    dut.hspi_data.value = BinaryValue("z"*16)
    await cycle(dut)

@cocotb.test()
async def hspi(dut):
    dut.hspi_htrdy.value = 0
    
    dut.hspi_hrclk.value = 0
    dut.hspi_hract.value = 0
    dut.hspi_hrvld.value = 0

    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    await cycle(dut)

    dut.hspi_hract.value = 1

    await hspi_send(dut, 0x12345678, range(256))

    await cycle(dut, 30)

    dut.hspi_htrdy.value = 1

    await cycle(dut, 256+4)

    dut.hspi_htrdy.value = 0

    await cycle(dut, 30)