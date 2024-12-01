library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comb_lfsr is
    generic (
        WIDTH : integer                       := 32;
        POLY  : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        current    : in std_logic_vector(WIDTH - 1 downto 0);
        next_value : out std_logic_vector(WIDTH - 1 downto 0)
    );
end comb_lfsr;

architecture Behavioral of comb_lfsr is
    signal poly_reg : std_logic_vector(WIDTH - 1 downto 0) := (others => '1');
    signal current_broadcast : std_logic_vector(WIDTH - 1 downto 0);
    signal xor_mask : std_logic_vector(WIDTH - 1 downto 0);
begin
    current_broadcast <= (others => current(0));
    xor_mask <= current_broadcast and POLY(31 downto 32 - WIDTH);
    next_value <= ("0" & current(WIDTH - 1 downto 1)) xor xor_mask;
end Behavioral;