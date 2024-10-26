import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

import cocotb
from cocotb.triggers import Timer

from dsp_utils.lut_fir import LutFIR
from dsp_utils.nco import NCO

class ModulatorFixture:
    def __init__(self, dut, signal):
        self.dut = dut
        self.reference_voltage = 0.0
        self.signal = signal
        self.signal_idx = 0

        self.ADC_DATA_WIDTH = dut.ADC_DATA_WIDTH.value.integer
        self.SYNC_DELAY = dut.SYNC_DELAY.value.integer
        self.LUTS_POW = dut.LUTS_POW.value.integer
        self.LUT_WIDTH = dut.LUT_WIDTH.value.integer
        self.LUT_DEPTH = dut.LUT_DEPTH.value.integer
        self.LUTFIR_OUTPUT_WIDTH = dut.LUTFIR_OUTPUT_WIDTH.value.integer
        self.NCO_LUT_DEPTH = dut.NCO_LUT_DEPTH.value.integer
        self.NCO_LUT_WIDTH = dut.NCO_LUT_WIDTH.value.integer
        self.CIC_N = dut.CIC_N.value.integer
        self.CIC_R = dut.CIC_R.value.integer
        self.MULTIPLIER_STAGES = dut.MULTIPLIER_STAGES.value.integer

        self.fir_addr_width = self.LUT_DEPTH + self.LUTS_POW

        self.fir_addr_offset = 0
        self.nco_addr_offset = 2**self.fir_addr_width
        self.phase_addr_offset = 2**(self.fir_addr_width + 1)

        print(self)

    def __str__(self):
        s = (
            f"ModulatorFixture Configuration:\n"
            f"ADC_DATA_WIDTH: {self.ADC_DATA_WIDTH}\n"
            f"SYNC_DELAY: {self.SYNC_DELAY}\n"
            f"LUTS_POW: {self.LUTS_POW}\n"
            f"LUT_WIDTH: {self.LUT_WIDTH}\n"
            f"LUT_DEPTH: {self.LUT_DEPTH}\n"
            f"LUTFIR_OUTPUT_WIDTH: {self.LUTFIR_OUTPUT_WIDTH}\n"
            f"NCO_LUT_DEPTH: {self.NCO_LUT_DEPTH}\n"
            f"NCO_LUT_WIDTH: {self.NCO_LUT_WIDTH}\n"
            f"CIC_N: {self.CIC_N}\n"
            f"CIC_R: {self.CIC_R}\n"
            f"MULTIPLIER_STAGES: {self.MULTIPLIER_STAGES}\n"
        )
        return s

    async def reset(self):
        self.dut.rst.value = 1
        await Timer(1, units="ns")
        self.dut.rst.value = 0
        await Timer(1, units="ns")

    def step_dut(self):
        di_val = 0
        if self.reference_voltage > self.signal[self.signal_idx]:
            di_val |= 1
        
        if self.reference_voltage > self.signal[self.signal_idx+1]:
            di_val |= 2
        
        self.dut.adc_di.value = di_val
        self.signal_idx += 2

    async def write_mem_addr(self, addr, data):
        self.dut.lut_wr_addr.value = addr
        self.dut.lut_wr_data.value = int(data)
        self.dut.lut_wr_en.value = 1

        self.dut.lut_wr_clk.value = 0
        await Timer(1, units="ns")
        self.dut.lut_wr_clk.value = 1
        await Timer(1, units="ns")

        self.dut.lut_wr_en.value = 0

    async def program_lut(self, data):
        for i in range(len(data)):
            await self.write_mem_addr(i + self.fir_addr_offset, data[i])

    async def program_nco_lut(self, data):
        for i in range(len(data)):
            await self.write_mem_addr(i + self.nco_addr_offset, data[i])

    async def program_frequency(self, phase_value):
        await self.write_mem_addr(self.phase_addr_offset, phase_value)

    async def clock(self):
        self.dut.adc_clk.value = 0
        self.dut.if_proc_clk.value = 0
        self.dut.bb_proc_clk.value = 0
        await Timer(1, units="ns")
        self.dut.adc_clk.value = 1
        self.dut.if_proc_clk.value = 1
        self.dut.bb_proc_clk.value = 1
        await Timer(1, units="ns")

#@cocotb.test()
#async def basic(dut):
#    m = ModulatorFixture(dut, [])
#    m.reset()

@cocotb.test()
async def modulator(dut):
    fs = 500000
    t = 0.5
    f1 = 1055.1
    f2 = 600.3
    f3 = 24000

    n_samples = int(t*fs)

    downconversion = 16

    signal_voltages = np.zeros(n_samples)
    output_bits = np.zeros(n_samples)
    output_bits_idx = 0

    output_filtered = np.zeros(n_samples//16)
    output_filtered_idx = 0
    output_i = np.zeros(n_samples//16)
    output_i_idx = 0
    output_q = np.zeros(n_samples//16)
    output_q_idx = 0
    nco_i_out = np.zeros(n_samples//16)
    nco_i_out_idx = 0
    nco_q_out = np.zeros(n_samples//16)
    nco_q_out_idx = 0
    cic_i_out = np.zeros(n_samples//16)
    cic_i_out_idx = 0
    cic_q_out = np.zeros(n_samples//16)
    cic_q_out_idx = 0

    samples = np.linspace(0, t, int(fs*t), endpoint=False)
    sig = np.sin(2 * np.pi * f1 * samples)
    signal2 = np.sin(2 * np.pi * f2 * samples)
    signal3 = np.sin(2 * np.pi * f3 * samples)
    noise = np.random.normal(0, 2, n_samples) * 2

    sig += noise + signal2 + signal3

    modulator_fixture = ModulatorFixture(dut, sig)
    await modulator_fixture.reset()


    #l = LutFIR.make_lowpass(1/128, 1/64, 8, 16, 16)
    #l = LutFIR.make_bandpass(1/64, 1/512, 1/128, 8, 16, 16)
    l = LutFIR.make_nyquist(16, 1, 8, 16, 16)
    lut_data = l.get_lut_data()
    lut_data = lut_data[:len(lut_data)//2] # Discard half the data - it's symmetrical
    await modulator_fixture.program_lut(lut_data)
    nco = NCO(modulator_fixture.NCO_LUT_DEPTH, modulator_fixture.NCO_LUT_WIDTH)
    nco_lut_data = nco.get_lut_data()
    await modulator_fixture.program_nco_lut(nco_lut_data)
    await modulator_fixture.program_frequency(-(234*64+25))

    reference_data = l.process(sig)



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

        if dut.dc_data_strobe.value == 1:
            output_filtered[output_filtered_idx] = dut.dc_data_out.value.signed_integer
            output_filtered_idx += 1
        
        if dut.mul_i_strobe.value == 1:
            output_i[output_i_idx] = int(dut.multiplier_out.value.signed_integer)
            output_i_idx += 1

        if dut.mul_q_strobe.value == 1:
            output_q[output_q_idx] = int(dut.multiplier_out.value.signed_integer)
            output_q_idx += 1
        
        if dut.nco_i_strobe.value == 1:
            nco_i_out[nco_i_out_idx] = int(dut.nco_data_out.value.signed_integer)
            nco_i_out_idx += 1

        if dut.cic_i_strobe.value == 1:
            cic_i_out[cic_i_out_idx] = int(dut.cic_out_i.value.signed_integer)
            cic_i_out_idx += 1

        if dut.nco_q_strobe.value == 1:
            nco_q_out[nco_q_out_idx] = int(dut.nco_data_out.value.signed_integer)
            nco_q_out_idx += 1

        if dut.cic_q_strobe.value == 1:
            cic_q_out[cic_q_out_idx] = int(dut.cic_out_q.value.signed_integer)
            cic_q_out_idx += 1

        await modulator_fixture.clock()
    
    iq_out = np.zeros(n_samples//16, dtype=np.complex128)
    iq_out.real = output_i / 2**31
    iq_out.imag = output_q / 2**31

    nco_out = np.zeros(n_samples//16, dtype=np.complex128)
    nco_out.real = nco_i_out / 2**31
    nco_out.imag = nco_q_out / 2**31

    cic_out = np.zeros(n_samples//16, dtype=np.complex128)
    cic_out.real = cic_i_out / 2**16
    cic_out.imag = cic_q_out / 2**16

    fig, ax = plt.subplots(8,2)

    output_filtered /= 2**19
    reference_data /= 2**19

    filter_impulse_response = l.impulse_response()
    filter_impulse_response /= 2**19

    plot_td_and_spectrum(ax[0], signal_voltages, "Input data", fs, downconversion)
    plot_td_and_spectrum(ax[1], filter_impulse_response, "Ref. filter response", fs, downconversion)
    plot_td_and_spectrum(ax[2], output_bits, "ADC Output", fs, downconversion)

    plot_td_and_spectrum(ax[3], reference_data[::16], "Ref filter output", fs/downconversion)
    plot_td_and_spectrum(ax[4], output_filtered, "HW filter output", fs/downconversion)
    
    plot_td_and_spectrum(ax[5], iq_out, "Mixed output", fs/downconversion)

    plot_td_and_spectrum(ax[6], nco_out, "NCO output", fs/downconversion, rng=(-200, 0))
    plot_td_and_spectrum(ax[7], cic_out[:cic_q_out_idx], "CIC output", fs/(downconversion*16), rng=(-100, 100))

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
