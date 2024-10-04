library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Ice40HX.all;
use work.Utilities.all;
use work.AdcPkg.all;
use work.LutFirPkg.all;
use work.DeserPkg.all;

entity top_level is
  port (
    clk : in std_logic;
    leds : out std_logic_vector(7 downto 0);
    ftdi_rx : in std_logic;
    ftdi_tx : out std_logic;

    adc_di : inout std_logic;
    adc_do : out std_logic_vector(63 downto 0);
    adc_do_strobe : out std_logic;

    lut_wr_clk : in std_logic;
    lut_wr_en : in std_logic;
    lut_wr_addr : in std_logic_vector(10 downto 0);
    lut_wr_data : in std_logic_vector(15 downto 0);

    dc_data_out : out std_logic_vector(7 downto 0);
    dc_data_strobe : out std_logic
  );
end top_level;

architecture top_level of top_level is
  constant ADC_DC_WIDTH : integer := 64;

  signal nrst : std_logic := '0';
  signal clk_4hz: std_logic;
  signal leds_buf : std_ulogic_vector (1 to 6);

  signal clk_adc : std_logic;
  signal rst_adc : std_logic;

  signal clk_downconverter : std_logic;
  signal rst_downconverter : std_logic;

  signal pllrst : std_logic;

  signal adc_do_strobe_int : std_logic;
  signal adc_do_int : std_logic_vector(ADC_DC_WIDTH-1 downto 0);

  signal adc_di_int : std_logic_vector(1 downto 0);
  signal deser_int : std_logic_vector(8 * 2**(4) - 1 downto 0);

begin

  process (clk)
    variable cnt : unsigned (1 downto 0) := "00";
  begin
    if rising_edge (clk) then
      if cnt = 3 then
        nrst <= '1';
      else
        cnt := cnt + 1;
      end if;
    end if;
  end process;

  pll_inst : SB_PLL40_CORE
  generic map (
    FEEDBACK_PATH => "SIMPLE",
    DIVR => "0000",
    DIVF => "0111111",
    DIVQ => "101",
    FILTER_RANGE => "001"
  )
  port map (
    REFERENCECLK => clk,
    RESETB        => nrst,
    PLLOUTGLOBAL => clk_adc,
    BYPASS => '0',
    LOCK => rst_adc
  );

  adc_input_io : SB_IO
  generic map (
    PIN_TYPE => (others => '0'),
    PULLUP => '0',
    NEG_TRIGGER => '0',
    IO_STANDARD => "SB_LVCMOS"
  )
  port map (
    PACKAGE_PIN => adc_di,
    INPUT_CLK => clk_adc,
    OUTPUT_CLK => clk_adc,
    OUTPUT_ENABLE => '0',
    D_OUT_0 => '0',
    D_OUT_1 => '0',
    D_IN_0 => adc_di_int(0),
    D_IN_1 => adc_di_int(1)
  );

  adc_do_strobe <= adc_do_strobe_int;
  adc_do(ADC_DC_WIDTH-1 downto 0) <= adc_do_int;
  uut: ADC
  generic map (
    DATA_WIDTH => ADC_DC_WIDTH,
    SYNC_DELAY => 1
  )
  port map (
      clk => clk_adc,
      rst => rst_adc,
      di => adc_di_int,
      do => adc_do_int,
      do_strobe => adc_do_strobe_int
  );

  de : deser
  generic map (
    INPUT_WIDTH => ADC_DC_WIDTH,
    OUTPUT_WIDTH => 8*2**4
  )
  port map (
    clk => clk,
    rst => rst_adc,
    data_in_strobe => adc_do_strobe_int,
    data_in => adc_do_int,

    data_out => deser_int
  );

  lut_fir: LutFir
  generic map (
    LUTS_POW => 3,
    LUT_WIDTH => 16,
    LUT_DEPTH => 8,
    DATA_OUTPUT_WIDTH => 8
  )
  port map (
    clk => clk,
    rst => rst_adc,
    di_strobe => adc_do_strobe_int,
    data_in => deser_int,

    data_out => dc_data_out,
    do_strobe => dc_data_strobe,

    lut_wr_clk => lut_wr_clk,
    lut_wr_en => lut_wr_en,
    lut_wr_addr => lut_wr_addr,
    lut_wr_data => lut_wr_data
  );

  leds <= (others => '0');
end top_level;
