library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is
    generic (
        WORD_WIDTH   : integer := 8;
        MOSI_WIDTH   : integer := 1;
        MISO_WIDTH   : integer := 1;
        BUFFER_DEPTH : integer := 1
    );
    port (
        clk : in std_logic; -- System clock
        rst : in std_logic; -- Reset signal (active high)

        sclk : in std_logic;  -- SPI clock
        mosi : in std_logic;  -- Master Out Slave In
        miso : out std_logic; -- Master In Slave Out
        cs   : in std_logic;  -- Chip select (active low)

        data_in            : in std_logic_vector(WORD_WIDTH - 1 downto 0);  -- Data to send
        data_out           : out std_logic_vector(WORD_WIDTH - 1 downto 0); -- Received data
        data_in_strobe     : out std_logic;
        data_out_strobe    : out std_logic;
        transaction_active : out std_logic
    );
end entity spi_slave;

architecture behavioral of spi_slave is
    signal bit_counter : integer range 0 to WORD_WIDTH := 0;
    signal shift_register : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal spi_clk_edge : std_logic;
    signal transaction_active_int : std_logic;

    signal sclk_buf : std_logic_vector(BUFFER_DEPTH downto 0);
    signal sclk_rising : std_logic;
    signal sclk_falling : std_logic;
    signal mosi_buf : std_logic_vector(BUFFER_DEPTH downto 0);
    signal cs_buf : std_logic_vector(BUFFER_DEPTH downto 0);
begin
    sclk_buf(0) <= sclk;
    mosi_buf(0) <= mosi;
    cs_buf(0) <= cs;

    process (clk, rst)
    begin
        if rst = '1' then
            sclk_buf(BUFFER_DEPTH downto 1) <= (others => '0');
            mosi_buf(BUFFER_DEPTH downto 1) <= (others => '0');
            cs_buf(BUFFER_DEPTH downto 1) <= (others => '0');
            sclk_rising <= '0';
            sclk_falling <= '0';
        elsif rising_edge(clk) then
            sclk_buf(BUFFER_DEPTH downto 1) <= sclk_buf(sclk_buf'left - 1 downto 0);
            mosi_buf(BUFFER_DEPTH downto 1) <= mosi_buf(mosi_buf'left - 1 downto 0);
            cs_buf(BUFFER_DEPTH downto 1) <= cs_buf(cs_buf'left - 1 downto 0);
            if sclk_buf(sclk_buf'left) = '0' and sclk_buf(sclk_buf'left - 1) = '1' then
                sclk_rising <= '1';
                sclk_falling <= '0';
            elsif sclk_buf(sclk_buf'left) = '1' and sclk_buf(sclk_buf'left - 1) = '0' then
                sclk_rising <= '0';
                sclk_falling <= '1';
            else
                sclk_rising <= '0';
                sclk_falling <= '0';
            end if;
        end if;
    end process;

    transaction_active <= transaction_active_int;
    process (clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
            miso <= '0';
            transaction_active_int <= '0';
            bit_counter <= 0;
            data_in_strobe <= '0';
            data_out_strobe <= '0';
        elsif rising_edge(clk) then
            data_in_strobe <= '0';
            data_out_strobe <= '0';

            if cs_buf(cs_buf'left) = '0' then
                transaction_active_int <= '1';
            else
                transaction_active_int <= '0';
            end if;

            if transaction_active_int = '0' and cs_buf(cs_buf'left) = '0' then
                bit_counter <= 0;
                shift_register <= data_in;
                miso <= data_in(data_in'left);
            end if;

            if transaction_active_int = '1' then
                if sclk_rising = '1' then
                    bit_counter <= bit_counter + 1;
                    shift_register <= shift_register(shift_register'left - 1 downto 0) & mosi_buf(mosi_buf'left);

                    if bit_counter = WORD_WIDTH - 1 then
                        data_in_strobe <= '1';
                        data_out <= shift_register(shift_register'left - 1 downto 0) & mosi_buf(mosi_buf'left);
                        data_out_strobe <= '1';
                        bit_counter <= 0;
                    end if;
                end if;

                if sclk_falling = '1' then
                    if bit_counter = 0 then
                        shift_register <= data_in;
                        miso <= data_in(data_in'left);
                    else
                        miso <= shift_register(shift_register'left);
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture behavioral;