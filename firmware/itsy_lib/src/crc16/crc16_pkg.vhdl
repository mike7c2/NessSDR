library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package crc16_pkg is
    component crc16 is
        generic (
            WIDTH : integer := 16
        );
        port (
            clk     : in std_logic;
            rst     : in std_logic;
            clear   : in std_logic;
            data_in : in std_logic_vector(15 downto 0);
            valid   : in std_logic;
            crc_out : out std_logic_vector(15 downto 0)
        );
    end component;
end crc16_pkg;