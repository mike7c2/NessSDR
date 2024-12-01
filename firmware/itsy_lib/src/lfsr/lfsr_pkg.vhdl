library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

PACKAGE lfsr_pkg IS
    component lfsr is
        generic (
            WIDTH : integer := 32;
            POLY : std_logic_vector := ""
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            data_out : out std_logic
        );
    end component;

    component comb_lfsr is
        generic (
            WIDTH : integer := 32;
            POLY : std_logic_vector := ""
        );
        port (
            current : in std_logic_vector(WIDTH - 1 downto 0);
            next_value : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component;

    type lfsr_polys_array_type is array (natural range <>) of std_logic_vector(31 downto 0); -- Maximum length 32 bits

    constant LFSR_MAXIMAL_LENGTH_POLY_LUT : lfsr_polys_array_type(2 to 32);
END lfsr_pkg;


package body lfsr_pkg is
    -- Initialize the LUT in the package body
    constant LFSR_MAXIMAL_LENGTH_POLY_LUT : lfsr_polys_array_type(2 to 32) := (
        "11000000000000000000000000000000",
        "11000000000000000000000000000000",
        "11000000000000000000000000000000",
        "10100000000000000000000000000000",
        "11000000000000000000000000000000",
        "11000000000000000000000000000000",
        "10111000000000000000000000000000",
        "10001000000000000000000000000000",
        "10010000000000000000000000000000",
        "10100000000000000000000000000000",
        "11001010000000000000000000000000",
        "11011000000000000000000000000000",
        "11010100000000000000000000000000",
        "11000000000000000000000000000000",
        "10110100000000000000000000000000",
        "10010000000000000000000000000000",
        "10000001000000000000000000000000",
        "11100100000000000000000000000000",
        "10010000000000000000000000000000",
        "10100000000000000000000000000000",
        "11000000000000000000000000000000",
        "10000100000000000000000000000000",
        "11011000000000000000000000000000",
        "10010000000000000000000000000000",
        "11100010000000000000000000000000",
        "11100100000000000000000000000000",
        "10010000000000000000000000000000",
        "10100000000000000000000000000000",
        "11001010000000000000000000000000",
        "10010000000000000000000000000000",
        "11010001100000000000000000000000"
    );
end lfsr_pkg;
