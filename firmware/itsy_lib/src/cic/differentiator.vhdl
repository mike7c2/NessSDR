library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity differentiator is
    generic (
        WIDTH : integer := 32;
        DELAY : integer := 5
    );
    port (
        clk        : in std_logic;
        rst        : in std_logic;
        en         : in std_logic;
        input_sig  : in signed(WIDTH - 1 downto 0);
        output_sig : out signed(WIDTH - 1 downto 0)
    );
end differentiator;

architecture Behavioral of differentiator is
    signal delayed_input : signed((WIDTH * DELAY) - 1 downto 0);
begin
    process (clk, rst)
    begin
        if rst = '1' then
            delayed_input <= (others => '0');
            output_sig <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                delayed_input <= delayed_input(delayed_input'left downto WIDTH) & input_sig;
                output_sig <= input_sig - delayed_input(delayed_input'left downto delayed_input'left - (WIDTH - 1));
            end if;
        end if;
    end process;
end Behavioral;