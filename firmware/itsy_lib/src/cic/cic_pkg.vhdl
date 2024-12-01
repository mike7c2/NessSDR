library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cic_pkg is
    component cic is
        generic (
            N     : integer := 3;
            R     : integer := 8;
            D     : integer := 1;
            WIDTH : integer := 32
        );
        port (
            clk           : in std_logic;
            rst           : in std_logic;
            en            : in std_logic;
            input_sig     : in std_logic_vector(WIDTH - 1 downto 0);
            output_strobe : out std_logic;
            output_sig    : out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component;

    component differentiator is
        generic (
            WIDTH : integer := 32;
            DELAY : integer := 5
        );
        port (
            clk        : in std_logic;
            rst        : in std_logic;
            en         : in std_logic;
            input_sig  : in signed(WIDTH - 1 downto 0);
            output_sig : out signed(WIDTH - 1 downto 0)
        );
    end component;

    component integrator is
        generic (
            WIDTH : integer := 32
        );
        port (
            clk        : in std_logic;
            rst        : in std_logic;
            en         : in std_logic;
            input_sig  : in signed(WIDTH - 1 downto 0);
            output_sig : out signed(WIDTH - 1 downto 0)
        );
    end component;
end cic_pkg;