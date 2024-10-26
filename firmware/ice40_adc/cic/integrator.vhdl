library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integrator is
    generic (
        WIDTH : integer := 32
    );
    port (
        clk      : in std_logic; 
        rst    : in std_logic;
        en       : in std_logic;
        input_sig : in signed(WIDTH-1 downto 0);
        output_sig : out signed(WIDTH-1 downto 0)
    );
end integrator;

architecture Behavioral of integrator is
    signal accumulator : signed(WIDTH-1 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            accumulator <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                accumulator <= accumulator + input_sig;
            end if;
        end if;
    end process;
    output_sig <= accumulator;
    
end Behavioral;