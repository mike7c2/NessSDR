library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_pkg.all;
use work.hspi_pkg.all;

entity hspi_buffered_txrx is
    generic (
        WIDTH          : integer := 16;
        BURST_SIZE_POW : integer := 4;
        TX_FIFO_POW    : integer := 8;
        RX_FIFO_POW    : integer := 8
    );
    port (
        rst : in std_logic;

        bus_data_out : out std_logic_vector(WIDTH - 1 downto 0);
        bus_data_in : in std_logic_vector(WIDTH - 1 downto 0);

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
end hspi_buffered_txrx;

architecture Behavioral of hspi_buffered_txrx is
    signal tx_fifo_empty : std_logic;
    signal tx_fifo_not_empty : std_logic;
    signal hspi_tx_strobe : std_logic;
    signal hspi_tx_data : std_logic_vector(WIDTH - 1 downto 0);

    signal hspi_rx_strobe : std_logic;
    signal hspi_rx_data : std_logic_vector(WIDTH - 1 downto 0);

begin


    tx_fifo_not_empty <= not tx_fifo_empty;

    tx_fifo_inst : rw_clk_fifo
    generic map(
        DATA_WIDTH     => WIDTH,
        ADDR_WIDTH     => TX_FIFO_POW,
        XFER_DELAY_POW => 2
    )
    port map(
        rst => rst,

        wr_clk   => tx_data_clk,
        write_en => tx_data_strobe,
        data_in  => tx_data,
        full     => tx_data_full,

        rd_clk   => hrclk,
        read_en  => hspi_tx_strobe,
        data_out => hspi_tx_data,
        empty    => tx_fifo_empty
    );

    hspi_tx_inst : hspi_tx
    generic map(
        WIDTH          => WIDTH,
        BURST_SIZE_POW => BURST_SIZE_POW
    )
    port map(
        clk => hrclk,
        rst => rst,

        bus_data_out => bus_data_out,

        htclk => htclk,
        htreq => htreq,
        htrdy => htrdy,
        htvld => htvld,

        user_field => (others => '0'),
        tx_data        => hspi_tx_data,
        tx_data_valid  => tx_fifo_not_empty,
        tx_data_strobe => hspi_tx_strobe
    );

    rx_fifo_inst : rw_clk_fifo
    generic map(
        DATA_WIDTH     => WIDTH,
        ADDR_WIDTH     => RX_FIFO_POW,
        XFER_DELAY_POW => 2
    )
    port map(
        rst => rst,

        wr_clk   => hrclk,
        write_en => hspi_rx_strobe,
        data_in  => hspi_rx_data,
        full     => open,

        rd_clk   => rx_data_clk,
        read_en  => rx_data_strobe,
        data_out => rx_data,
        empty    => rx_data_empty

    );

    hspi_rx_inst : hspi_rx
    generic map(
        WIDTH          => WIDTH,
        BURST_SIZE_POW => BURST_SIZE_POW
    )
    port map(
        rst => rst,

        bus_data_in => bus_data_in,

        hrclk => hrclk,
        hract => hract,
        htack => htack,
        hrvld => hrvld,

        user_field      => open,
        sequence_number => open,
        crc_error       => open,
        rx_data         => hspi_rx_data,
        rx_data_strobe  => hspi_rx_strobe
    );
end Behavioral;