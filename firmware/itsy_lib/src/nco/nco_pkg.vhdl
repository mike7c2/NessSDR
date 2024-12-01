library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package nco_pkg is

    component nco is
        generic (
            LUT_WIDTH : integer := 16;
            LUT_DEPTH : integer := 2
        );
        port (
            clk : in std_logic;
            rst : in std_logic;

            phase     : in std_logic_vector(LUT_DEPTH + 1 downto 0);
            di_strobe : in std_logic;

            data_out     : out std_logic_vector(LUT_WIDTH downto 0);
            out_i_strobe : out std_logic;
            out_q_strobe : out std_logic;

            lut_wr_clk  : in std_logic;
            lut_wr_en   : in std_logic;
            lut_wr_addr : in std_logic_vector(LUT_DEPTH - 1 downto 0);
            lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
        );
    end component;

end nco_pkg;