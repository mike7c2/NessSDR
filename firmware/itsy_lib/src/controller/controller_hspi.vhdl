library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hspi_pkg.all;
use work.pipeline_controller_pkg.all;

entity pipeline_hspi_controller is
    port (
        clk : in std_logic;
        rst : in std_logic;

        bus_data : inout std_logic_vector(15 downto 0);

        htclk : out std_logic;
        htreq : out std_logic;
        htrdy : in std_logic;
        htvld : out std_logic;

        hrclk : in std_logic;
        hract : in std_logic;
        htack : out std_logic;
        hrvld : in std_logic;

        pipeline_data_in_strobe : std_logic;
        pipeline_data_in        : std_logic_vector(15 downto 0);

        pipeline_wr_en   : out std_logic;
        pipeline_wr_addr : out std_logic_vector(15 downto 0);
        pipeline_wr_data : out std_logic_vector(15 downto 0);

        streaming_active : out std_logic
    );

end pipeline_hspi_controller;

architecture Behavioral of pipeline_hspi_controller is
    type ctrl_state_t is (idle, waiting_cmd, receive_addr, receive_data, streaming_read);
    signal ctrl_state : ctrl_state_t := idle;

    signal internal_wr_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal internal_wr_data : std_logic_vector(15 downto 0) := (others => '0');

    signal hspi_rx_data : std_logic_vector(15 downto 0);
    signal hspi_rx_empty : std_logic;
    signal hspi_rx_data_strobe : std_logic;

    signal hspi_data_out : std_logic_vector(15 downto 0);
    signal hspi_tx_data_strobe : std_logic;
    signal hspi_tx_full : std_logic;

    signal pipeline_data_in_buf : std_logic_vector(15 downto 0);
    signal pipeline_data_in_strobe_buf : std_logic;

    signal read_stream_active : std_logic;
begin
    streaming_active <= read_stream_active;

    process (clk, rst)
    begin
        if rst = '1' then
            pipeline_data_in_buf <= (others => '0');
            pipeline_data_in_strobe_buf <= '0';
        elsif rising_edge(clk) then
            pipeline_data_in_buf <= pipeline_data_in;
            pipeline_data_in_strobe_buf <= pipeline_data_in_strobe;
        end if;
    end process;

    hspi_inst : hspi_buffered_txrx
    generic map(
        WIDTH          => 16,
        BURST_SIZE_POW => 8,
        TX_FIFO_POW    => 8,
        RX_FIFO_POW    => 8
    )
    port map(
        rst => rst,

        bus_data => bus_data,

        htclk => htclk,
        htreq => htreq,
        htrdy => htrdy,
        htvld => htvld,

        hrclk => hrclk,
        hract => hract,
        htack => htack,
        hrvld => hrvld,

        rx_data_clk    => clk,
        rx_data        => hspi_rx_data,
        rx_data_empty  => hspi_rx_empty,
        rx_data_strobe => hspi_rx_data_strobe,

        tx_data_clk    => clk,
        tx_data        => pipeline_data_in,
        tx_data_strobe => pipeline_data_in_strobe_buf,
        tx_data_full   => hspi_tx_full
    );

    process (clk, rst)
    begin
        if rst = '1' then
            ctrl_state <= idle;

            pipeline_wr_addr <= (others => '0');
            pipeline_wr_data <= (others => '0');
            pipeline_wr_en <= '0';

            hspi_rx_data_strobe <= '0';
            read_stream_active <= '0';

        elsif rising_edge(clk) then
            pipeline_wr_en <= '0';
            hspi_rx_data_strobe <= '0';

            case ctrl_state is
                when idle =>
                    ctrl_state <= waiting_cmd;

                when waiting_cmd =>
                    if hspi_rx_empty = '0' then
                        hspi_rx_data_strobe <= '1';
                        case hspi_rx_data is
                            when "0000000000000001" =>
                                ctrl_state <= receive_addr;
                            when "0000000000000011" =>
                                read_stream_active <= '1';
                                ctrl_state <= waiting_cmd;
                            when "0000000000000100" =>
                                read_stream_active <= '0';
                                ctrl_state <= waiting_cmd;
                            when "0000000000000101" =>
                                ctrl_state <= waiting_cmd;
                            when others =>
                                ctrl_state <= waiting_cmd;
                        end case;
                    end if;

                when receive_addr =>
                    if hspi_rx_empty = '0' then
                        hspi_rx_data_strobe <= '1';
                        pipeline_wr_addr <= hspi_rx_data;
                        ctrl_state <= receive_data;
                    end if;
                when receive_data =>
                    if hspi_rx_empty = '0' then
                        hspi_rx_data_strobe <= '1';
                        pipeline_wr_data <= hspi_rx_data;
                        pipeline_wr_en <= '1';
                        ctrl_state <= waiting_cmd;
                    end if;
                when others =>
                    ctrl_state <= idle;
            end case;

        end if;
    end process;

end Behavioral;