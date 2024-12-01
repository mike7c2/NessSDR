import numpy as np
import matplotlib.pyplot as plt
import random
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

def ints_to_std_logic_vector(values, bit_width):
    mask = (1 << bit_width) - 1
    values = [x & mask for x in values]
    
    combined = 0
    for value in values:
        combined = (combined << bit_width) | value

    total_bits = len(values) * bit_width

    return BinaryValue(value=combined, n_bits=total_bits, bigEndian=False)

async def cycle(dut, n = 1):
    for i in range(n):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")


@cocotb.test()
async def test(dut):
    input_data = [
        [0, 1, 2, 3, 4, 5, 6, 7],
        [-1]*8,
        [1]*8,
        [-32768]*8,
        [32767]*8,
    ]

    for i in range(100000):
        row = []
        for j in range(8):
            row.append(random.randint(-32768, 32767))
        input_data.append(row)

    output_predicted = []

    # Stuff dummy values for pipeline delay
    output_predicted.append(0)
    output_predicted.append(0)
    output_predicted.append(0)

    for i in input_data:
        output_predicted.append(sum(i))

    output_measured = []

    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    for i in input_data:
        dut.data_in.value = ints_to_std_logic_vector(i, 16)
        await cycle(dut)
        output_measured.append(int(dut.data_out.value.signed_integer))

    for i in range(len(output_measured)):
        assert(output_predicted[i] == output_measured[i])
