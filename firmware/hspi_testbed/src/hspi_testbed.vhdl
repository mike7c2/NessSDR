library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ice40hx.all;
use work.utilities.all;
use work.hspi_pkg.all;
use work.fifo_pkg.all;

entity hspi_testbed is
    port (
        clk_12mhz : in std_logic;

        leds : out std_logic_vector(7 downto 0);
        dbg  : out std_logic_vector(7 downto 0);

        hspi_htclk : out std_logic;
        hspi_htreq : out std_logic;
        hspi_htrdy : in std_logic;
        hspi_htvld : out std_logic;

        hspi_hrclk : in std_logic;
        hspi_hract : in std_logic;
        hspi_htack : out std_logic;
        hspi_hrvld : in std_logic;

        hspi_data : inout std_logic_vector(15 downto 0)
    );
end hspi_testbed;

architecture top_level of hspi_testbed is
    signal clk : std_logic;
    signal clk_lock_if : std_logic;
    signal rst : std_logic;

    signal hspi_rx_data : std_logic_vector(15 downto 0);
    signal hspi_rx_empty : std_logic;
    signal hspi_rx_data_strobe : std_logic;


    signal hspi_tx_data : std_logic_vector(15 downto 0);
    signal hspi_tx_full : std_logic;
    signal hspi_tx_data_strobe : std_logic;

    signal hspi_loopback_strobe : std_logic;
begin
    -- 12MHz to 80MHz
    pll_inst_if : SB_PLL40_CORE
    generic map(
        FEEDBACK_PATH => "SIMPLE",
        -- 100Mhz
        --DIVR => "0000",
        --DIVF => "1000010",
        --DIVQ => "011",
        -- 80Mhz
        DIVR => "0000",
        DIVF => "0110100",
        DIVQ => "011",
        -- 50Mhz
        --DIVR => "0000",
        --DIVF => "1000010",
        --DIVQ => "100",
        FILTER_RANGE => "001"
    )
    port map(
        REFERENCECLK => clk_12mhz,
        RESETB       => '1',
        PLLOUTGLOBAL => clk,
        BYPASS       => '0',
        LOCK         => clk_lock_if
    );
    rst <= not clk_lock_if;

    hspi_tx_data <= hspi_rx_data;
    hspi_loopback_strobe <= not hspi_rx_empty and not hspi_tx_full;
    hspi_rx_data_strobe <= hspi_loopback_strobe;
    hspi_tx_data_strobe <= hspi_loopback_strobe;

    hspi_inst : hspi_buffered_txrx
    generic map(
        WIDTH          => 16,
        BURST_SIZE_POW => 8,
        TX_FIFO_POW    => 10,
        RX_FIFO_POW    => 10
    )
    port map(
        rst => rst,

        bus_data => hspi_data,

        htclk => hspi_htclk,
        htreq => hspi_htreq,
        htrdy => hspi_htrdy,
        htvld => hspi_htvld,

        hrclk => hspi_hrclk,
        hract => hspi_hract,
        htack => hspi_htack,
        hrvld => hspi_hrvld,

        rx_data_clk    => clk,
        rx_data        => hspi_rx_data,
        rx_data_empty  => hspi_rx_empty,
        rx_data_strobe => hspi_rx_data_strobe,

        tx_data_clk    => clk,
        tx_data        => hspi_tx_data,
        tx_data_strobe => hspi_tx_data_strobe,
        tx_data_full   => hspi_tx_full
    );

    leds <= (others => '0');
    dbg <= (others => '0');

end top_level;