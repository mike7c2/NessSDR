import sys
import numpy as np
import threading
from gnuradio import gr
import socket



class ExampleBlock(gr.sync_block):
    def __init__(self, mode=0, frequency=0, zone=1.0):
        # Initialize the block with no inputs and one complex 8-bit output
        gr.sync_block.__init__(
            self,
            name="ExampleBlock",
            in_sig=[np.complex64],
            out_sig=[np.complex64]
        )
        
        # Initialize settings with default values
        self.mode = mode
        self.last_mode = -1
        self.frequency = frequency
        self.last_frequency = -1
        self.zone = zone
        self.last_zone = -1
        self.send_message("localhost", 2010, "{" + f'"cmd": "freq", "frequency":{self.frequency}' + "}")

        print("Blarg")

    def async_message(self, server_ip, server_port, message):
        threading.Thread(target=self.send_message, args=(server_ip, server_port, message)).start()

    def send_message(self, server_ip, server_port, message):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((server_ip, server_port))
            s.sendall(message.encode())

    def work(self, input_items, output_items):
        out = output_items[0]

        if self.last_mode != self.mode:
            self.last_mode = self.mode
            self.async_message("localhost", 2010, "{" + f'"cmd": "mode", "mode":{self.mode}' + "}")

        if self.last_frequency != self.frequency:
            self.last_frequency = self.frequency
            self.async_message("localhost", 2010, "{" + f'"cmd": "freq", "frequency":{self.frequency}' + "}")

        if self.last_zone != self.zone:
            self.last_zone = self.zone
            self.async_message("localhost", 2010, "{" + f'"cmd": "filter", "zone":{self.zone}' + "}")

        out[:] = input_items[0][:]

        return len(out)
