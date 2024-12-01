#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Not titled yet
# GNU Radio version: 3.10.11.0

from PyQt5 import Qt
from gnuradio import qtgui
from PyQt5 import QtCore
from gnuradio import analog
from gnuradio import blocks
from gnuradio import gr
from gnuradio.filter import firdes
from gnuradio.fft import window
import sys
import signal
from PyQt5 import Qt
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import network
from gnuradio import soapy
import lime_epy_block_0 as epy_block_0  # embedded python block
import sip
import threading



class lime(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "Not titled yet", catch_exceptions=True)
        Qt.QWidget.__init__(self)
        self.setWindowTitle("Not titled yet")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except BaseException as exc:
            print(f"Qt GUI: Could not set Icon: {str(exc)}", file=sys.stderr)
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("gnuradio/flowgraphs", "lime")

        try:
            geometry = self.settings.value("geometry")
            if geometry:
                self.restoreGeometry(geometry)
        except BaseException as exc:
            print(f"Qt GUI: Could not restore geometry: {str(exc)}", file=sys.stderr)
        self.flowgraph_started = threading.Event()

        ##################################################
        # Variables
        ##################################################
        self.zone = zone = 50000000
        self.tone_mag = tone_mag = 0.5
        self.sig_freq = sig_freq = 50
        self.samp_rate = samp_rate = 60000000
        self.rf_pwr = rf_pwr = 10
        self.rf_freq = rf_freq = 20000000
        self.noise_mag = noise_mag = 0
        self.mode = mode = 0
        self.frequency = frequency = 0

        ##################################################
        # Blocks
        ##################################################

        self._zone_range = qtgui.Range(0, 200000000, 1, 50000000, 200)
        self._zone_win = qtgui.RangeWidget(self._zone_range, self.set_zone, "Fir center", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._zone_win)
        self._tone_mag_range = qtgui.Range(0, 1, 0.0001, 0.5, 200)
        self._tone_mag_win = qtgui.RangeWidget(self._tone_mag_range, self.set_tone_mag, "Tone magnitude", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._tone_mag_win)
        self._sig_freq_range = qtgui.Range(-samp_rate/2, samp_rate/2, 1, 50, 200)
        self._sig_freq_win = qtgui.RangeWidget(self._sig_freq_range, self.set_sig_freq, "TX signal frequency offset", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._sig_freq_win)
        self._rf_pwr_range = qtgui.Range(-20, 60, 1, 10, 200)
        self._rf_pwr_win = qtgui.RangeWidget(self._rf_pwr_range, self.set_rf_pwr, "TX Power", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._rf_pwr_win)
        self._rf_freq_range = qtgui.Range(20000000, 1000000000, 100000, 20000000, 200)
        self._rf_freq_win = qtgui.RangeWidget(self._rf_freq_range, self.set_rf_freq, "TX LO frequency", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._rf_freq_win)
        self._noise_mag_range = qtgui.Range(0, 1, 0.001, 0, 200)
        self._noise_mag_win = qtgui.RangeWidget(self._noise_mag_range, self.set_noise_mag, "Noise magnitude", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._noise_mag_win)
        self._mode_range = qtgui.Range(0, 1, 1, 0, 200)
        self._mode_win = qtgui.RangeWidget(self._mode_range, self.set_mode, "SDR output mode", "counter_slider", int, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._mode_win)
        self._frequency_range = qtgui.Range(0, 200000000/16, 1, 0, 200)
        self._frequency_win = qtgui.RangeWidget(self._frequency_range, self.set_frequency, "LO Mixer frequency", "counter_slider", float, QtCore.Qt.Horizontal)
        self.top_layout.addWidget(self._frequency_win)
        self.soapy_limesdr_sink_0 = None
        dev = 'driver=lime'
        stream_args = ''
        tune_args = ['']
        settings = ['']

        self.soapy_limesdr_sink_0 = soapy.sink(dev, "fc32", 1, '',
                                  stream_args, tune_args, settings)
        self.soapy_limesdr_sink_0.set_sample_rate(0, samp_rate)
        self.soapy_limesdr_sink_0.set_bandwidth(0, 200000)
        self.soapy_limesdr_sink_0.set_frequency(0, rf_freq)
        self.soapy_limesdr_sink_0.set_frequency_correction(0, 0)
        self.soapy_limesdr_sink_0.set_gain(0, min(max(rf_pwr, -12.0), 64.0))
        self.qtgui_waterfall_sink_x_0_1_0 = qtgui.waterfall_sink_c(
            1024, #size
            window.WIN_BLACKMAN_hARRIS, #wintype
            0, #fc
            samp_rate, #bw
            "", #name
            1, #number of inputs
            None # parent
        )
        self.qtgui_waterfall_sink_x_0_1_0.set_update_time(0.10)
        self.qtgui_waterfall_sink_x_0_1_0.enable_grid(False)
        self.qtgui_waterfall_sink_x_0_1_0.enable_axis_labels(True)



        labels = ['', '', '', '', '',
                  '', '', '', '', '']
        colors = [0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
                  1.0, 1.0, 1.0, 1.0, 1.0]

        for i in range(1):
            if len(labels[i]) == 0:
                self.qtgui_waterfall_sink_x_0_1_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_waterfall_sink_x_0_1_0.set_line_label(i, labels[i])
            self.qtgui_waterfall_sink_x_0_1_0.set_color_map(i, colors[i])
            self.qtgui_waterfall_sink_x_0_1_0.set_line_alpha(i, alphas[i])

        self.qtgui_waterfall_sink_x_0_1_0.set_intensity_range(-140, 10)

        self._qtgui_waterfall_sink_x_0_1_0_win = sip.wrapinstance(self.qtgui_waterfall_sink_x_0_1_0.qwidget(), Qt.QWidget)

        self.top_layout.addWidget(self._qtgui_waterfall_sink_x_0_1_0_win)
        self.qtgui_waterfall_sink_x_0 = qtgui.waterfall_sink_c(
            1024, #size
            window.WIN_BLACKMAN_hARRIS, #wintype
            0, #fc
            samp_rate, #bw
            "", #name
            1, #number of inputs
            None # parent
        )
        self.qtgui_waterfall_sink_x_0.set_update_time(0.10)
        self.qtgui_waterfall_sink_x_0.enable_grid(False)
        self.qtgui_waterfall_sink_x_0.enable_axis_labels(True)



        labels = ['', '', '', '', '',
                  '', '', '', '', '']
        colors = [0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
                  1.0, 1.0, 1.0, 1.0, 1.0]

        for i in range(1):
            if len(labels[i]) == 0:
                self.qtgui_waterfall_sink_x_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_waterfall_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_waterfall_sink_x_0.set_color_map(i, colors[i])
            self.qtgui_waterfall_sink_x_0.set_line_alpha(i, alphas[i])

        self.qtgui_waterfall_sink_x_0.set_intensity_range(-140, 10)

        self._qtgui_waterfall_sink_x_0_win = sip.wrapinstance(self.qtgui_waterfall_sink_x_0.qwidget(), Qt.QWidget)

        self.top_layout.addWidget(self._qtgui_waterfall_sink_x_0_win)
        self.qtgui_freq_sink_x_0 = qtgui.freq_sink_c(
            1024, #size
            window.WIN_BLACKMAN_hARRIS, #wintype
            0, #fc
            samp_rate, #bw
            "", #name
            1,
            None # parent
        )
        self.qtgui_freq_sink_x_0.set_update_time(0.10)
        self.qtgui_freq_sink_x_0.set_y_axis((-140), 10)
        self.qtgui_freq_sink_x_0.set_y_label('Relative Gain', 'dB')
        self.qtgui_freq_sink_x_0.set_trigger_mode(qtgui.TRIG_MODE_FREE, 0.0, 0, "")
        self.qtgui_freq_sink_x_0.enable_autoscale(False)
        self.qtgui_freq_sink_x_0.enable_grid(False)
        self.qtgui_freq_sink_x_0.set_fft_average(1.0)
        self.qtgui_freq_sink_x_0.enable_axis_labels(True)
        self.qtgui_freq_sink_x_0.enable_control_panel(False)
        self.qtgui_freq_sink_x_0.set_fft_window_normalized(False)



        labels = ['', '', '', '', '',
            '', '', '', '', '']
        widths = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        colors = ["blue", "red", "green", "black", "cyan",
            "magenta", "yellow", "dark red", "dark green", "dark blue"]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0, 1.0]

        for i in range(1):
            if len(labels[i]) == 0:
                self.qtgui_freq_sink_x_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_freq_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_freq_sink_x_0.set_line_width(i, widths[i])
            self.qtgui_freq_sink_x_0.set_line_color(i, colors[i])
            self.qtgui_freq_sink_x_0.set_line_alpha(i, alphas[i])

        self._qtgui_freq_sink_x_0_win = sip.wrapinstance(self.qtgui_freq_sink_x_0.qwidget(), Qt.QWidget)
        self.top_layout.addWidget(self._qtgui_freq_sink_x_0_win)
        self.network_tcp_source_0 = network.tcp_source.tcp_source(itemsize=gr.sizeof_char*1,addr='127.0.0.1',port=2001,server=False)
        self.epy_block_0 = epy_block_0.ExampleBlock(mode=mode, frequency=frequency, zone=zone/12500000)
        self.blocks_stream_demux_0 = blocks.stream_demux(gr.sizeof_char*1, (1, 1))
        self.blocks_float_to_complex_0 = blocks.float_to_complex(1)
        self.blocks_char_to_float_0_0 = blocks.char_to_float(1, 1)
        self.blocks_char_to_float_0 = blocks.char_to_float(1, 1)
        self.blocks_add_xx_0_0 = blocks.add_vcc(1)
        self.blocks_add_xx_0 = blocks.add_vcc(1)
        self.analog_sig_source_x_0 = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, sig_freq, tone_mag, 0, 0)
        self.analog_fastnoise_source_x_0 = analog.fastnoise_source_c(analog.GR_GAUSSIAN, noise_mag, 0, 8192)
        self.analog_const_source_x_0 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, +1 +1j)


        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_const_source_x_0, 0), (self.blocks_add_xx_0_0, 0))
        self.connect((self.analog_fastnoise_source_x_0, 0), (self.blocks_add_xx_0, 0))
        self.connect((self.analog_sig_source_x_0, 0), (self.blocks_add_xx_0, 1))
        self.connect((self.blocks_add_xx_0, 0), (self.qtgui_waterfall_sink_x_0_1_0, 0))
        self.connect((self.blocks_add_xx_0, 0), (self.soapy_limesdr_sink_0, 0))
        self.connect((self.blocks_add_xx_0_0, 0), (self.epy_block_0, 0))
        self.connect((self.blocks_char_to_float_0, 0), (self.blocks_float_to_complex_0, 0))
        self.connect((self.blocks_char_to_float_0_0, 0), (self.blocks_float_to_complex_0, 1))
        self.connect((self.blocks_float_to_complex_0, 0), (self.blocks_add_xx_0_0, 1))
        self.connect((self.blocks_stream_demux_0, 0), (self.blocks_char_to_float_0, 0))
        self.connect((self.blocks_stream_demux_0, 1), (self.blocks_char_to_float_0_0, 0))
        self.connect((self.epy_block_0, 0), (self.qtgui_freq_sink_x_0, 0))
        self.connect((self.epy_block_0, 0), (self.qtgui_waterfall_sink_x_0, 0))
        self.connect((self.network_tcp_source_0, 0), (self.blocks_stream_demux_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("gnuradio/flowgraphs", "lime")
        self.settings.setValue("geometry", self.saveGeometry())
        self.stop()
        self.wait()

        event.accept()

    def get_zone(self):
        return self.zone

    def set_zone(self, zone):
        self.zone = zone
        self.epy_block_0.zone = self.zone/12500000

    def get_tone_mag(self):
        return self.tone_mag

    def set_tone_mag(self, tone_mag):
        self.tone_mag = tone_mag
        self.analog_sig_source_x_0.set_amplitude(self.tone_mag)

    def get_sig_freq(self):
        return self.sig_freq

    def set_sig_freq(self, sig_freq):
        self.sig_freq = sig_freq
        self.analog_sig_source_x_0.set_frequency(self.sig_freq)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.analog_sig_source_x_0.set_sampling_freq(self.samp_rate)
        self.qtgui_freq_sink_x_0.set_frequency_range(0, self.samp_rate)
        self.qtgui_waterfall_sink_x_0.set_frequency_range(0, self.samp_rate)
        self.qtgui_waterfall_sink_x_0_1_0.set_frequency_range(0, self.samp_rate)
        self.soapy_limesdr_sink_0.set_sample_rate(0, self.samp_rate)

    def get_rf_pwr(self):
        return self.rf_pwr

    def set_rf_pwr(self, rf_pwr):
        self.rf_pwr = rf_pwr
        self.soapy_limesdr_sink_0.set_gain(0, min(max(self.rf_pwr, -12.0), 64.0))

    def get_rf_freq(self):
        return self.rf_freq

    def set_rf_freq(self, rf_freq):
        self.rf_freq = rf_freq
        self.soapy_limesdr_sink_0.set_frequency(0, self.rf_freq)

    def get_noise_mag(self):
        return self.noise_mag

    def set_noise_mag(self, noise_mag):
        self.noise_mag = noise_mag
        self.analog_fastnoise_source_x_0.set_amplitude(self.noise_mag)

    def get_mode(self):
        return self.mode

    def set_mode(self, mode):
        self.mode = mode
        self.epy_block_0.mode = self.mode

    def get_frequency(self):
        return self.frequency

    def set_frequency(self, frequency):
        self.frequency = frequency
        self.epy_block_0.frequency = self.frequency




def main(top_block_cls=lime, options=None):

    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()

    tb.start()
    tb.flowgraph_started.set()

    tb.show()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    qapp.exec_()

if __name__ == '__main__':
    main()
