LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE RebufferPkg IS
    component Rebuffer is
        generic (
            INPUT_WIDTH : integer := 2;
            OUTPUT_WIDTH : integer := 16
        );
        port (
            rst : in std_logic;
            in_clk : in std_logic;
            out_clk : in std_logic;

            data_in_strobe : in std_logic;
            data_in : in std_logic_vector(INPUT_WIDTH-1 downto 0);

            data_out_strobe : out std_logic;
            data_out : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
        );
    end component;
END RebufferPkg;