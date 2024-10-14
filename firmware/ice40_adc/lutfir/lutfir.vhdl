library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Utilities.all;
use work.brampkg.all;
use work.adderpkg.all;

entity LutFIR is
    generic (
        LUTS_POW : integer := 3;
        LUT_WIDTH : integer := 16;
        LUT_DEPTH : integer := 8;
        DATA_OUTPUT_WIDTH : integer := 12
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        di_strobe : in std_logic;
        data_in  : in std_logic_vector(2**(LUTS_POW+1) * LUT_DEPTH -1 downto 0);

        data_out  : out std_logic_vector(DATA_OUTPUT_WIDTH-1 downto 0);
        do_strobe  : out std_logic;

        lut_wr_clk : in std_logic;
        lut_wr_en : in std_logic;
        lut_wr_addr : in std_logic_vector(LUT_DEPTH + LUTS_POW - 1 downto 0);
        lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
    );
end LutFIR;

architecture Behavioral of LutFIR is
    constant N_LUTS : integer := 2**LUTS_POW;

    signal di_strobe_buf : std_logic;
    signal process_en : std_logic;
    signal process_pipe : std_logic_vector(LUTS_POW+7 downto 0);
    signal buf : std_logic_vector(2**(LUTS_POW+1) * LUT_DEPTH -1 downto 0);
    signal lut_addr : std_logic_vector((LUT_DEPTH * N_LUTS) - 1 downto 0);

    signal ram_wr_enables : std_logic_vector(N_LUTS - 1 downto 0);
    signal ram_rd_data : std_logic_vector((N_LUTS) * LUT_WIDTH - 1 downto 0);
    signal ram_rd_data_buf : std_logic_vector((N_LUTS) * LUT_WIDTH - 1 downto 0);
    signal ram_rd_en : std_logic;
    signal symmetry_value : std_logic_vector(LUT_WIDTH+LUTS_POW downto 0);
    signal adder_out : std_logic_vector(LUT_WIDTH+LUTS_POW-1 downto 0);
begin

    brams: for i in 0 to N_LUTS-1 generate
        ram_wr_enables(i) <= '1' when unsigned(lut_wr_addr(LUT_DEPTH + LUTS_POW - 1 downto LUT_DEPTH)) = i and lut_wr_en = '1' else '0';

        bramx: BRAM
        generic map (
            DATA_WIDTH => LUT_WIDTH,
            ADDR_WIDTH => LUT_DEPTH
          )
          port map (
            rst => rst,

            wr_clk => lut_wr_clk,
            wr_en => ram_wr_enables(i),
            wr_addr => lut_wr_addr(LUT_DEPTH-1 downto 0),
            wr_data => lut_wr_data,
            
            rd_clk => clk,
            rd_en => ram_rd_en,
            rd_addr => lut_addr(LUT_DEPTH * (i + 1) - 1 downto LUT_DEPTH * i),
            rd_data => ram_rd_data(LUT_WIDTH * (i + 1) - 1 downto LUT_WIDTH * i)
          );
    end generate brams;

    adder: pipelined_adder
    generic map (
        N_INPUTS => N_LUTS,
        N_INPUTS_POW => LUTS_POW,
        DATA_WIDTH_IN => LUT_WIDTH
    )
    port map (
        clk => clk,
        rst => rst,
        data_in => ram_rd_data_buf,
        data_out => adder_out
    );

    process(clk, rst)
    begin
        if rst = '1' then
            buf <= (others => '0');
            process_pipe <= (others => '0');
            ram_rd_data_buf <= (others => '0');
        elsif rising_edge(clk) then
            ram_rd_data_buf <= ram_rd_data;
            if di_strobe = '1' then
                buf <= data_in;
                process_pipe <= process_pipe(process_pipe'left-1 downto 0) & '1';
            else
                process_pipe <= process_pipe(process_pipe'left-1 downto 0) & '0';
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            ram_rd_en <= '0';
            lut_addr <= (others => '0');
        elsif rising_edge(clk) then
            ram_rd_en <= '0';
            if process_pipe(0) = '1' then
                lut_addr <= buf(lut_addr'left downto 0);
                ram_rd_en <= '1';
            elsif process_pipe(1) = '1' then
                for i in lut_addr'range loop
                    lut_addr(lut_addr'left - i) <= buf(i + lut_addr'left+1);
                end loop;
                ram_rd_en <= '1';
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            symmetry_value <= (others => '0');
            data_out <= (others => '0');
            do_strobe <= '0';
        elsif rising_edge(clk) then
            do_strobe <= '0';
            if process_pipe(LUTS_POW+4) = '1' then
                symmetry_value <= std_logic_vector(resize(signed(adder_out), LUT_WIDTH+LUTS_POW+1));
            end if;
            if process_pipe(LUTS_POW+5) = '1' then
                symmetry_value <= std_logic_vector(resize(signed(adder_out), LUT_WIDTH+LUTS_POW+1) + resize(signed(symmetry_value), LUT_WIDTH+LUTS_POW+1));
            end if;
            if process_pipe(LUTS_POW+6) = '1' then
                data_out <= symmetry_value(symmetry_value'left downto symmetry_value'left - (DATA_OUTPUT_WIDTH-1));
                do_strobe <= '1';
            end if;
        end if;
    end process;

end Behavioral;