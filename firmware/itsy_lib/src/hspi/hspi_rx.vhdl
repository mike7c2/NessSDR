library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.crc16_pkg.all;

entity hspi_rx is
    generic (
        WIDTH          : integer := 16;
        BURST_SIZE_POW : integer := 4
    );
    port (
        hrclk : in std_logic;
        rst   : in std_logic;

        bus_data_in : in std_logic_vector(WIDTH - 1 downto 0);

        hract : in std_logic;
        htack : out std_logic;
        hrvld : in std_logic;

        user_field      : out std_logic_vector(25 downto 0);
        sequence_number : out std_logic_vector(3 downto 0);
        crc_error       : out std_logic;
        rx_data         : out std_logic_vector(WIDTH - 1 downto 0);
        rx_data_strobe  : out std_logic
    );
end hspi_rx;

architecture Behavioral of hspi_rx is
    constant max_cnt : std_logic_vector(BURST_SIZE_POW - 1 downto 0) := (others => '1');

    type state_type is (idle, pending_request, header_1, header_2, data, crc);
    signal current_state : state_type;

    signal header : std_logic_vector(31 downto 0);

    signal crc_out : std_logic_vector(15 downto 0);
    signal crc_clr : std_logic;

    signal rx_cnt : std_logic_vector(BURST_SIZE_POW - 1 downto 0);
begin
    sequence_number <= header(27 downto 24);
    crc_16_inst : crc16
    generic map(
        WIDTH => 16
    )
    port map(
        clk     => hrclk,
        rst     => rst,
        clear   => crc_clr,
        data_in => bus_data_in,
        valid   => hrvld,
        crc_out => crc_out
    );

    process (hrclk, rst)
    begin
        if rst = '1' then
            crc_clr <= '0';
            htack <= '0';
            crc_error <= '0';
            current_state <= idle;
            rx_data_strobe <= '0';
            rx_data <= (others => '0');
            rx_cnt <= (others => '0');

        elsif rising_edge(hrclk) then
            crc_clr <= '0';
            htack <= '0';
            crc_error <= '0';
            rx_data_strobe <= '0';
            rx_data <= (others => '0');

            case current_state is

                when idle =>
                    crc_clr <= '1';
                    if hract = '1' then
                        current_state <= pending_request;
                    else
                        current_state <= idle;
                    end if;

                when pending_request =>
                    htack <= '1';
                    current_state <= header_1;

                when header_1 =>
                    htack <= '1';

                    if hrvld = '1' then
                        header(31 downto 16) <= bus_data_in;
                        current_state <= header_2;
                    else
                        current_state <= header_1;
                    end if;

                when header_2 =>
                    htack <= '1';

                    if hrvld = '1' then
                        header(15 downto 0) <= bus_data_in;
                        current_state <= data;
                    else
                        current_state <= header_1;
                    end if;

                when data =>
                    htack <= '1';

                    if hrvld = '1' then
                        rx_data_strobe <= '1';
                        rx_data <= bus_data_in;
                        rx_cnt <= std_logic_vector(unsigned(rx_cnt) + 1);

                        if rx_cnt = max_cnt then
                            current_state <= crc;
                        else
                            current_state <= data;
                        end if;
                    else
                        current_state <= data;
                    end if;

                when crc =>
                    htack <= '1';

                    if hrvld = '1' then
                        if bus_data_in /= crc_out then
                            crc_error <= '1';
                        end if;
                        current_state <= idle;
                    else
                        current_state <= crc;
                    end if;

                when others =>
                    current_state <= idle;

            end case;
        end if;

    end process;

end Behavioral;