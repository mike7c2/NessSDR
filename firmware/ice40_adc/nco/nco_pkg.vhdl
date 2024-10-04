LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE NCOPkg IS

    component NCO is
        generic (
            LUT_WIDTH : integer := 16;
            LUT_DEPTH : integer := 10
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
    
            phase : in std_logic_vector(LUT_DEPTH+1 downto 0);
            sample_en : in std_logic;
    
            i_out : out std_logic_vector(LUT_WIDTH downto 0);
            q_out : out std_logic_vector(LUT_WIDTH downto 0);
            out_strobe : out std_logic;
    
            lut_wr_clk : in std_logic;
            lut_wr_en : in std_logic;
            lut_wr_addr : in std_logic_vector(LUT_DEPTH - 1 downto 0);
            lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
        );
    end component;

END NCOPkg;