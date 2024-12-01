library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_pkg.all;
use work.fifo_pkg.all;
use work.pipeline_controller_pkg.all;

entity pipeline_controller is
    generic (
        FIFO_DEPTH : integer := 10
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        spi_clk  : in std_logic;
        spi_mosi : in std_logic;
        spi_miso : out std_logic;
        spi_cs   : in std_logic;

        pipeline_data_in_strobe : std_logic;
        pipeline_data_in        : std_logic_vector(15 downto 0);

        pipeline_wr_en   : out std_logic;
        pipeline_wr_addr : out std_logic_vector(15 downto 0);
        pipeline_wr_data : out std_logic_vector(15 downto 0);

        streaming_active : out std_logic
    );

end pipeline_controller;

architecture Behavioral of pipeline_controller is
    type ctrl_state_t is (idle, waiting_cmd, receive_addr, receive_data, streaming_read);
    signal ctrl_state : ctrl_state_t := idle;

    signal internal_wr_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal internal_wr_data : std_logic_vector(15 downto 0) := (others => '0');

    signal read_stream_active : std_logic;

    signal spi_data_in : std_logic_vector(15 downto 0);
    signal spi_data_out : std_logic_vector(15 downto 0);
    signal spi_data_in_strobe : std_logic;
    signal spi_data_out_strobe : std_logic;
    signal spi_transaction_active : std_logic;

    signal pipeline_data_in_buf : std_logic_vector(15 downto 0);
    signal pipeline_data_in_strobe_buf : std_logic;

    signal fifo_rd_rst : std_logic;
    signal fifo_rd_en : std_logic;
    signal fifo_rd_data : std_logic_vector(15 downto 0);
    signal fifo_clear : std_logic;

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

    spi_inst : spi_slave
    generic map(
        WORD_WIDTH   => 16,
        MOSI_WIDTH   => 1,
        MISO_WIDTH   => 1,
        BUFFER_DEPTH => 2
    )
    port map(
        clk => clk,
        rst => rst,

        sclk => spi_clk,
        mosi => spi_mosi,
        miso => spi_miso,
        cs   => spi_cs,

        data_in            => spi_data_in,
        data_out           => spi_data_out,
        data_in_strobe     => spi_data_in_strobe,
        data_out_strobe    => spi_data_out_strobe,
        transaction_active => spi_transaction_active
    );

    fifo_inst : Fifo
    generic map(
        DATA_WIDTH => 16,
        ADDR_WIDTH => FIFO_DEPTH
    )
    port map(
        clk      => clk,
        rst      => rst,
        clear    => fifo_clear,
        write_en => pipeline_data_in_strobe_buf,
        read_en  => fifo_rd_en,
        data_in  => pipeline_data_in_buf,
        data_out => fifo_rd_data,
        empty    => open,
        full     => open
    );

    process (clk, rst)
    begin
        if rst = '1' then
            ctrl_state <= idle;

            pipeline_wr_addr <= (others => '0');
            pipeline_wr_data <= (others => '0');
            pipeline_wr_en <= '0';

            fifo_rd_en <= '0';
            fifo_clear <= '0';

            spi_data_in <= (others => '0');

            read_stream_active <= '0';

        elsif rising_edge(clk) then
            pipeline_wr_en <= '0';
            fifo_rd_en <= '0';
            fifo_clear <= '0';

            if spi_transaction_active = '0' then
                ctrl_state <= idle;
            else
                if spi_data_in_strobe = '1' and read_stream_active = '1' then
                    fifo_rd_en <= '1';
                    spi_data_in <= fifo_rd_data;
                end if;

                case ctrl_state is
                    when idle =>
                        ctrl_state <= waiting_cmd;

                    when waiting_cmd =>
                        if spi_data_out_strobe = '1' then
                            case spi_data_out is
                                when "0000000000000001" =>
                                    ctrl_state <= receive_addr;
                                when "0000000000000011" =>
                                    read_stream_active <= '1';
                                    ctrl_state <= idle;
                                when "0000000000000100" =>
                                    read_stream_active <= '0';
                                    ctrl_state <= idle;
                                when "0000000000000101" =>
                                    fifo_clear <= '1';
                                    ctrl_state <= idle;
                                when others =>
                                    ctrl_state <= idle;
                            end case;
                        end if;

                    when receive_addr =>
                        if spi_data_out_strobe = '1' then
                            pipeline_wr_addr <= spi_data_out;
                            ctrl_state <= receive_data;
                        end if;

                    when receive_data =>
                        if spi_data_out_strobe = '1' then
                            pipeline_wr_data <= spi_data_out;
                            pipeline_wr_en <= '1';
                            ctrl_state <= idle;
                        end if;
                    when others =>
                        ctrl_state <= idle;
                end case;
            end if;
        end if;
    end process;

end Behavioral;