library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pipeline_pkg is
    component pipeline is
        generic (
            ADC_DATA_WIDTH      : integer := 16;
            SYNC_DELAY          : integer := 1;
            LUTS_POW            : integer := 4;
            LUT_WIDTH           : integer := 16;
            LUT_DEPTH           : integer := 8;
            LUTFIR_OUTPUT_WIDTH : integer := 16;
            NCO_LUT_DEPTH       : integer := 10;
            NCO_LUT_WIDTH       : integer := 16;
            CIC_N               : integer := 5;
            CIC_R               : integer := 32;
            CIC_WIDTH           : integer := 32;
            MULTIPLIER_STAGES   : integer := 4
        );
        port (
            adc_clk     : in std_logic;
            if_proc_clk : in std_logic;
    
            lut_wr_clk : in std_logic;
    
            rst : in std_logic;
    
            adc_di        : in std_logic_vector(1 downto 0);
            adc_do        : out std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
            adc_do_strobe : out std_logic;
    
            dc_data_out    : out std_logic_vector(LUTFIR_OUTPUT_WIDTH - 1 downto 0);
            dc_data_strobe : out std_logic;
    
            nco_data_out : out std_logic_vector(NCO_LUT_WIDTH downto 0);
            nco_i_strobe : out std_logic;
            nco_q_strobe : out std_logic;
    
            multiplier_out : out std_logic_vector((NCO_LUT_WIDTH + NCO_LUT_WIDTH) - 1 downto 0);
            mul_i_strobe   : out std_logic;
            mul_q_strobe   : out std_logic;
    
            cic_i_strobe : out std_logic;
            cic_out_i    : out std_logic_vector(CIC_WIDTH - 1 downto 0);
            cic_q_strobe : out std_logic;
            cic_out_q    : out std_logic_vector(CIC_WIDTH - 1 downto 0);
    
            data_out        : out std_logic_vector(15 downto 0);
            data_out_strobe : out std_logic;
    
            lut_wr_en   : in std_logic;
            lut_wr_addr : in std_logic_vector(15 downto 0);
            lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
        );
    end component;
end pipeline_pkg;