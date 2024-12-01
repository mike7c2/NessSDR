library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package hspi_pkg is

    component hspi_buffered_txrx is
        generic (
            WIDTH          : integer := 16;
            BURST_SIZE_POW : integer := 4;
            TX_FIFO_POW    : integer := 8;
            RX_FIFO_POW    : integer := 8
        );
        port (
            rst : in std_logic;

            bus_data : inout std_logic_vector(WIDTH - 1 downto 0);

            htclk : out std_logic;
            htreq : out std_logic;
            htrdy : in std_logic;
            htvld : out std_logic;

            hrclk : in std_logic;
            hract : in std_logic;
            htack : out std_logic;
            hrvld : in std_logic;

            rx_data_clk    : in std_logic;
            rx_data        : out std_logic_vector(WIDTH - 1 downto 0);
            rx_data_empty  : out std_logic;
            rx_data_strobe : in std_logic;

            tx_data_clk    : in std_logic;
            tx_data        : in std_logic_vector(WIDTH - 1 downto 0);
            tx_data_strobe : in std_logic;
            tx_data_full   : out std_logic
        );
    end component;

    component hspi_tx is
        generic (
            WIDTH          : integer := 16;
            BURST_SIZE_POW : integer := 8
        );
        port (
            clk : in std_logic;
            rst : in std_logic;

            bus_data_out : out std_logic_vector(WIDTH - 1 downto 0);

            htclk : out std_logic;
            htreq : out std_logic;
            htrdy : in std_logic;
            htvld : out std_logic;

            user_field     : in std_logic_vector(25 downto 0);
            tx_data        : in std_logic_vector(WIDTH - 1 downto 0);
            tx_data_valid  : in std_logic;
            tx_data_strobe : out std_logic
        );
    end component;

    component hspi_rx is
        generic (
            WIDTH          : integer := 16;
            BURST_SIZE_POW : integer := 4
        );
        port (
            rst : in std_logic;

            bus_data_in : in std_logic_vector(WIDTH - 1 downto 0);

            hrclk : in std_logic;
            hract : in std_logic;
            htack : out std_logic;
            hrvld : in std_logic;

            user_field      : out std_logic_vector(25 downto 0);
            sequence_number : out std_logic_vector(3 downto 0);
            crc_error       : out std_logic;
            rx_data         : out std_logic_vector(WIDTH - 1 downto 0);
            rx_data_strobe  : out std_logic
        );
    end component;
end hspi_pkg;