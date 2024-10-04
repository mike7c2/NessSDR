LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE DeserPkg IS
    component Deser is
        generic (
            INPUT_WIDTH : integer := 2;
            OUTPUT_WIDTH : integer := 16
        );
        port (
            rst : in std_logic;
            clk : in std_logic;

            data_in_strobe : in std_logic;
            data_in : in std_logic_vector(INPUT_WIDTH-1 downto 0);

            data_out : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
        );
    end component;
END DeserPkg;