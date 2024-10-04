LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE MultiplierPkg IS
    component pipelined_multiplier is
        generic (
            N_STAGES : integer := 4;
            DATA_WIDTH_IN_A : integer := 16;
            DATA_WIDTH_IN_B : integer := 16
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            data_in_a : in std_logic_vector(DATA_WIDTH_IN_A-1 downto 0);
            data_in_b : in std_logic_vector(DATA_WIDTH_IN_B-1 downto 0);
            data_out : out std_logic_vector(DATA_WIDTH_IN_A + DATA_WIDTH_IN_B - 1 downto 0)
        );
    end component;

END MultiplierPkg;