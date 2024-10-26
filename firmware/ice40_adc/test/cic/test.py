import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import numpy as np
import matplotlib.pyplot as plt

# Clock generator coroutine
async def clock_gen(clk, period_ns=10):
    """Generate clock signal with given period in nanoseconds"""
    while True:
        clk <= 0
        await Timer(period_ns // 2, units='ns')
        clk <= 1
        await Timer(period_ns // 2, units='ns')

@cocotb.test()
async def test_cic_filter(dut):
    """ Test the CIC filter with a step input signal """
    dut.input_sig = int(0)

    # Parameters
    N = int(dut.N)  # Number of stages

    # Start the clock
    cocotb.start_soon(clock_gen(dut.clk))
    dut.en = 1
    # Reset the DUT
    dut.rst = 1
    await Timer(20, units='ns')  # Keep reset active for 20ns
    dut.rst = 0
    await RisingEdge(dut.clk)  # Wait for first rising edge after reset is deasserted

    input_length = 20000  # Length of the input signal
    noise = np.random.normal(0, 2, input_length)
    # Generate input signal (simple step function)
    input_signal = np.zeros(input_length, dtype=np.int32)
    #input_signal[:input_length//4] = -1
    #input_signal[input_length//4:] = 1  # Step at 100th sample
    #input_signal[input_length//2:] = 0  # Step at 100th sample
    #input_signal[len(input_signal)//2] = -1
    input_signal[len(input_signal)//2 + 1] = 1
    #input_signal = noise
    input_signal *= 8
    #input_signal += noise
    # Arrays to store the input and output for plotting
    output_signal = []

    # Apply input signal and capture output
    for i in range(input_length):
        # Apply input signal to the DUT
        dut.input_sig = int(input_signal[i])

        # Wait for a clock cycle
        await RisingEdge(dut.clk)

        # Capture the output after decimation
        #if dut.output_sig.value.is_resolvable:
        if dut.output_strobe.value.integer == 1:
            output_signal.append(int(dut.output_sig.value.signed_integer))

    # Plot input and output signals
    plt.figure(figsize=(10, 6))
    plt.subplot(4, 1, 1)
    plt.plot(input_signal, label='Input Signal')
    plt.title(f'CIC Filter Test (N={N})')
    plt.legend()

    plt.subplot(4, 1, 2)
    plt.plot(output_signal, label='Output Signal', color='orange')
    plt.title('Filtered (Decimated) Output')
    plt.legend()

    plt.subplot(4, 1, 3)
    plt.magnitude_spectrum(input_signal, label='Input Signal', scale="dB")
    plt.title(f'CIC Filter Test (N={N})')
    plt.legend()

    plt.subplot(4, 1, 4)
    plt.magnitude_spectrum(output_signal, label='Output Signal', color='orange', scale="dB")
    plt.title('Filtered (Decimated) Output')
    plt.legend()

    plt.tight_layout()
    plt.show()
