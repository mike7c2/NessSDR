library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pipeline_controller_pkg is
    component pipeline_controller is
        generic (
            FIFO_DEPTH : integer := 10
        );
        port (
            clk : in std_logic;
            rst : in std_logic;

            spi_clk  : in std_logic;
            spi_mosi : in std_logic;
            spi_miso : out std_logic;
            spi_cs   : in std_logic;

            pipeline_data_in_strobe : std_logic;
            pipeline_data_in        : std_logic_vector(15 downto 0);

            pipeline_wr_en   : out std_logic;
            pipeline_wr_addr : out std_logic_vector(15 downto 0);
            pipeline_wr_data : out std_logic_vector(15 downto 0);

            streaming_active : out std_logic
        );
    end component;

    component pipeline_hspi_controller is
        port (
            clk : in std_logic;
            rst : in std_logic;

            bus_data : inout std_logic_vector(15 downto 0);

            htclk : out std_logic;
            htreq : out std_logic;
            htrdy : in std_logic;
            htvld : out std_logic;

            hrclk : in std_logic;
            hract : in std_logic;
            htack : out std_logic;
            hrvld : in std_logic;

            pipeline_data_in_strobe : std_logic;
            pipeline_data_in        : std_logic_vector(15 downto 0);

            pipeline_wr_en   : out std_logic;
            pipeline_wr_addr : out std_logic_vector(15 downto 0);
            pipeline_wr_data : out std_logic_vector(15 downto 0);

            streaming_active : out std_logic
        );

    end component;

    constant WRITE_DATA_CMD : std_logic_vector := "0000000000000001";
    constant START_STREAM_CMD : std_logic_vector := "0000000000000011";
    constant STOP_STREAM_CMD : std_logic_vector := "0000000000000100";

end pipeline_controller_pkg;