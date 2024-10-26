library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Delay is
    generic (
        DATA_WIDTH : integer := 2;
        DELAY_LENGTH : integer := 4
    );
    port (
        rst : in std_logic;
        clk : in std_logic;

        data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end Delay;

architecture Behavioral of Delay is
    signal buf : std_logic_vector((DATA_WIDTH * DELAY_LENGTH) - 1 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            buf <= (others => '0');
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            data_out <= buf(buf'left downto (buf'left - DATA_WIDTH) + 1);
            buf <= buf((buf'left - DATA_WIDTH) downto 0) & data_in;
        end if;
    end process;
end Behavioral;