LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE DelayPkg IS
    component Delay is
        generic (
            DATA_WIDTH : integer := 2;
            DELAY_LENGTH : integer := 2
        );
        port (
            rst : in std_logic;
            clk : in std_logic;

            data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
            data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
END DelayPkg;