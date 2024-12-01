library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipelined_multiplier is
    generic (
        N_STAGES        : integer := 4;
        DATA_WIDTH_IN_A : integer := 16;
        DATA_WIDTH_IN_B : integer := 16
    );
    port (
        clk       : in std_logic;
        rst       : in std_logic;
        data_in_a : in std_logic_vector(DATA_WIDTH_IN_A - 1 downto 0);
        data_in_b : in std_logic_vector(DATA_WIDTH_IN_B - 1 downto 0);
        data_out  : out std_logic_vector(DATA_WIDTH_IN_A + DATA_WIDTH_IN_B - 1 downto 0)
    );
end pipelined_multiplier;

architecture Behavioral of pipelined_multiplier is
    constant DATA_OUTPUT_WIDTH : integer := DATA_WIDTH_IN_A + DATA_WIDTH_IN_B;
    constant BITS_PER_STAGE : integer := (DATA_WIDTH_IN_A + (N_STAGES - 1)) / N_STAGES;

    type intermediate_reg_a is array (0 to N_STAGES) of std_logic_vector(DATA_WIDTH_IN_A - 1 downto 0);
    type intermediate_reg_b is array (0 to N_STAGES) of std_logic_vector(DATA_WIDTH_IN_B - 1 downto 0);
    type intermediate_reg is array (0 to N_STAGES) of std_logic_vector(DATA_OUTPUT_WIDTH - 1 downto 0);
    signal intermediate_data_a : intermediate_reg_a;
    signal intermediate_data_b : intermediate_reg_b;
    signal intermediate_regs : intermediate_reg;
begin
    process (clk, rst)
        variable add : std_logic_vector(DATA_OUTPUT_WIDTH - 1 downto 0);
        constant prepend : std_logic_vector(DATA_OUTPUT_WIDTH - 1 downto 0) := (others => '0');
    begin
        if rst = '1' then
            data_out <= (others => '0');
            intermediate_data_a <= (others => (others => '0'));
            intermediate_data_b <= (others => (others => '0'));
            intermediate_regs <= (others => (others => '0'));
        elsif rising_edge(clk) then
            intermediate_data_a(0) <= data_in_a;
            intermediate_data_b(0) <= data_in_b;
            intermediate_regs(0) <= (others => '0');
            for stage in 1 to N_STAGES loop
                intermediate_data_a(stage) <= intermediate_data_a(stage - 1);
                intermediate_data_b(stage) <= intermediate_data_b(stage - 1);

                add := intermediate_regs(stage - 1);

                for b in 0 to BITS_PER_STAGE - 1 loop
                    if intermediate_data_a(stage - 1)(b + (stage - 1) * BITS_PER_STAGE) = '1' then
                        add := std_logic_vector(
                            resize(
                            signed(add) +
                            signed(
                            intermediate_data_b(stage - 1)) *
                            2 ** (b + (stage - 1) * BITS_PER_STAGE),
                            DATA_OUTPUT_WIDTH
                            )
                            );
                    end if;
                end loop;

                intermediate_regs(stage) <= add;
            end loop;

            data_out <= intermediate_regs(N_STAGES);
        end if;
    end process;
end Behavioral;