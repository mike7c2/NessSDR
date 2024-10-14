import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer

from dsp_utils.lut_fir import LutFIR

class ModulatorFixture:
    def __init__(self, dut, signal):
        self.dut = dut
        self.reference_voltage = 0.0
        self.signal = signal

        self.signal_idx = 0

    def step_dut(self):

        di_val = 0

        if self.reference_voltage > self.signal[self.signal_idx]:
            di_val |= 1
        
        if self.reference_voltage > self.signal[self.signal_idx+1]:
            di_val |= 2
        
        self.dut.adc_di.value = di_val
            

        self.signal_idx += 2

    async def program_lut(self, data):

        for i in range(len(data)):
            self.dut.lut_wr_addr.value = i
            self.dut.lut_wr_data.value = int(data[i])
            self.dut.lut_wr_en.value = 1

            self.dut.lut_wr_clk.value = 0
            await Timer(1, units="ns")
            self.dut.lut_wr_clk.value = 1
            await Timer(1, units="ns")

            self.dut.lut_wr_en.value = 0

            self.dut.lut_wr_clk.value = 0
            await Timer(1, units="ns")
            self.dut.lut_wr_clk.value = 1
            await Timer(1, units="ns")

    async def program_nco_lut(self, data):

        for i in range(len(data)):
            self.dut.lut_wr_addr.value = i
            self.dut.lut_wr_data.value = int(data[i])
            self.dut.nco_lut_wr_en.value = 1

            self.dut.lut_wr_clk.value = 0
            await Timer(1, units="ns")
            self.dut.lut_wr_clk.value = 1
            await Timer(1, units="ns")

            self.dut.nco_lut_wr_en.value = 0

            self.dut.lut_wr_clk.value = 0
            await Timer(1, units="ns")
            self.dut.lut_wr_clk.value = 1
            await Timer(1, units="ns")

async def clock(dut):
    dut.adc_clk.value = 0
    dut.if_proc_clk.value = 0
    dut.bb_proc_clk.value = 0
    await Timer(1, units="ns")
    dut.adc_clk.value = 1
    dut.if_proc_clk.value = 1
    dut.bb_proc_clk.value = 1
    await Timer(1, units="ns")

@cocotb.test()
async def modulator(dut):
    fs = 500000
    t = 0.1
    f1 = 1055.1
    f2 = 600.3
    f3 = 24000

    n_samples = int(t*fs)

    downconversion = 16

    signal_voltages = np.zeros(n_samples)
    output_bits = np.zeros(n_samples)
    output_filtered = np.zeros(n_samples//16)
    output_bits_idx = 0
    output_filtered_idx = 0
    samples = np.linspace(0, t, int(fs*t), endpoint=False)
    sig = np.sin(2 * np.pi * f1 * samples)
    signal2 = np.sin(2 * np.pi * f2 * samples)
    signal3 = np.sin(2 * np.pi * f3 * samples)
    noise = np.random.normal(0, 2, n_samples)

    sig += noise + signal2 + signal3

    modulator_fixture = ModulatorFixture(dut, sig)
    print(dir(dut))
    dut.rst.value = 1
    await Timer(1, units="ns")
    dut.rst.value = 0

    #l = LutFIR.make_lowpass(1/128, 1/64, 8, 16, 16)
    l = LutFIR.make_bandpass(1/64, 1/512, 1/128, 8, 16, 16)
    lut_data = l.get_lut_data()
    lut_data = lut_data[:len(lut_data)//2] # Discard half the data - it's symmetrical
    print(len(lut_data))
    reference_data = l.process(sig)

    await modulator_fixture.program_lut(lut_data)


    nco_lut_data = np.sin(np.linspace(0,np.pi/2, 1024)) * (2**16)-1
    await modulator_fixture.program_nco_lut(nco_lut_data)


    for i in range(n_samples//2):
        signal_voltages[i*2] = modulator_fixture.signal[modulator_fixture.signal_idx]
        signal_voltages[i*2+1] = modulator_fixture.signal[modulator_fixture.signal_idx+1]

        modulator_fixture.step_dut()

        if dut.adc_do_strobe.value == 1:
            for b in dut.adc_do.value:
                try:
                    output_bits[output_bits_idx] = b
                except:
                    output_bits[output_bits_idx] = 0
                output_bits_idx += 1
            #print(dut.adc_do.value)
        n_bits = 16
        if dut.dc_data_strobe.value == 1:
             
            unsigned_value = int(dut.dc_data_out.value)
            if unsigned_value >= (1 << (n_bits - 1)):  # Check if the MSB is set (sign bit)
                output_filtered[output_filtered_idx] = unsigned_value - (1 << n_bits)
            else:
                output_filtered[output_filtered_idx] = unsigned_value
            output_filtered[output_filtered_idx]
            output_filtered_idx += 1

        await clock(dut)

    fig, ax = plt.subplots(5,2)

    output_filtered /= 2**(n_bits-1)
    reference_data /= 2**19

    filter_impulse_response = l.impulse_response()
    filter_impulse_response /= 2**19

    plot_td_and_spectrum(ax[0], signal_voltages, "Input data", fs, downconversion)
    plot_td_and_spectrum(ax[1], filter_impulse_response, "Ref. filter response", fs, downconversion)
    plot_td_and_spectrum(ax[2], output_bits, "ADC Output", fs, downconversion)

    plot_td_and_spectrum(ax[3], reference_data[::16], "Ref filter output", fs/downconversion)
    plot_td_and_spectrum(ax[4], output_filtered, "HW filter output", fs/downconversion)
    
    plt.tight_layout()
    plt.show()

def plot_td_and_spectrum(ax_arr, signal, name, fs, nyquist_lines=None, rng=(-100, 0)):
    ax_arr[0].plot(signal)
    ax_arr[0].set_xlabel(f"{name} (time/samples)")
    ax_arr[1].magnitude_spectrum(signal, scale="dB", Fs=fs)
    ax_arr[1].set_xlabel(f"{name} (freq)")
    ax_arr[1].set_ylim(rng)
    if nyquist_lines is not None:
        for i in range(nyquist_lines):
            x_point = ((fs/2)/nyquist_lines) * i
            ax_arr[1].plot([x_point, x_point], rng, color="grey")
