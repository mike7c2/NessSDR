import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

from dsp_utils.lut_fir import LutFIR
from random import randint


async def cycle(dut, n = 1):
    for i in range(n):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")




@cocotb.test()
async def multiplier(dut):
    n_bits = 32
    inputs = [(a, b, a * b) for b in range(0, 10) for a in range(0, 10)]
    inputs += [(a, b, a * b) for b in range(-4, 4) for a in range(-4, 4)]
    for i in range(1000):
        a = randint(-32768,32767)
        b = randint(-32768,32767)
        inputs.append((a, b, a*b))
    outputs = []

    dut.data_in_a = 0
    dut.data_in_b = 0

    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    await cycle(dut)

    for i in range(len(inputs)):

        dut.data_in_a = inputs[i][0]
        dut.data_in_b = inputs[i][1]

        if int(dut.data_out) >= (1 << (n_bits - 1)):  # Check if the MSB is set (sign bit)
            outputs.append(int(dut.data_out) - (1 << n_bits))
        else:
            outputs.append(int(dut.data_out))
        await cycle(dut)

    for i in range(len(inputs)-6):
        if outputs[i+6] != inputs[i][2]:
            print(f"Error!! Wanted {inputs[i][2]} Got {outputs[i+6]}")
        else:
            print(f"{inputs[i][0]} * {inputs[i][1]} == {inputs[i][2]}")







