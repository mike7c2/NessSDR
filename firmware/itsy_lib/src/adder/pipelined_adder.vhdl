library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipelined_adder is
    generic (
        N_INPUTS      : integer := 8;
        N_INPUTS_POW  : integer := 3;
        DATA_WIDTH_IN : integer := 16
    );
    port (
        clk      : in std_logic;
        rst      : in std_logic;
        data_in  : in std_logic_vector(N_INPUTS * DATA_WIDTH_IN - 1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH_IN + N_INPUTS_POW - 1 downto 0)
    );
end pipelined_adder;

architecture Behavioral of pipelined_adder is
    constant N_RANKS : integer := N_INPUTS_POW;
    constant DATA_WIDTH_OUT : integer := DATA_WIDTH_IN + N_INPUTS_POW;
    type intermediate_regs is array (0 to N_RANKS - 1, 0 to N_INPUTS/2 - 1) of std_logic_vector(DATA_WIDTH_OUT - 1 downto 0);
    signal intermediate_bits : intermediate_regs;
begin
    process (clk, rst)

    begin
        if rst = '1' then
            data_out <= (others => '0');
            intermediate_bits <= (others => (others => (others => '0')));
        elsif rising_edge(clk) then
            for i in 0 to (N_INPUTS/2) - 1 loop
                intermediate_bits(0, i)(DATA_WIDTH_OUT - 1 downto 0) <= std_logic_vector(
                resize(signed(data_in((i + 1) * DATA_WIDTH_IN - 1 downto (i) * DATA_WIDTH_IN)), DATA_WIDTH_OUT) +
                resize(signed(data_in((i + 1 + (N_INPUTS/2)) * DATA_WIDTH_IN - 1 downto (i + (N_INPUTS/2)) * DATA_WIDTH_IN)), DATA_WIDTH_OUT)
                );
            end loop;
            for stage in 1 to N_INPUTS_POW loop
                for i in 0 to (N_INPUTS/2 ** (stage + 1)) - 1 loop
                    intermediate_bits(stage, i)(DATA_WIDTH_OUT - 1 downto 0) <= std_logic_vector(
                    signed(intermediate_bits(stage - 1, i)) + signed(intermediate_bits(stage - 1, i + (N_INPUTS/2 ** (stage + 1))))
                    );
                end loop;
            end loop;

            data_out <= intermediate_bits(N_RANKS - 1, 0);
        end if;
    end process;
end Behavioral;