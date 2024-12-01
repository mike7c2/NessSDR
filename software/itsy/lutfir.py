from scipy import signal
import numpy as np
import matplotlib.pyplot as plt
import argparse
import logging

logger = logging.getLogger(__name__)


class LutFIR:
    def __init__(self, taps, lut_width, lut_bitdepth, n_luts):

        if len(taps) != lut_width * n_luts:
            raise Exception("Taps must be exact length of lut width * n_luts")

        unscaled_segments = []

        for i in range(n_luts):
            unscaled_segments.append(LutFIR.make_lut(
                taps[i*lut_width:(i+1)*lut_width]))

        maximum = 0
        for o in unscaled_segments:
            if np.max(np.abs(o)) > maximum:
                maximum = np.max(np.abs(o))

        segments = []
        for o in unscaled_segments:
            o /= maximum
            o *= 2**(lut_bitdepth-1)-1
            segments.append(o.astype(np.int32))

        self.lut_width = lut_width
        self.lut_bitdepth = lut_bitdepth
        self.n_luts = n_luts

        self.segments = segments
        self.reference = taps

    def length(self):
        return self.lut_width * self.n_luts

    @staticmethod
    def make_lut(taps):
        nvals = 2**len(taps)
        outputs = np.zeros(nvals)

        
        for i in range(nvals):
            vals = np.zeros(len(taps))
            for j in range(len(taps)):
                if (i & (1 << j)) != 0:
                    vals[j] = 1
                else:
                    vals[j] = -1
            outputs[i] = np.sum(taps * vals)
        
        # Experiment, flip address indexes
        """
        for i in range(nvals):
            vals = np.zeros(len(taps))
            for j in range(len(taps)):
                if (i & ((1 << (len(taps)-1)) >> j)) != 0:
                    vals[j] = 1
                else:
                    vals[j] = -1
            outputs[i] = np.sum(taps * vals)
        """

        return outputs
        
    def process(self, data):
        data_out = np.zeros(len(data) - self.n_luts * self.lut_width)
        for i in range(len(data) - self.n_luts * self.lut_width):
            data_slice = data[i:i+self.n_luts * self.lut_width]
            lut_results = []
            for lut in range(self.n_luts):
                addr_bits = data_slice[lut*self.lut_width:(lut+1)*self.lut_width]
                addr = 0
                for j in range(len(addr_bits)):
                    if addr_bits[j] > 0:
                        addr |= 1 << j
                lut_results.append(self.segments[lut][addr])

            data_out[i] = sum(lut_results)
        return data_out

    def get_lut_data(self):
        lut_data = np.zeros(2**self.lut_width * self.n_luts, dtype=np.int32)
        for i, s in enumerate(self.segments):
            lut_data[2**self.lut_width * i: 2**self.lut_width * (i+1)] = s
        return lut_data

    def impulse_response(self):
        impulse = np.zeros(self.length()*2)
        impulse[self.length()] = 1
        impulse[self.length()+1] = -1

        response = self.process(impulse)

        return response

    def normalise_data(self, data):
        data /= 2**(self.lut_width-1)
        return data

    @staticmethod
    def make_lowpass(passband, cutoff, lut_width, lut_bitdepth, n_luts):
        num_taps = lut_width*n_luts
        frequencies = [
            0.0,
            passband/2,
            cutoff/2,
            0.5
        ]
        gains = [1, 1, 0, 0]
        logger.debug(f"Making filter, freqs: {frequencies}, gains: {gains}")
        coefficients = signal.firwin2(num_taps, frequencies, gains, fs=1.0)

        return LutFIR(coefficients, lut_width, lut_bitdepth, n_luts)

    @staticmethod
    def make_bandpass(center, passband, cutoff, lut_width, lut_bitdepth, n_luts):
        logger.debug(
            f"center: {center}, passband: {passband}, cutoff: {cutoff}, lut_width: {lut_width}, lut_bitdepth: {lut_bitdepth}, nluts: {n_luts}")
        num_taps = lut_width*n_luts
        frequencies = [
            0.0,
            center-cutoff/2,
            center-passband/2,
            center,
            center+passband/2,
            center+cutoff/2,
            0.5
        ]
        gains = [0, 0, 1, 1, 1, 0, 0]
        coefficients = signal.firwin2(num_taps, frequencies, gains, fs=1.0)

        return LutFIR(coefficients, lut_width, lut_bitdepth, n_luts)

    @staticmethod
    def nyquist_params(downconversion, zone, lut_width, lut_bitdepth, n_luts):
        n_nyzones = downconversion
        center = (zone / (n_nyzones*2)) + (1 / (downconversion * 4))
        passband = 1 / (n_nyzones * 8.01)
        cutoff = 1 / (n_nyzones * 4.01)

        return (center, passband, cutoff, lut_width, lut_bitdepth, n_luts)

    @staticmethod
    def make_nyquist(downconversion, zone, lut_width, lut_bitdepth, n_luts):
        params = LutFIR.nyquist_params(
            downconversion, zone, lut_width, lut_bitdepth, n_luts)
        return LutFIR.make_bandpass(*params)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    commands = parser.add_mutually_exclusive_group(required=True)
    commands.add_argument("--bandpass", action="store_true",
                          help="Make a bandpass filter")
    commands.add_argument("--lowpass", action="store_true",
                          help="Make a lowpass filter")
    commands.add_argument("--nyquist", action="store_true",
                          help="Make a nyquist filter")
    parser.add_argument("--plot", action="store_true",
                        help="Show noise response of filter")
    parser.add_argument("--center", type=float, default=0.25,
                        help="Center frequency for bandpass")
    parser.add_argument("--cutoff", type=float, default=16,
                        help="Cutoff = (fs/2)/cutoff")
    parser.add_argument("--passband", type=float, default=32,
                        help="Passband = (fs/2)/passband")
    parser.add_argument("--width", type=int, default=8,
                        help="Address width of LUT")
    parser.add_argument("--word", type=int, default=16,
                        help="Word size of LUT")
    parser.add_argument("--nluts", type=int, default=16, help="Number of luts")
    parser.add_argument("--downconversion", type=int,
                        default=16, help="Downconversion factor")
    parser.add_argument("--zone", type=int, default=1, help="Nyquist zone")
    args = parser.parse_args()

    filt = None

    passband_width = 1 / args.passband
    cutoff_width = 1 / args.cutoff

    if args.bandpass:
        filt = LutFIR.make_bandpass(
            args.center, passband_width, cutoff_width, args.width, args.word, args.nluts)
    elif args.lowpass:
        filt = LutFIR.make_lowpass(
            passband_width, cutoff_width, args.width, args.word, args.nluts)
    elif args.nyquist:
        filt = LutFIR.make_nyquist(args.downconversion,
                                   args.zone, args.width, args.word, args.nluts)

    if args.plot:
        noise = np.random.normal(0, 1, 100000)
        noise[noise > 0] = 1
        noise[noise < 0] = 0

        data = filt.normalise_data(filt.process(noise))
        ir = filt.normalise_data(filt.impulse_response())

        fig, axarr = plt.subplots(1)
        axarr = [axarr]
        axarr[0].magnitude_spectrum(noise, scale="dB", label="Noise")
        axarr[0].magnitude_spectrum(data, scale="dB", label="Response")
        axarr[0].magnitude_spectrum(ir, scale="dB", label="Impulse response")

        if args.lowpass:
            axarr[0].plot([passband_width, passband_width],
                          [-100, 100], color="green")
            axarr[0].plot([cutoff_width, cutoff_width],
                          [-100, 100], color="red")
            axarr[0].plot([cutoff_width*2, cutoff_width*2],
                          [-100, 100], color="red")
        elif args.bandpass:
            axarr[0].plot([passband_width, passband_width],
                          [-100, 100], color="green")
            axarr[0].plot([cutoff_width, cutoff_width],
                          [-100, 100], color="red")
            axarr[0].plot([cutoff_width*2, cutoff_width*2],
                          [-100, 100], color="red")
        elif args.nyquist:
            (center, passband, cutoff, lut_width, lut_bitdepth, n_luts) = LutFIR.nyquist_params(
                args.downconversion, args.zone, args.width, args.word, args.nluts)
            axarr[0].plot([center*2, center*2], [-100, 100], color="green")
            axarr[0].plot(
                [(center + passband)*2, (center + passband) * 2], [-100, 100], color="red")
            axarr[0].plot([(center + cutoff)*2, (center + cutoff)
                          * 2], [-100, 100], color="red")

        axarr[0].legend()
        plt.show()
