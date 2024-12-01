library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram is
    generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 8
    );
    port (
        rst : in std_logic;

        wr_clk  : in std_logic;
        wr_en   : in std_logic;
        wr_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        wr_data : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        rd_clk  : in std_logic;
        rd_en   : in std_logic;
        rd_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        rd_data : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end bram;

architecture Behavioral of bram is
    type ram_type is array (0 to 2 ** ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram : ram_type;
begin
    process (wr_clk, rst)
    begin
        if rst = '1' then
        elsif rising_edge(wr_clk) then
            if wr_en = '1' then
                ram(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;

    process (rd_clk, rst)
    begin
        if rst = '1' then
            rd_data <= (others => '0');
        elsif rising_edge(rd_clk) then
            if rd_en = '1' then
                rd_data <= ram(to_integer(unsigned(rd_addr)));
            end if;
        end if;
    end process;

end Behavioral;