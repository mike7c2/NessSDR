library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lfsr_pkg.all;

entity rw_clk_fifo_lfsr is
    generic (
        DATA_WIDTH     : integer := 16;
        ADDR_WIDTH     : integer := 10;
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
end rw_clk_fifo_lfsr;

architecture Behavioral of rw_clk_fifo_lfsr is
    constant RAM_SIZE : integer := 2 ** ADDR_WIDTH;

    signal write_pointer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal next_write_pointer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal read_pointer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal next_read_pointer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

    signal read_pointer_xfer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal read_pointer_toggle : std_logic;
    signal read_pointer_toggle_buf : std_logic;
    signal read_pointer_write_clocked : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal empty_int : std_logic;

    signal write_pointer_xfer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal write_pointer_toggle : std_logic;
    signal write_pointer_toggle_buf : std_logic;
    signal write_pointer_read_clocked : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal full_int : std_logic;

    type ram_type is array (0 to RAM_SIZE - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram : ram_type;
begin

    rd_lfsr : comb_lfsr
    generic map(
        WIDTH => ADDR_WIDTH,
        POLY  => LFSR_MAXIMAL_LENGTH_POLY_LUT(ADDR_WIDTH)
    )
    port map(
        current    => read_pointer,
        next_value => next_read_pointer
    );

    write_pointer_to_read_clock_cdc : process (rd_clk, rst)
        variable rd_xfer_cnt : unsigned(XFER_DELAY_POW - 1 downto 0);
    begin
        if rst = '1' then
            write_pointer_read_clocked <= (others => '0');
            write_pointer_toggle_buf <= '0';
            read_pointer_xfer <= (others => '0');
            read_pointer_toggle <= '0';
        elsif rising_edge(rd_clk) then
            if rd_xfer_cnt = 0 then
                read_pointer_xfer <= read_pointer;
            elsif rd_xfer_cnt = 2 ** XFER_DELAY_POW / 2 then
                read_pointer_toggle <= not read_pointer_toggle;
            end if;

            rd_xfer_cnt := rd_xfer_cnt + 1;

            if write_pointer_toggle_buf /= write_pointer_toggle then
                write_pointer_toggle_buf <= write_pointer_toggle;
                write_pointer_read_clocked <= write_pointer_xfer;
            end if;
        end if;
    end process;

    fifo_rd_process : process (rd_clk, rst)
    begin
        if rst = '1' then
            read_pointer <= (0 => '1', others => '0');
            data_out <= (others => '0');
            empty_int <= '1';
        elsif rising_edge(rd_clk) then
            if read_en = '1' and empty_int = '0' then
                data_out <= ram(to_integer(unsigned(read_pointer)));
                read_pointer <= next_read_pointer;

                if next_read_pointer = write_pointer_read_clocked then
                    empty_int <= '1';
                end if;
            end if;

            if empty_int = '1' then
                if read_pointer /= write_pointer_read_clocked then
                    empty_int <= '0';
                end if;
            end if;
        end if;
    end process;

    wr_lfsr : comb_lfsr
    generic map(
        WIDTH => ADDR_WIDTH,
        POLY  => LFSR_MAXIMAL_LENGTH_POLY_LUT(ADDR_WIDTH)
    )
    port map(
        current    => write_pointer,
        next_value => next_write_pointer
    );

    read_pointer_to_write_clock_cdc : process (wr_clk, rst)
        variable wr_xfer_cnt : unsigned(XFER_DELAY_POW - 1 downto 0);
    begin
        if rst = '1' then
            read_pointer_write_clocked <= (others => '0');
            read_pointer_toggle_buf <= '0';
            write_pointer_xfer <= (others => '0');
            write_pointer_toggle <= '0';
        elsif rising_edge(wr_clk) then
            if wr_xfer_cnt = 0 then
                write_pointer_xfer <= write_pointer;
            elsif wr_xfer_cnt = 2 ** XFER_DELAY_POW / 2 then
                write_pointer_toggle <= not write_pointer_toggle;
            end if;

            wr_xfer_cnt := wr_xfer_cnt + 1;

            if read_pointer_toggle_buf /= read_pointer_toggle then
                read_pointer_toggle_buf <= read_pointer_toggle;
                read_pointer_write_clocked <= read_pointer_xfer;
            end if;
        end if;
    end process;

                
    fifo_wr_process : process (wr_clk, rst)
    begin
        if rst = '1' then
            write_pointer <= (0 => '1', others => '0');
            full_int <= '0';
        elsif rising_edge(wr_clk) then
            if write_en = '1' and full_int = '0' then
                ram(to_integer(unsigned(write_pointer))) <= data_in;
                write_pointer <= next_write_pointer;

                if next_write_pointer = read_pointer_write_clocked then
                    full_int <= '1';
                end if;
            end if;

            if full_int = '1' then
                if write_pointer /= read_pointer_write_clocked then
                    full_int <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Assign output signals
    empty <= empty_int;
    full <= full_int;

end Behavioral;