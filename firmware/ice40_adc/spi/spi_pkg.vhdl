LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE SpiPkg IS
    component spi_slave is
        generic (
            WORD_WIDTH : integer := 8;
            MOSI_WIDTH : integer := 1;
            MISO_WIDTH : integer := 1;
            BUFFER_DEPTH : integer := 1
        );
        port (
            clk        : in  std_logic;      -- System clock
            rst        : in  std_logic;      -- Reset signal (active high)
    
            sclk       : in  std_logic;      -- SPI clock
            mosi       : in  std_logic;      -- Master Out Slave In
            miso       : out std_logic;      -- Master In Slave Out
            cs         : in  std_logic;      -- Chip select (active low)
    
            data_in    : in  std_logic_vector(WORD_WIDTH-1 downto 0); -- Data to send
            data_out   : out std_logic_vector(WORD_WIDTH-1 downto 0); -- Received data
            data_in_strobe : out std_logic;
            data_out_strobe : out std_logic;
            transaction_active : out std_logic
        );
    end component;
END SpiPkg;