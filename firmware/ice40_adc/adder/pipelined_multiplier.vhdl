library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity pipelined_multiplier is
    generic (
        N_STAGES : integer := 4;
        DATA_WIDTH_IN_A : integer := 16;
        DATA_WIDTH_IN_B : integer := 16
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        data_in_a : in std_logic_vector(DATA_WIDTH_IN_A-1 downto 0);
        data_in_b : in std_logic_vector(DATA_WIDTH_IN_B-1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH_IN_A + DATA_WIDTH_IN_B - 1 downto 0)
    );

    -- Function declaration
    function left_shift_pad(
        input_vec    : std_logic_vector;  -- Input vector to shift
        output_len   : integer;           -- Desired length of the output vector
        shift_amount : integer            -- Shift amount
    ) return std_logic_vector is
        constant input_len : integer := input_vec'length;  -- Infer input vector length
        variable temp_output : std_logic_vector(output_len-1 downto 0);  -- Output vector
        variable shifted_data : std_logic_vector(output_len-1 downto 0); -- Shifted version of input
    begin
        -- Initialize output with zeros
        temp_output := (others => '0');
        
        -- Shift input vector left by shift_amount and zero-pad
        if shift_amount < input_len then
            -- Shift the input and fill with 0s
            shifted_data := input_vec & (output_len - input_len - 1 downto 0 => '0');
            shifted_data := shifted_data(output_len-1 downto shift_amount) & (shift_amount-1 downto 0 => '0');
        else
            -- If shift amount exceeds or equals input length, output will be zero-padded
            shifted_data := (others => '0');
        end if;
        
        -- Assign shifted result to output
        temp_output := shifted_data;

        return temp_output;
    end left_shift_pad;
end pipelined_multiplier;

architecture Behavioral of pipelined_multiplier is
    constant DATA_OUTPUT_WIDTH : integer := DATA_WIDTH_IN_A + DATA_WIDTH_IN_B;
    constant BITS_PER_STAGE : integer := DATA_WIDTH_IN_A+(N_STAGES-1) / N_STAGES;

    type intermediate_reg_a is array (0 to N_STAGES - 1) of std_logic_vector(DATA_WIDTH_IN_A-1 downto 0);
    type intermediate_reg_b is array (0 to N_STAGES - 1) of std_logic_vector(DATA_WIDTH_IN_B-1 downto 0);
    type intermediate_reg is array (0 to N_STAGES - 1) of std_logic_vector(DATA_OUTPUT_WIDTH-1 downto 0);
    signal intermediate_data_a : intermediate_reg_a;
    signal intermediate_data_b : intermediate_reg_b;
    signal intermediate_regs : intermediate_reg;
begin
    process(clk, rst)
        variable add : std_logic_vector(DATA_OUTPUT_WIDTH-1 downto 0);
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
                intermediate_data_a(stage) <= intermediate_data_a(stage-1);
                intermediate_data_b(stage) <= intermediate_data_b(stage-1);
                
                add := intermediate_regs(stage-1);

                for b in 0 to BITS_PER_STAGE loop
                    if intermediate_data_a(stage-1)(b + (stage-1) * BITS_PER_STAGE) = '1' then
                        add := std_logic_vector(
                            unsigned(add) + 
                            unsigned(left_shift_pad(intermediate_data_b(stage-1), DATA_OUTPUT_WIDTH-1, b + (stage-1) * BITS_PER_STAGE))
                        );
                    end if;
                end loop;
            end loop;

            data_out <= intermediate_regs(N_STAGES-1);
        end if;
    end process;
end Behavioral;