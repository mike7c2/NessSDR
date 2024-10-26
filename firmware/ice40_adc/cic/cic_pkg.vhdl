LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE CicPkg IS
    component CIC is
        generic (
            N : integer := 3;  -- Number of stages for both integrator and differentiator
            R : integer := 8;
            D : integer := 1;
            WIDTH : integer := 32 -- Bit width for both integrator and differentiator stages
        );
        port (
            clk       : in std_logic;
            rst     : in std_logic;
            en        : in std_logic;
            input_sig : in std_logic_vector(WIDTH-1 downto 0);
            output_strobe : out std_logic;
            output_sig : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    component differentiator is
        generic (
            WIDTH : integer := 32;
            DELAY : integer := 5
        );
        port (
            clk      : in std_logic;
            rst    : in std_logic;
            en       : in std_logic;
            input_sig : in signed(WIDTH-1 downto 0);
            output_sig : out signed(WIDTH-1 downto 0)
        );
    end component;

    component integrator is
        generic (
            WIDTH : integer := 32
        );
        port (
            clk      : in std_logic; 
            rst    : in std_logic;
            en       : in std_logic;
            input_sig : in signed(WIDTH-1 downto 0);
            output_sig : out signed(WIDTH-1 downto 0)
        );
    end component;
END CicPkg;