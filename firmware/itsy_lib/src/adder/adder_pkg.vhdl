library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package adder_pkg is
    component adder is
        generic (
            DATA_WIDTH_IN_A : integer := 16;
            DATA_WIDTH_IN_B : integer := 16;
            DATA_WIDTH_OUT  : integer := 16
        );
        port (
            clk       : in std_logic;
            rst       : in std_logic;
            data_in_a : in std_logic_vector(DATA_WIDTH_IN_A - 1 downto 0);
            data_in_b : in std_logic_vector(DATA_WIDTH_IN_B - 1 downto 0);
            data_out  : in std_logic_vector(DATA_WIDTH_OUT - 1 downto 0)
        );
    end component;

    component pipelined_adder is
        generic (
            N_INPUTS      : integer := 8;
            N_INPUTS_POW  : integer := 3;
            DATA_WIDTH_IN : integer := 16
        );
        port (
            clk      : in std_logic;
            rst      : in std_logic;
            data_in  : in std_logic_vector(N_INPUTS * DATA_WIDTH_IN - 1 downto 0);
            data_out : out std_logic_vector(DATA_WIDTH_IN + N_INPUTS_POW - 1 downto 0)
        );
    end component;

end adder_pkg;