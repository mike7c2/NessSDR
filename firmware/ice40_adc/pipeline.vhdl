library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AdcPkg.all;
use work.LutFirPkg.all;
use work.RebufferPkg.all;
use work.NcoPkg.all;
use work.MultiplierPkg.all;
use work.DelayPkg.all;
use work.CicPkg.all;

entity pipeline is
    generic (
        ADC_DATA_WIDTH : integer := 16;
        SYNC_DELAY : integer := 1;
        LUTS_POW : integer := 3;
        LUT_WIDTH : integer := 16;
        LUT_DEPTH : integer := 8;
        LUTFIR_OUTPUT_WIDTH :integer := 16;
        NCO_LUT_DEPTH : integer := 10;
        NCO_LUT_WIDTH : integer := 16;
        CIC_N : integer := 5;
        CIC_R : integer := 32;
        CIC_WIDTH : integer := 32;
        MULTIPLIER_STAGES : integer := 4
    );
    port (
        adc_clk : in std_logic;
        if_proc_clk : in std_logic;
        bb_proc_clk : in std_logic;

        lut_wr_clk : in std_logic;

        rst : in std_logic;

        adc_di : in std_logic_vector(1 downto 0);
        adc_do : out std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
        adc_do_strobe : out std_logic;

        dc_data_out : out std_logic_vector(LUTFIR_OUTPUT_WIDTH-1 downto 0);
        dc_data_strobe : out std_logic;

        nco_data_out : out std_logic_vector(NCO_LUT_WIDTH downto 0);
        nco_i_strobe : out std_logic;
        nco_q_strobe : out std_logic;

        multiplier_out : out std_logic_vector((NCO_LUT_WIDTH + NCO_LUT_WIDTH) - 1 downto 0);
        mul_i_strobe : out std_logic;
        mul_q_strobe : out std_logic;

        cic_i_strobe : out std_logic;
        cic_out_i : out std_logic_vector(CIC_WIDTH-1 downto 0);
        cic_q_strobe : out std_logic;
        cic_out_q : out std_logic_vector(CIC_WIDTH-1 downto 0);

        lut_wr_en : in std_logic;
        lut_wr_addr : in std_logic_vector(LUT_DEPTH + LUTS_POW + 1 downto 0);
        lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
    );
end pipeline;

architecture pipeline of pipeline is
    signal adc_do_strobe_int : std_logic;
    signal adc_do_int : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);

    signal re_do_strobe_int : std_logic;
    signal re_int : std_logic_vector(LUT_DEPTH * 2**(LUTS_POW+1) - 1 downto 0);

    signal dc_data_strobe_int : std_logic;
    signal dc_data_out_int : std_logic_vector(LUTFIR_OUTPUT_WIDTH-1 downto 0);

    signal nco_lut_wr_en : std_logic;
    signal fir_lut_wr_en : std_logic;

    signal nco_do_int : std_logic_vector(NCO_LUT_WIDTH downto 0);
    signal nco_i_strobe_int : std_logic;
    signal nco_q_strobe_int : std_logic;

    signal nco_strobe_vec : std_logic_vector(1 downto 0);
    signal mul_strobe_int : std_logic_vector(1 downto 0);

    signal multiplier_out_int : std_logic_vector((NCO_LUT_WIDTH + NCO_LUT_WIDTH) - 1 downto 0);
    signal multiplier_int_div : std_logic_vector((NCO_LUT_WIDTH + NCO_LUT_WIDTH) - 1 downto 0);

    signal cic_in : std_logic_vector(CIC_WIDTH-1 downto 0);


    signal nco_phase_inc : std_logic_vector(15 downto 0);
    signal phase : std_logic_vector(15 downto 0);
    signal phase_inc_wr_en : std_logic;
begin
    adc_do_strobe <= adc_do_strobe_int;
    adc_do <= adc_do_int;

    uut: ADC
    generic map (
        DATA_WIDTH => ADC_DATA_WIDTH,
        SYNC_DELAY => SYNC_DELAY
    )
    port map (
        clk => adc_clk,
        rst => rst,
        di => adc_di,
        do => adc_do_int,
        do_strobe => adc_do_strobe_int
    );

    re : rebuffer
    generic map (
        INPUT_WIDTH => ADC_DATA_WIDTH,
        OUTPUT_WIDTH => LUT_DEPTH*2**(LUTS_POW+1)
    )
    port map (
        in_clk => adc_clk,
        out_clk => if_proc_clk,
        rst => rst,
        data_in_strobe => adc_do_strobe_int,
        data_in => adc_do_int,

        data_out_strobe => re_do_strobe_int,
        data_out => re_int
    );

    dc_data_strobe <= dc_data_strobe_int;
    dc_data_out <= dc_data_out_int;

    fir_lut_wr_en <= '1' when lut_wr_en ='1' and lut_wr_addr(lut_wr_addr'left downto lut_wr_addr'left - 1) = "00" else '0';
    nco_lut_wr_en <= '1' when lut_wr_en = '1'and lut_wr_addr(lut_wr_addr'left downto lut_wr_addr'left - 1) = "01" else '0';
    phase_inc_wr_en <= '1' when lut_wr_en = '1' and lut_wr_addr(lut_wr_addr'left downto lut_wr_addr'left - 1) = "10" else '0';

    lut_fir: LutFir
    generic map (
        LUTS_POW => LUTS_POW,
        LUT_WIDTH => LUT_WIDTH,
        LUT_DEPTH => LUT_DEPTH,
        DATA_OUTPUT_WIDTH => LUTFIR_OUTPUT_WIDTH
    )
    port map (
        clk => if_proc_clk,
        rst => rst,
        di_strobe => re_do_strobe_int,
        data_in => re_int,

        data_out => dc_data_out_int,
        do_strobe => dc_data_strobe_int,

        lut_wr_clk => lut_wr_clk,
        lut_wr_en => fir_lut_wr_en,
        lut_wr_addr => lut_wr_addr(LUT_DEPTH+LUTS_POW - 1 downto 0),
        lut_wr_data => lut_wr_data
    );

    nco_data_out <= nco_do_int;
    nco_i_strobe <= nco_i_strobe_int;
    nco_q_strobe <= nco_q_strobe_int;

    nco_strobe_vec <= nco_q_strobe_int & nco_i_strobe_int;

    n : NCO
    generic map (
        LUT_WIDTH => NCO_LUT_WIDTH,
        LUT_DEPTH => NCO_LUT_DEPTH
    )
    port map (
        clk => bb_proc_clk,
        rst => rst,

        phase => phase(phase'left downto phase'left-(NCO_LUT_DEPTH+1)),
        di_strobe => dc_data_strobe_int,

        data_out => nco_do_int,
        out_i_strobe => nco_i_strobe_int,
        out_q_strobe => nco_q_strobe_int,

        lut_wr_clk => lut_wr_clk,
        lut_wr_en => nco_lut_wr_en,
        lut_wr_addr => lut_wr_addr(NCO_LUT_DEPTH-1 downto 0),
        lut_wr_data => lut_wr_data
    );

    mul_i_strobe <= mul_strobe_int(0);
    mul_q_strobe <= mul_strobe_int(1);

    de : delay
    generic map (
        DATA_WIDTH => 2,
        DELAY_LENGTH => MULTIPLIER_STAGES+1
    )
    port map (
        clk => bb_proc_clk,
        rst => rst,
        data_in => nco_strobe_vec,
        data_out => mul_strobe_int
    );

    multiplier_out <= multiplier_out_int;
    multiplier_int_div <= std_logic_vector(signed(multiplier_out_int) / 2**24);
    cic_in <= multiplier_int_div(multiplier_int_div'left downto multiplier_int_div'left - (CIC_WIDTH-1));

    mult : pipelined_multiplier
    generic map (
        N_STAGES => MULTIPLIER_STAGES,
        DATA_WIDTH_IN_A => NCO_LUT_WIDTH,
        DATA_WIDTH_IN_B => NCO_LUT_WIDTH
    )
    port map (
        clk => bb_proc_clk,
        rst => rst,
        data_in_a => nco_do_int(nco_do_int'left downto nco_do_int'left - (NCO_LUT_WIDTH-1)),
        data_in_b => dc_data_out_int(dc_data_out'left downto dc_data_out'left - (NCO_LUT_WIDTH-1)),
        data_out => multiplier_out_int
    );

    cic_i_inst : cic
    generic map (
        N => CIC_N,
        R => CIC_R,
        D => 1,
        WIDTH => CIC_WIDTH
    )
    port map (
        clk => bb_proc_clk,
        rst => rst,
        en => mul_strobe_int(0),
        input_sig => cic_in,
        output_strobe => cic_i_strobe,
        output_sig => cic_out_i
    );

    cic_q_inst : cic
    generic map (
        N => CIC_N,
        R => CIC_R,
        D => 1,
        WIDTH => CIC_WIDTH
    )
    port map (
        clk => bb_proc_clk,
        rst => rst,
        en => mul_strobe_int(1),
        input_sig => cic_in,
        output_strobe => cic_q_strobe,
        output_sig => cic_out_q
    );

    process(lut_wr_clk, rst)
    begin
        if rst = '1' then
            nco_phase_inc <= (others => '0');
        elsif rising_edge(lut_wr_clk) then
            if phase_inc_wr_en = '1' then
                nco_phase_inc <= lut_wr_data;
            end if;
        end if;
    end process;

    process(bb_proc_clk, rst)
    begin
        if rst = '1' then
            phase <= (others => '0');
        elsif rising_edge(bb_proc_clk) then
            if dc_data_strobe_int = '1' then
                phase <= std_logic_vector(unsigned(phase) + unsigned(nco_phase_inc));
            end if;
        end if;
    end process;

end pipeline;