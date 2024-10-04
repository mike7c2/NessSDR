LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE BramPkg IS
    component BRAM is
        generic (
            DATA_WIDTH : integer := 16;
            ADDR_WIDTH : integer := 8
        );
        port (
            rst : in std_logic;
    
            wr_clk : in std_logic;
            wr_en : in std_logic;
            wr_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            wr_data : in std_logic_vector(DATA_WIDTH-1 downto 0);
            
            rd_clk : in std_logic;
            rd_en : in std_logic;
            rd_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            rd_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
END BramPkg;