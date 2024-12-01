library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
    generic (
        WIDTH : integer                       := 32;
        POLY  : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk      : in std_logic;
        rst      : in std_logic;
        data_out : out std_logic
    );
end lfsr;

architecture Behavioral of lfsr is
    signal lfsr_reg : std_logic_vector(WIDTH - 1 downto 0) := (others => '1');
    signal feedback : std_logic;
begin
    -- Process to calculate feedback and shift the LFSR
    process (clk, rst)
        variable temp_feedback : std_logic := '0'; -- Temporary variable for feedback calculation
    begin
        if rst = '1' then
            lfsr_reg <= (others => '1'); -- Reset to a non-zero value
        elsif rising_edge(clk) then
            -- Calculate feedback by XORing bits based on POLY
            temp_feedback := '0';
            for i in 0 to WIDTH - 1 loop
                if POLY(i) = '1' then
                    temp_feedback := temp_feedback xor lfsr_reg(i);
                end if;
            end loop;

            feedback <= temp_feedback;
            lfsr_reg <= feedback & lfsr_reg(WIDTH - 1 downto 1); -- Shift left, inject feedback
        end if;
    end process;

    data_out <= lfsr_reg(WIDTH - 1); -- Output MSB as LFSR output
end Behavioral;