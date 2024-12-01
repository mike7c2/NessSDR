library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc16 is
    generic (
        WIDTH : integer := 16
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        clear : in std_logic;
        data_in : in std_logic_vector(15 downto 0);
        valid : in std_logic;
        crc_out : out std_logic_vector(15 downto 0)
    );
end entity crc16;

architecture Behavioral of crc16 is
    constant POLYNOMIAL : std_logic_vector(WIDTH - 1 downto 0) := x"8005";
begin
    process (clk, rst)
        variable crc_reg : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
    begin
        if rst = '1' then
            crc_reg := (others => '0'); -- Reset the CRC register
        elsif rising_edge(clk) then
            if clear = '1' then
                crc_reg := (others => '0');
            elsif valid = '1' then
                -- Perform the CRC calculation
                for i in 15 downto 0 loop
                    if (crc_reg(WIDTH - 1) xor data_in(i)) = '1' then
                        crc_reg := (crc_reg(WIDTH - 2 downto 0) & '0') xor POLYNOMIAL;
                    else
                        crc_reg := crc_reg(WIDTH - 2 downto 0) & '0';
                    end if;
                end loop;
            end if;
        end if;
        crc_out <= crc_reg;
    end process;

end architecture Behavioral;