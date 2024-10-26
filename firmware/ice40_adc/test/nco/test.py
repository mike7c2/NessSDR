import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

from dsp_utils.nco import NCO



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

async def program_lut(dut, data):

    dut.lut_wr_addr.value = 0
    dut.lut_wr_data.value = 0

    await cycle_wr(dut)

    for i in range(len(data)):
        print(f"Data[{i}] == {data[i]}")
        dut.lut_wr_addr.value = i
        dut.lut_wr_data.value = int(data[i])
        dut.lut_wr_en.value = 1

        await cycle_wr(dut)

        dut.lut_wr_en.value = 0

@cocotb.test()
async def test(dut):
    dut.phase.value = 0
    dut.di_strobe.value = 0
    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    await cycle(dut)

    n = NCO(10, 16)
    data = n.get_lut_data()
    await program_lut(dut, data)

    outputs_idx = 0
    outputs_i = []
    outputs_q = []

    for i in range(4192):
        
        dut.di_strobe = 1
        
        await(cycle(dut))

        dut.di_strobe = 0

        if dut.out_i_strobe == 1:
            outputs_i.append(int(dut.data_out.value.signed_integer))

            outputs_idx += 1
        if dut.out_q_strobe == 1:
            outputs_q.append(int(dut.data_out.value.signed_integer))

            outputs_idx += 1

        await(cycle(dut))

        if dut.out_i_strobe == 1:
            outputs_i.append(int(dut.data_out.value.signed_integer))

            outputs_idx += 1

        if dut.out_q_strobe == 1:
            outputs_q.append(int(dut.data_out.value.signed_integer))

            outputs_idx += 1

        dut.phase = (int(dut.phase) + 11) & 0xFFF

    fig, axarr = plt.subplots(4)
    axarr[0].plot(outputs_i)
    axarr[1].plot(outputs_q)
    axarr[2].plot(data)
    axarr[3].magnitude_spectrum(outputs_i, scale="dB")
    plt.show()

