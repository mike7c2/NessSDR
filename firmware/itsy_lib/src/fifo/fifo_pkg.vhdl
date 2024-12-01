library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fifo_pkg is
    component fifo is
        generic (
            DATA_WIDTH : integer := 16;
            ADDR_WIDTH : integer := 8
        );
        port (
            clk      : in std_logic;
            rst      : in std_logic;
            clear    : in std_logic;
            write_en : in std_logic;
            read_en  : in std_logic;
            data_in  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            empty    : out std_logic;
            full     : out std_logic
        );
    end component;

    component rw_clk_fifo is
        generic (
            DATA_WIDTH     : integer := 16;
            ADDR_WIDTH     : integer := 6;
            XFER_DELAY_POW : integer := 1
        );
        port (
            rst : in std_logic;

            wr_clk   : in std_logic;
            write_en : in std_logic;
            data_in  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            full     : out std_logic;

            rd_clk   : in std_logic;
            read_en  : in std_logic;
            data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            empty    : out std_logic
        );
    end component;

    component rw_clk_fifo_lfsr is
        generic (
            DATA_WIDTH     : integer := 16;
            ADDR_WIDTH     : integer := 6;
            XFER_DELAY_POW : integer := 1
        );
        port (
            rst : in std_logic;

            wr_clk   : in std_logic;
            write_en : in std_logic;
            data_in  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            full     : out std_logic;

            rd_clk   : in std_logic;
            read_en  : in std_logic;
            data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            empty    : out std_logic
        );
    end component;

end fifo_pkg;