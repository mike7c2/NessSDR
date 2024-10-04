LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE AdcPkg IS
    component ADC is
        generic (
            DATA_WIDTH : integer := 8;
            SYNC_DELAY : integer := 1
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            di  : in std_logic_vector(1 downto 0);
            do  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            do_strobe  : out std_logic
        );
    end component;

END AdcPkg;