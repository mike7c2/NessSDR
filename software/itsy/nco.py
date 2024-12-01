import numpy as np


class NCO:
    def __init__(self, lut_width, word_width):

        self.lut_width = lut_width
        self.word_width = word_width

        points = 2**lut_width
        extent = np.pi/2

        sample_points = np.linspace(
            ((1/(points*2)) * extent), extent - ((1/(points*2)) * extent), points)
        sin_points = np.sin(sample_points)

        self.lut = sin_points * ((2**(word_width-1))-1)

    def lookup(self, phase):
        phase &= (2**(self.lut_width+2) - 1)
        quadrant = phase >> self.lut_width
        phase &= (2**(self.lut_width) - 1)
        if quadrant == 0:
            return self.lut[phase]
        elif quadrant == 1:
            return self.lut[((2**self.lut_width)-1) - phase]
        elif quadrant == 2:
            return -self.lut[phase]
        else:
            return -self.lut[((2**self.lut_width)-1) - phase]

    def get_lut_data(self):
        return self.lut
