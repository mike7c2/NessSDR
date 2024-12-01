library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package multiplier_pkg is
    component pipelined_multiplier is
        generic (
            N_STAGES        : integer := 4;
            DATA_WIDTH_IN_A : integer := 16;
            DATA_WIDTH_IN_B : integer := 16
        );
        port (
            clk       : in std_logic;
            rst       : in std_logic;
            data_in_a : in std_logic_vector(DATA_WIDTH_IN_A - 1 downto 0);
            data_in_b : in std_logic_vector(DATA_WIDTH_IN_B - 1 downto 0);
            data_out  : out std_logic_vector(DATA_WIDTH_IN_A + DATA_WIDTH_IN_B - 1 downto 0)
        );
    end component;

end multiplier_pkg;