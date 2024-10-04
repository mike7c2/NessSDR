import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue

from dsp_utils.lut_fir import LutFIR



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

    for i in range(len(data)):
        dut.lut_wr_addr.value = i
        dut.lut_wr_data.value = int(data[i])
        dut.lut_wr_en.value = 1

        await cycle_wr(dut)

        dut.lut_wr_en.value = 0

@cocotb.test()
async def test(dut):
    dut.phase.value = 0
    dut.sample_en.value = 0
    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    await cycle(dut)

    data = np.sin(np.linspace(0,np.pi/2, 1024)) * (2**16)-1
    await program_lut(dut, data)

    outputs_idx = 0
    outputs_i = []
    outputs_q = []

    for i in range(4192):
        phase = int(dut.phase)
        dut.phase = (phase + 4) & 0xFFF
        dut.sample_en = 1

        await(cycle(dut))

        dut.sample_en = 0

        if dut.out_strobe == 1:
            outputs_i.append(int(dut.i_out))
            outputs_q.append(int(dut.q_out))

            outputs_idx += 1

        await(cycle(dut))

        if dut.out_strobe == 1:
            outputs_i.append(int(dut.i_out))
            outputs_q.append(int(dut.q_out))

            outputs_idx += 1

    fig, axarr = plt.subplots(3)
    axarr[0].plot(outputs_i)
    axarr[1].plot(outputs_q)
    axarr[2].plot(data)
    plt.show()

