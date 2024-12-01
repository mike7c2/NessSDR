library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package delay_pkg is
    component delay is
        generic (
            DATA_WIDTH   : integer := 2;
            DELAY_LENGTH : integer := 2
        );
        port (
            rst : in std_logic;
            clk : in std_logic;

            data_in  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;
end delay_pkg;