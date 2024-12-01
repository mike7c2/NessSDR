import time
import numpy as np
import queue
import threading
import logging

from nco import NCO
from lutfir import LutFIR

logger = logging.getLogger(__name__)


SAMPLING_FREQUENCY = 400000000
LUTS_POW = 3
LUT_WIDTH = 16
FIR_LUT_DEPTH = 8
NCO_LUT_DEPTH = 10
NCO_LUT_WIDTH = 16
STAGE1_DC = 16
STAGE2_DC = 32

SPI_FREQUENCY = 20_000_000  # Tested for IF clk 80Mhz

DEFAULT_DEVICE_URL = "ftdi://ftdi:2232h/2"


class ItsySDRHWCommands:
    WRITE_COMMAND = 0x0001
    START_STREAMING_COMMAND = 0x0003
    STOP_STREAMING_COMMAND = 0x0004
    CLEAR_FIFO_COMMAND = 0x0005

    FIR_ADDR_OFFSET = 0
    NCO_ADDR_OFFSET = 0x4000
    SETTING_ADDR_OFFSET = 0x8000

    @staticmethod
    def write_data(address, data, signed=True):
        cmd = ItsySDRHWCommands.WRITE_COMMAND.to_bytes(2, byteorder='big')
        cmd += address.to_bytes(2, byteorder='big')
        cmd += int(data).to_bytes(2, byteorder='big', signed=signed)
        return cmd

    @staticmethod
    def start_streaming():
        cmd = ItsySDRHWCommands.START_STREAMING_COMMAND.to_bytes(
            2, byteorder='big')
        return cmd

    @staticmethod
    def stop_streaming():
        cmd = ItsySDRHWCommands.STOP_STREAMING_COMMAND.to_bytes(
            2, byteorder='big')
        return cmd

    @staticmethod
    def program_nco_frequency(Fs, Dc, frequency):
        nco_f = Fs / Dc

        phase_value = int(((frequency * 2**16) / nco_f) % 32768)
        logger.debug(f"Setting phase value: {phase_value}")
        return ItsySDRHWCommands.write_data(ItsySDRHWCommands.SETTING_ADDR_OFFSET, phase_value)

    @staticmethod
    def program_output_setting(setting):
        return ItsySDRHWCommands.write_data(ItsySDRHWCommands.SETTING_ADDR_OFFSET + 1, setting, signed=False)


class ItsySDR:

    def __init__(self, spi_slave):
        self.running = True
        self.data_queue = queue.Queue()
        self.command_queue = queue.Queue()

        self.last_ctr = 0
        self.spi = spi_slave

        self.clear_fifo = True
        self.mode = 0

    def write_data(self, address, data):
        self.spi.write(ItsySDRHWCommands.write_data(address, data))

    def program_filter(self, zone):
        filt = LutFIR.make_nyquist(16, zone, FIR_LUT_DEPTH,
                                   LUT_WIDTH, 2**(LUTS_POW+1))
        lut_data = filt.get_lut_data()
        # Discard half the data - it's symmetrical
        lut_data = lut_data[:len(lut_data)//2]

        self.command_queue.put(
            b"".join([ItsySDRHWCommands.write_data(
                i + ItsySDRHWCommands.FIR_ADDR_OFFSET, x, True) for i, x in enumerate(lut_data)])
        )

    def program_filter_lowpass(self):
        filt = LutFIR.make_lowpass(1/32, 1/16, FIR_LUT_DEPTH,
                                   LUT_WIDTH, 2**(LUTS_POW+1))
        lut_data = filt.get_lut_data()
        # Discard half the data - it's symmetrical
        lut_data = lut_data[:len(lut_data)//2]

        self.command_queue.put(
            b"".join([ItsySDRHWCommands.write_data(
                i + ItsySDRHWCommands.FIR_ADDR_OFFSET, x, True) for i, x in enumerate(lut_data)])
        )

    def init_nco_lut(self):
        nco = NCO(NCO_LUT_DEPTH, NCO_LUT_WIDTH)
        nco_lut_data = nco.get_lut_data()

        self.command_queue.put(
            b"".join([ItsySDRHWCommands.write_data(
                i + ItsySDRHWCommands.NCO_ADDR_OFFSET, x, True) for i, x in enumerate(nco_lut_data)])
        )

    def start_streaming(self):
        logger.info("Starting streaming")
        self.command_queue.put(ItsySDRHWCommands.start_streaming())
        self.start_reader_thread()

    def stop_streaming(self):
        logger.info("Stopping streaming")
        self.command_queue.put(ItsySDRHWCommands.stop_streaming())

        while not self.command_queue.empty():
            time.sleep(0.1)

        logger.info("Stopped streaming")
        self.running = False

    def program_nco_frequency(self, frequency):
        self.command_queue.put(ItsySDRHWCommands.program_nco_frequency(
            SAMPLING_FREQUENCY, STAGE1_DC, frequency))

    def set_output_mode(self, mode):
        self.mode = mode
        self.command_queue.put(ItsySDRHWCommands.program_output_setting(mode))

    def stream_data(self, cmd, n):
        if cmd is None:
            cmd = b""

        return self.spi.exchange(cmd, n+2)

    def start_reader_thread(self):
        self.running = True
        self.reader_thread = threading.Thread(target=self.reader_thread_impl)
        self.reader_thread.start()

    def reader_thread_impl(self):
        while self.running:
            cmd = b""

            if self.mode == 1 or self.mode == 2:
                cmd += b"\x05"

            try:
                cmd = self.command_queue.get(block=False)
                logger.debug(f"Sending command len({len(cmd)}): {cmd.hex()}")
            except queue.Empty:
                pass
            data = self.stream_data(cmd, 32768)
            self.data_queue.put(data)
        logger.info("Streamer thread exiting")

    def get_samples(self):
        if self.mode == 0 or self.mode == 1:
            return self.get_iq_samples()
        elif self.mode == 2:
            return self.get_real_samples()

    def get_iq_samples(self):
        data = self.data_queue.get()

        data_u16 = np.array(data).view(dtype=np.uint16, )
        ctr = ((data_u16 & 0x0100) >> 8) | ((data_u16 & 0x0001) << 1)
        data_iq_u16 = (data_u16 & 0xFEFE)

        unique_indices = np.where(
            np.diff(np.concatenate(([self.last_ctr], ctr))) != 0)[0]
        self.last_ctr = ctr[-1]
        unique_iq_u16 = data_iq_u16[unique_indices]
        logger.debug(
            f"Dropped {len(data_iq_u16) - len(unique_iq_u16)} samples")

        return unique_iq_u16.tobytes()

    def get_real_samples(self):
        data = self.data_queue.get()

        data_i16 = np.array(data).view(dtype=np.int16, )
        ctr = ((data_i16 & 0x0100) >> 8) | ((data_i16 & 0x0001) << 1)
        data_fixed_i16 = ((data_i16 & (np.int16(0xFE)<<8)) >> 2) | ((data_i16 & 0xFE) >> 1)

        unique_indices = np.where(
            np.diff(np.concatenate(([self.last_ctr], ctr))) != 0)[0]
        self.last_ctr = ctr[-1]
        unique_i16 = data_fixed_i16[unique_indices]
        logger.debug(
            f"Dropped {len(data_fixed_i16) - len(unique_i16)} samples")

        return unique_i16.tobytes()
