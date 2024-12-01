library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.crc16_pkg.all;

entity hspi_tx is
    generic (
        WIDTH          : integer := 16;
        BURST_SIZE_POW : integer := 4
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        bus_data_out : inout std_logic_vector(WIDTH - 1 downto 0);

        htclk : out std_logic;
        htreq : out std_logic;
        htrdy : in std_logic;
        htvld : out std_logic;

        user_field     : in std_logic_vector(25 downto 0);
        tx_data        : in std_logic_vector(WIDTH - 1 downto 0);
        tx_data_valid  : in std_logic;
        tx_data_strobe : out std_logic
    );
end hspi_tx;

architecture Behavioral of hspi_tx is
    constant max_cnt : std_logic_vector(BURST_SIZE_POW - 1 downto 0) := (others => '1');

    type state_type is (idle, requesting, header_1, header_2, data, crc);
    signal current_state : state_type;
    signal header : std_logic_vector(31 downto 0);

    signal tx_length : std_logic_vector(1 downto 0);
    signal sequence : std_logic_vector(3 downto 0);

    signal crc_out : std_logic_vector(15 downto 0);
    signal crc_clr : std_logic;

    signal tx_cnt : std_logic_vector(BURST_SIZE_POW - 1 downto 0);

    signal htvld_int : std_logic;
    signal bus_data_out_int : std_logic_vector(15 downto 0);
begin
    htclk <= clk;
    htvld <= htvld_int;
    bus_data_out <= bus_data_out_int;
    tx_length <= "00";

    header <= tx_length & sequence & user_field;

    crc_16_inst : crc16
    generic map(
        WIDTH => 16
    )
    port map(
        clk     => clk,
        rst     => rst,
        clear   => crc_clr,
        data_in => bus_data_out_int,
        valid   => htvld_int,
        crc_out => crc_out
    );

    process (clk, rst)
    begin
        if rst = '1' then
            htreq <= '0';
            htvld_int <= '0';
            crc_clr <= '0';
            bus_data_out_int <= (others => 'Z');
            tx_data_strobe <= '0';
            current_state <= idle;
            tx_cnt <= (others => '0');
            sequence <= (others => '0');
        elsif rising_edge(clk) then
            htreq <= '0';
            htvld_int <= '0';
            tx_data_strobe <= '0';
            crc_clr <= '0';
            bus_data_out_int <= (others => 'Z');

            case current_state is

                when idle =>
                    crc_clr <= '1';
                    if tx_data_valid = '1' then
                        current_state <= requesting;
                    else
                        current_state <= idle;
                    end if;

                when requesting =>
                    htreq <= '1';

                    if htrdy = '1' then
                        current_state <= header_1;
                    else
                        current_state <= requesting;
                    end if;

                when header_1 =>
                    htreq <= '1';
                    htvld_int <= '1';
                    tx_data_strobe <= '0';

                    bus_data_out_int <= header(31 downto 16);
                    current_state <= header_2;

                when header_2 =>
                    htreq <= '1';
                    htvld_int <= '1';
                    tx_data_strobe <= '0';

                    bus_data_out_int <= header(15 downto 0);
                    current_state <= data;

                when data =>
                    htreq <= '1';

                    if tx_data_valid = '1' then
                        htvld_int <= '1';
                        tx_data_strobe <= '1';
                        tx_cnt <= std_logic_vector(unsigned(tx_cnt) + 1);
                        bus_data_out_int <= tx_data;

                        if tx_cnt = max_cnt then
                            current_state <= crc;
                        else
                            current_state <= data;
                        end if;
                    else
                        current_state <= data;
                    end if;

                when crc =>
                    htreq <= '1';
                    htvld_int <= '1';

                    bus_data_out_int <= crc_out;
                    current_state <= idle;
                    sequence <= std_logic_vector(unsigned(sequence) + 1);

                when others =>
                    current_state <= idle;

            end case;
        end if;

    end process;

end Behavioral;