library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rebuffer is
    generic (
        INPUT_WIDTH  : integer := 2;
        OUTPUT_WIDTH : integer := 16
    );
    port (
        rst     : in std_logic;
        in_clk  : in std_logic;
        out_clk : in std_logic;

        data_in_strobe : in std_logic;
        data_in        : in std_logic_vector(INPUT_WIDTH - 1 downto 0);

        data_out_strobe : out std_logic;
        data_out        : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
    );
end rebuffer;

architecture Behavioral of rebuffer is
    signal buf : std_logic_vector(OUTPUT_WIDTH - 1 downto 0);
    signal update_strobe : std_logic;
    signal last_update_strobe : std_logic;
begin

    process (in_clk, rst)
    begin
        if rst = '1' then
            buf <= (others => '0');
            update_strobe <= '0';
        elsif rising_edge(in_clk) then
            if data_in_strobe = '1' then
                update_strobe <= not update_strobe;
                buf <= buf((OUTPUT_WIDTH - INPUT_WIDTH) - 1 downto 0) & data_in;
            end if;
        end if;
    end process;

    process (out_clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
            last_update_strobe <= '0';
            data_out_strobe <= '0';
        elsif rising_edge(out_clk) then
            if update_strobe /= last_update_strobe then
                last_update_strobe <= update_strobe;
                data_out <= buf;
                data_out_strobe <= '1';
            else
                data_out_strobe <= '0';
            end if;
        end if;
    end process;

end Behavioral;