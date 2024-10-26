library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cic is
    generic (
        N : integer := 3;  -- Number of stages for both integrator and differentiator
        R : integer := 8;
        D : integer := 1;
        WIDTH : integer := 32 -- Bit width for both integrator and differentiator stages
    );
    port (
        clk       : in std_logic;
        rst     : in std_logic;
        en        : in std_logic;
        input_sig : in std_logic_vector(WIDTH-1 downto 0);
        output_strobe : out std_logic;
        output_sig : out std_logic_vector(WIDTH-1 downto 0)
    );
end cic;

architecture Behavioral of cic is
    type stage_array_t is array (natural range <>) of signed(WIDTH-1 downto 0);

    signal integrator_out : stage_array_t(0 to N) := (others => (others => '0'));
    signal comb_out : stage_array_t(0 to N) := (others => (others => '0'));

    signal comb_en : std_logic;
begin
    integrator_out(0) <= signed(input_sig);

    gen_integrators : for i in 0 to N-1 generate
        u_integrator : entity work.integrator
            generic map (
                WIDTH => WIDTH
            )
            port map (
                clk => clk,
                rst => rst,
                en => en,
                input_sig => integrator_out(i),
                output_sig => integrator_out(i+1)
            );
    end generate gen_integrators;

    process(clk, rst)
        variable comb_cnt : integer;
    begin
        if rst = '1' then
            comb_en <= '0';
            comb_cnt := 0;
        elsif rising_edge(clk) then
            comb_en <= '0';

            if en = '1' then
                if comb_cnt = R-1 then
                    comb_en <= '1';
                    comb_cnt := 0;
                else
                    comb_cnt := comb_cnt + 1;
                end if;
                
            end if;
        end if;
    end process;

    comb_out(0) <= integrator_out(N);

    gen_combs : for i in 0 to N-1 generate
        u_differentiator : entity work.differentiator
            generic map (
                WIDTH => WIDTH,
                DELAY => D
            )
            port map (
                clk => clk,
                rst => rst,
                en => comb_en,
                input_sig => comb_out(i),
                output_sig => comb_out(i+1)
            );
    end generate gen_combs;

    output_strobe <= comb_en;
    output_sig <= std_logic_vector(comb_out(N));

end Behavioral;
