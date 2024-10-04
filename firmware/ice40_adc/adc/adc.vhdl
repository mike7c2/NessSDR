library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ADC is
    generic (
        DATA_WIDTH : integer := 8;
        SYNC_DELAY : integer := 1
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        di  : in std_logic_vector(1 downto 0);
        do  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        do_strobe  : out std_logic
    );
end ADC;

architecture Behavioral of ADC is
    signal shift_register : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal di_sync : std_logic_vector((SYNC_DELAY*2)-1 downto 0);
    signal do_strobe_int : std_logic;
begin

    process(clk, rst)
    begin
        if rst = '1' then
            di_sync <= (others => '0');
        elsif rising_edge(clk) then
            di_sync <= di_sync(di_sync'left-2 downto 0) & di;
        end if;
    end process;

    do_strobe <= do_strobe_int;

    process(clk, rst)
    begin
        if rst = '1' then
            do_strobe_int <= '0';
        elsif rising_edge(clk) then
            if shift_register(DATA_WIDTH-2) = '1' then
                do_strobe_int <= '1';
            else                
                do_strobe_int <= '0';
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            shift_register <= (0 => '1', others => '0');
        elsif rising_edge(clk) then
            
            if shift_register(DATA_WIDTH-2) = '1' then
                do <= shift_register(shift_register'left-2 downto 0) & di_sync(1 downto 0);
                shift_register <= (0 => '1', others => '0');
            else
                shift_register <= shift_register(shift_register'left-2 downto 0) & di_sync(1 downto 0);    
            end if;
        end if;
    end process;
end Behavioral;