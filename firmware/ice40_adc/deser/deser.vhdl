library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Deser is
    generic (
        INPUT_WIDTH : integer := 2;
        OUTPUT_WIDTH : integer := 16
    );
    port (
        rst : in std_logic;
        clk : in std_logic;

        data_in_strobe : in std_logic;
        data_in : in std_logic_vector(INPUT_WIDTH-1 downto 0);

        data_out : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
    );
end entity;

architecture Behavioral of Deser is
    signal buf : std_logic_vector(OUTPUT_WIDTH-1 downto 0);
begin
    data_out <= buf;

    process(clk, rst)
    begin
        if rst = '1' then
            buf <= (others => '0');
        elsif rising_edge(clk) then
            if data_in_strobe = '1' then
                buf <= buf((OUTPUT_WIDTH-INPUT_WIDTH) - 1 downto 0) & data_in;
            end if;
        end if;
    end process;

end Behavioral;