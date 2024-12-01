import threading
import socket
import argparse
import json
import logging

from pyftdi.spi import SpiController

from itsysdr import ItsySDR, DEFAULT_DEVICE_URL, SPI_FREQUENCY

logger = logging.getLogger(__name__)


class ItsyNetWrapper:
    def __init__(self, args):
        self.args = args
        self.spi = SpiController()
        self.spi.configure(DEFAULT_DEVICE_URL)
        self.slave = self.spi.get_port(cs=0, freq=SPI_FREQUENCY, mode=0)

        # Initialize ItsySDR instance with required parameters
        self.itsy = ItsySDR(self.slave)

        # Prepare sockets
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.bind((args.host_ip, args.host_port))
        self.server_socket.listen(1)

        self.command_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.command_socket.bind((args.host_ip, args.command_port))
        self.command_socket.listen(1)

    def start(self):
        # Start the NCO and filter on the ItsySDR device
        self.itsy.init_nco_lut()
        self.itsy.program_filter(self.args.nyquist)
        self.itsy.program_nco_frequency(self.args.frequency)
        self.itsy.set_output_mode(0x0000)

        # Start command socket thread
        threading.Thread(target=self.command_socket_thread,
                         daemon=True).start()

        # Main streaming loop
        while True:
            client_socket, client_address = self.server_socket.accept()
            logger.info("Streaming client connected!")
            self.handle_client(client_socket)

    def command_socket_thread(self):
        while True:
            client_socket, client_address = self.command_socket.accept()
            logger.info("Command client connected!")
            full_msg = b""
            while True:
                msg = client_socket.recv(1024)
                if not msg:
                    break
                full_msg += msg
            try:
                command = json.loads(full_msg.decode("utf-8"))
                try:
                    self.handle_command(command)
                except:
                    logger.exception("Failed to handle command")
            except json.JSONDecodeError:
                logger.warning("Received invalid JSON format.")
            client_socket.close()

    def handle_command(self, command):
        logger.info(f"Got command: {command}")
        cmd = command.get("cmd")
        if cmd == "freq":
            freq = float(command.get("frequency"))
            self.itsy.program_nco_frequency(freq)
        elif cmd == "mode":
            mode = int(command.get("mode"))
            self.itsy.set_output_mode(mode)
        elif cmd == "filter":
            zone = float(command.get("zone"))
            self.itsy.program_filter(zone)
        else:
            logger.warning(f"Unknown command received: {cmd}")

    def handle_client(self, client_socket):
        try:
            self.itsy.start_streaming()
            while True:
                samples = self.itsy.get_samples()
                client_socket.sendall(samples)

        except (ConnectionResetError, BrokenPipeError):
            logger.info("Streaming client disconnected!")
        finally:
            self.itsy.stop_streaming()
            client_socket.close()

    def stop(self):
        self.spi.terminate()
        self.server_socket.close()
        self.command_socket.close()


def run(args):
    wrapper = ItsyNetWrapper(args)
    try:
        wrapper.start()
    finally:
        wrapper.stop()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host-ip", default="127.0.0.1", help="Server IP")
    parser.add_argument("--host-port", type=int,
                        default=2000, help="Server port")
    parser.add_argument("--command-port", type=int,
                        default=2010, help="Server port")
    parser.add_argument("nyquist", type=float, default=None,
                        help="Filter center nyquist zone")
    parser.add_argument("frequency", type=float,
                        default=None, help="Mixer LO frequency")

    logging.basicConfig(encoding='utf-8', level=logging.INFO)

    run(parser.parse_args())
