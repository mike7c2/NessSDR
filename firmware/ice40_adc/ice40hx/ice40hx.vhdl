-- ExamplePackage.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package Ice40HX is

    component SB_PLL40_CORE
    generic (
        FEEDBACK_PATH                : string := "SIMPLE";
        PLLOUT_SELECT                : string := "GENCLK";
        DIVR                         : std_logic_vector(3 downto 0) := "0000";
        DIVF                         : std_logic_vector(6 downto 0) := "0111111";
        DIVQ                         : std_logic_vector(2 downto 0) := "101";
        FILTER_RANGE                 : std_logic_vector(2 downto 0) := "001"
    );
    port (
        REFERENCECLK : in std_logic;
        PLLOUTGLOBAL : out std_logic;
        RESETB       : in std_logic;
        BYPASS       : in std_logic;
        LOCK         : out std_logic
    );
    end component;

    component SB_IO
    generic (
        PIN_TYPE : std_logic_vector(5 downto 0) := (others => '0');
        PULLUP   : std_logic := '0';
        NEG_TRIGGER : std_logic := '0'; 
        IO_STANDARD : string := "SB_LVCMOS"
    );
    port (
        PACKAGE_PIN : inout std_logic;
        INPUT_CLK : in std_logic;
        OUTPUT_CLK : in std_logic;
        OUTPUT_ENABLE : in std_logic;
        D_OUT_0 : in std_logic;
        D_OUT_1 : in std_logic;
        D_IN_0 : out std_logic;
        D_IN_1 : out std_logic
    );
    end component;

end package Ice40HX;
