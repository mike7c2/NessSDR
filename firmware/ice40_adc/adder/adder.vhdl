library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Adder is
    generic (
        DATA_WIDTH_IN_A : integer := 16;
        DATA_WIDTH_IN_B : integer := 16;
        DATA_WIDTH_OUT : integer := 16
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        data_in_a : in std_logic_vector(DATA_WIDTH_IN_A-1 downto 0);
        data_in_b : in std_logic_vector(DATA_WIDTH_IN_B-1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH_OUT-1 downto 0)
    );
end Adder;

architecture Behavioral of Adder is

begin
    process(clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            data_out <= std_logic_vector(unsigned(data_in_a) + unsigned(data_in_b));
        end if;
    end process;
end Behavioral;