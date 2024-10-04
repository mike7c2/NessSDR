library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AdcPkg.all;
use work.LutFirPkg.all;
use work.DeserPkg.all;

entity test_harness is
  generic (
    DATA_WIDTH : integer := 16;
    SYNC_DELAY : integer := 1;
    LUTS_POW : integer := 3;
    LUT_WIDTH : integer := 16;
    LUT_DEPTH : integer := 8;
    DATA_OUTPUT_WIDTH :integer := 12
  );
  port (
    clk : in std_logic;
    rst : in std_logic;

    adc_di : in std_logic_vector(1 downto 0);
    adc_cmp : out std_logic;
    adc_do : out std_logic_vector(DATA_WIDTH-1 downto 0);
    adc_do_strobe : out std_logic;

    dc_data_out : out std_logic_vector(DATA_OUTPUT_WIDTH-1 downto 0);
    dc_data_strobe : out std_logic;

    lut_wr_clk : in std_logic;
    lut_wr_en : in std_logic;
    lut_wr_addr : in std_logic_vector(LUT_DEPTH + LUTS_POW - 1 downto 0);
    lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
  );
end test_harness;

architecture test_harness of test_harness is
  signal adc_do_strobe_int : std_logic;
  signal adc_do_int : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal deser_int : std_logic_vector(LUT_DEPTH * 2**(LUTS_POW+1) - 1 downto 0);
begin
  adc_do_strobe <= adc_do_strobe_int;
  adc_do <= adc_do_int;

  uut: ADC
  generic map (
    DATA_WIDTH => DATA_WIDTH,
    SYNC_DELAY => SYNC_DELAY
  )
  port map (
      clk => clk,
      rst => rst,
      di => adc_di,
      do => adc_do_int,
      do_strobe => adc_do_strobe_int
  );

  de : deser
  generic map (
    INPUT_WIDTH => DATA_WIDTH,
    OUTPUT_WIDTH => LUT_DEPTH*2**(LUTS_POW+1)
  )
  port map (
    clk => clk,
    rst => rst,
    data_in_strobe => adc_do_strobe_int,
    data_in => adc_do_int,

    data_out => deser_int
  );

  lut_fir: LutFir
  generic map (
    LUTS_POW => LUTS_POW,
    LUT_WIDTH => LUT_WIDTH,
    LUT_DEPTH => LUT_DEPTH,
    DATA_OUTPUT_WIDTH => DATA_OUTPUT_WIDTH
  )
  port map (
    clk => clk,
    rst => rst,
    di_strobe => adc_do_strobe_int,
    data_in => deser_int,

    data_out => dc_data_out,
    do_strobe => dc_data_strobe,

    lut_wr_clk => lut_wr_clk,
    lut_wr_en => lut_wr_en,
    lut_wr_addr => lut_wr_addr,
    lut_wr_data => lut_wr_data
  );

end test_harness;