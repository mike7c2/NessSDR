library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 6
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
end fifo;

architecture Behavioral of FIFO is
    constant RAM_SIZE : integer := 2 ** ADDR_WIDTH;

    signal write_pointer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal read_pointer : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

    signal internal_data_out : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal internal_empty : std_logic;
    signal internal_full : std_logic;

    type ram_type is array (0 to RAM_SIZE - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram : ram_type;
begin

    process (clk, rst)
    begin
        if rst = '1' then
            read_pointer <= (others => '0');
            internal_data_out <= (others => '0');
            internal_empty <= '1';
        elsif rising_edge(clk) then
            if clear = '1' then
                read_pointer <= (others => '0');
            elsif read_en = '1' and internal_empty = '0' then
                internal_data_out <= ram(to_integer(unsigned(read_pointer)));
                if std_logic_vector(unsigned(read_pointer) + 1) = write_pointer then
                    internal_empty <= '1';
                end if;

                read_pointer <= std_logic_vector(unsigned(read_pointer) + 1);
            elsif internal_empty = '1' and read_pointer /= write_pointer then
                internal_empty <= '0';
            end if;
        end if;
    end process;

    process (clk, rst)
    begin
        if rst = '1' then
            write_pointer <= (others => '0');
            internal_full <= '0';
        elsif rising_edge(clk) then
            if clear = '1' then
                write_pointer <= (others => '0');
            elsif write_en = '1' and internal_full = '0' then
                ram(to_integer(unsigned(write_pointer))) <= data_in;

                if std_logic_vector(unsigned(write_pointer) + 1) = read_pointer then
                    internal_full <= '1';
                end if;

                write_pointer <= std_logic_vector(unsigned(write_pointer) + 1);
            elsif internal_full = '1' and write_pointer /= read_pointer then
                internal_full <= '0';
            end if;
        end if;
    end process;

    -- Assign output signals
    data_out <= internal_data_out;
    empty <= internal_empty;
    full <= internal_full;

end Behavioral;