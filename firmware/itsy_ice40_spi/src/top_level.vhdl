library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ice40hx.all;
use work.utilities.all;
use work.pipeline_controller_pkg.all;
use work.pipeline_pkg.all;
use work.lfsr_pkg.all;

entity top_level is
    port (
        clk_12mhz : in std_logic;

        leds : out std_logic_vector(7 downto 0);
        dbg  : out std_logic_vector(7 downto 0);

        ftdi_sclk : in std_logic;
        ftdi_mosi : in std_logic;
        ftdi_miso : out std_logic;
        ftdi_cs   : in std_logic;

        adc_di    : inout std_logic;
        adc_do    : inout std_logic;
        noise_out : inout std_logic
    );
end top_level;

architecture top_level of top_level is
    constant CIC_WIDTH : integer := 48;

    signal nrst : std_logic := '0';

    signal clk_adc : std_logic;
    signal clk_lock_adc : std_logic;
    signal rst_adc : std_logic;

    signal clk_if : std_logic;
    signal clk_lock_if : std_logic;
    signal rst_if : std_logic;

    signal pllrst : std_logic;

    signal adc_di_int : std_logic_vector(1 downto 0);
    signal adc_di_fb : std_logic_vector(1 downto 0);

    signal lut_wr_en : std_logic;
    signal lut_wr_addr : std_logic_vector(15 downto 0);
    signal lut_wr_data : std_logic_vector(15 downto 0);

    signal spi_data_in : std_logic_vector(15 downto 0);
    signal spi_data_in_strobe : std_logic;
    signal spi_data_out : std_logic_vector(15 downto 0);
    signal spi_data_out_strobe : std_logic;
    signal spi_transaction_active : std_logic;

    signal pipeline_data : std_logic_vector(15 downto 0);
    signal pipeline_data_strobe : std_logic;

    signal pipeline_wr_en : std_logic;
    signal pipeline_rd_en : std_logic;

    signal lfsr_data_out : std_logic;

    signal clk_gen : std_logic_vector(11 downto 0);

begin

    -- 12MHz to 200MHz
    pll_inst_adc : SB_PLL40_CORE
    generic map(
        FEEDBACK_PATH => "SIMPLE",
        -- 50Mhz
        --DIVR => "0000",
        --DIVF => "1000010",
        --DIVQ => "100",
        -- 80Mhz
        --DIVR => "0000",      
        --DIVF => "0110100",
        --DIVQ => "011",
        -- 100Mhz
        --DIVR => "0000",
        --DIVF => "1000010",
        --DIVQ => "011",
        -- 120Mhz
        --DIVR => "0000",
        --DIVF => "1001111",
        --DIVQ => "011",
        -- 200Mhz
        DIVR         => "0000",
        DIVF         => "1000010",
        DIVQ         => "010",
        FILTER_RANGE => "001"
    )
    port map(
        REFERENCECLK => clk_12mhz,
        RESETB       => '1',
        PLLOUTGLOBAL => clk_adc,
        BYPASS       => '0',
        LOCK         => clk_lock_adc
    );
    rst_adc <= not clk_lock_adc;

    -- 12MHz to 80MHz
    pll_inst_if : SB_PLL40_CORE
    generic map(
        FEEDBACK_PATH => "SIMPLE",
        -- 100Mhz
        --DIVR => "0000",
        --DIVF => "1000010",
        --DIVQ => "011",
        -- 80Mhz
        DIVR => "0000",
        DIVF => "0110100",
        DIVQ => "011",
        -- 50Mhz
        --DIVR => "0000",
        --DIVF => "1000010",
        --DIVQ => "100",
        FILTER_RANGE => "001"
    )
    port map(
        REFERENCECLK => clk_12mhz,
        RESETB       => '1',
        PLLOUTGLOBAL => clk_if,
        BYPASS       => '0',
        LOCK         => clk_lock_if
    );
    rst_if <= not clk_lock_if;

    adc_input_io : SB_IO
    generic map(
        PIN_TYPE    => "000000",
        PULLUP      => '0',
        NEG_TRIGGER => '0',
        --IO_STANDARD => "SB_BLARGEN"
        --IO_STANDARD => "SB_LVCMOS"
        IO_STANDARD => "SB_LVDS_INPUT"
    )
    port map(
        PACKAGE_PIN   => adc_di,
        INPUT_CLK     => clk_adc,
        OUTPUT_CLK    => clk_adc,
        OUTPUT_ENABLE => '0',
        D_OUT_0       => '0',
        D_OUT_1       => '0',
        D_IN_0        => adc_di_int(0),
        D_IN_1        => adc_di_int(1)
    );

    --PROCESS (clk_adc)
    --BEGIN
    --    IF rising_edge (clk_adc) THEN
    --        adc_di_fb <= adc_di_int;
    --    END IF;
    --END PROCESS;
    adc_di_fb <= adc_di_int;

    adc_output_io : SB_IO
    generic map(
        PIN_TYPE    => "010000",
        PULLUP      => '0',
        NEG_TRIGGER => '0',
        IO_STANDARD => "SB_LVCMOS"
    )
    port map(
        PACKAGE_PIN   => adc_do,
        INPUT_CLK     => clk_adc,
        OUTPUT_CLK    => clk_adc,
        OUTPUT_ENABLE => '0',
        D_OUT_0       => adc_di_fb(0),
        D_OUT_1       => adc_di_fb(1),
        D_IN_0        => open,
        D_IN_1        => open
    );

    pl : pipeline
    generic map(
        ADC_DATA_WIDTH      => 16,
        SYNC_DELAY          => 1,
        LUTS_POW            => 3,
        LUT_WIDTH           => 16,
        LUT_DEPTH           => 8,
        LUTFIR_OUTPUT_WIDTH => 16,
        NCO_LUT_DEPTH       => 10,
        NCO_LUT_WIDTH       => 16,
        CIC_N               => 5,
        CIC_R               => 32,
        CIC_WIDTH           => CIC_WIDTH
    )
    port map(
        adc_clk     => clk_adc,
        if_proc_clk => clk_if,
        lut_wr_clk  => clk_if,
        rst         => rst_adc,

        adc_di         => adc_di_int,
        adc_do         => open,
        adc_do_strobe  => open,
        dc_data_out    => open,
        dc_data_strobe => open,

        nco_data_out   => open,
        nco_i_strobe   => open,
        nco_q_strobe   => open,
        multiplier_out => open,
        mul_i_strobe   => open,
        mul_q_strobe   => open,

        cic_i_strobe => open,
        cic_out_i    => open,
        cic_q_strobe => open,
        cic_out_q    => open,

        data_out_strobe => pipeline_data_strobe,
        data_out        => pipeline_data,

        lut_wr_en   => lut_wr_en,
        lut_wr_addr => lut_wr_addr,
        lut_wr_data => lut_wr_data
    );

    controller_inst : pipeline_controller
    generic map(
        FIFO_DEPTH => 11
    )
    port map(
        clk => clk_if,
        rst => rst_if,

        spi_clk  => ftdi_sclk,
        spi_mosi => ftdi_mosi,
        spi_miso => ftdi_miso,
        spi_cs   => ftdi_cs,

        pipeline_data_in_strobe => pipeline_data_strobe,
        pipeline_data_in        => pipeline_data,

        pipeline_wr_en   => lut_wr_en,
        pipeline_wr_addr => lut_wr_addr,
        pipeline_wr_data => lut_wr_data,

        streaming_active => leds(3)
    );

    lfsr_32bit : lfsr
    generic map(
        WIDTH => 32,
        POLY  => "10000000000000000000010000000011" -- 32, 22, 2, 1
    )
    port map(
        clk      => clk_adc,
        rst      => rst_adc,
        data_out => lfsr_data_out
    );

    noise_out <= lfsr_data_out;

    process (clk_12mhz)
        variable cnt : integer := 0;
        variable flip : std_logic := '0';
    begin
        if rising_edge (clk_12mhz) then
            cnt := cnt + 1;
            if cnt > 6000000 then
                cnt := 0;
                flip := not flip;
            end if;
            leds(7) <= flip;
        end if;
    end process;

    process (clk_adc)
    begin
        if rst_adc = '1' then
            clk_gen <= (others => '1');
        elsif rising_edge (clk_adc) then
            clk_gen <= std_logic_vector(unsigned(clk_gen) + 1);
            dbg <= clk_gen(clk_gen'left downto clk_gen'left - 7);
        end if;
    end process;

    leds(6) <= spi_transaction_active;
    leds(5) <= rst_adc;
    leds(4) <= rst_if;
    --leds(3) <= clk_adc;
    --leds(4) <= clk_if;
    --leds(5) <= ftdi_cs;
    --leds(6) <= ftdi_mosi;
    leds(2 downto 0) <= lut_wr_data(2 downto 0);

    --dbg(0) <= dc_data_strobe;
    --dbg(1) <= clk_if;
    --dbg(2) <= NOT clk_if;
    --dbg(3) <= spi_transaction_active;
    --dbg(4) <= spi_data_out_strobe;
    --dbg(5) <= dc_data_strobe;
    --dbg(6) <= cic_i_strobe;
    --dbg(7) <= cic_q_strobe;
end top_level;