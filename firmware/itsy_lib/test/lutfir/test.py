import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

from itsy.lut_fir import LutFIR

test_input_data = [
    "01101000101100110010110101011101010000101111001110011101011101110000000000101000111111100001111010001100110110000001001101000010",
    "11010001011001100101101010111010100001011110011100111010111011100000000001010001111111000011110100011001101100000010011010000100",
    "10111010100000010001100011110101000110100001001111110001101100100111100100000111000110101000010111001110100110000010101001100110",
    "01110101000000100011000111101010001101000010011111100011011001001111001000001110001101010000101110011101001100000101010011001101",
    "11101010000001000110001111010100011010000100111111000110110010011110010000011100011010100001011100111010011000001010100110011010",
    "11010100000010001100011110101000110100001001111110001101100100111100100000111000110101000010111001110100110000010101001100110101"
]
expected_outputs = [
    49864,
    49204,
    48491,
    47738,
    46957,
    46167
]

async def cycle(dut, n = 1):
    for i in range(n):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")

async def cycle_wr(dut, n = 1):
    for i in range(n):
        dut.lut_wr_clk.value = 0
        await Timer(1, units="ns")
        dut.lut_wr_clk.value = 1
        await Timer(1, units="ns")

@cocotb.test()
async def lutfir(dut):
    dut.data_in.value = 0
    dut.di_strobe.value = 0
    dut.rst.value = 1
    dut.data_in.value = 0
    await Timer(1, units="ns")
    dut.rst.value = 0

    await cycle(dut)

    l = LutFIR.make_lowpass(1/32, 1/16, 8, 16, 16)
    lut_data = l.get_lut_data()
    lut_data = lut_data[:len(lut_data)//2] 

    for i in range(len(lut_data)):
        dut.lut_wr_addr.value = i
        dut.lut_wr_data.value = int(lut_data[i])
        dut.lut_wr_en.value = 1
        await cycle_wr(dut)

    dut.lut_wr_en.value = 0

    await cycle(dut)
    dut.di_strobe.value = 1

    await cycle(dut)

    dut.data_in.value = 0
    dut.di_strobe.value = 0

    await cycle(dut, 10)

    for i in range(len(test_input_data)):
        print(f"Running input: {test_input_data[i]}")
        dut.data_in.value = BinaryValue(test_input_data[i][::-1], n_bits=128)
        dut.di_strobe.value = 1

        await cycle(dut, 1)

        dut.data_in.value = 0
        dut.di_strobe.value = 0

        await cycle(dut, 1)

    await cycle(dut, 10)










