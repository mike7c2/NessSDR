library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lut_fir_pkg is

    component lut_fir is
        generic (
            LUTS_POW          : integer := 3;
            LUT_WIDTH         : integer := 16;
            LUT_DEPTH         : integer := 8;
            DATA_OUTPUT_WIDTH : integer := 12
        );
        port (
            clk       : in std_logic;
            rst       : in std_logic;
            di_strobe : in std_logic;
            data_in   : in std_logic_vector(2 ** (LUTS_POW + 1) * LUT_DEPTH - 1 downto 0);

            data_out  : out std_logic_vector(DATA_OUTPUT_WIDTH - 1 downto 0);
            do_strobe : out std_logic;

            lut_wr_clk  : in std_logic;
            lut_wr_en   : in std_logic;
            lut_wr_addr : in std_logic_vector(LUT_DEPTH + LUTS_POW - 1 downto 0);
            lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
        );
    end component;

end lut_fir_pkg;