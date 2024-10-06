library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Utilities.all;
use work.brampkg.all;

entity NCO is
    generic (
        LUT_WIDTH : integer := 16;
        LUT_DEPTH : integer := 10
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        phase : in std_logic_vector(LUT_DEPTH+1 downto 0);
        di_strobe : in std_logic;

        data_out : out std_logic_vector(LUT_WIDTH downto 0);
        out_i_strobe : out std_logic;
        out_q_strobe : out std_logic;

        lut_wr_clk : in std_logic;
        lut_wr_en : in std_logic;
        lut_wr_addr : in std_logic_vector(LUT_DEPTH - 1 downto 0);
        lut_wr_data : in std_logic_vector(LUT_WIDTH - 1 downto 0)
    );
end NCO;

architecture Behavioral of NCO is
    signal process_pipeline : std_logic_vector(5 downto 0);
    signal phase_p0 : std_logic_vector(LUT_DEPTH -1 downto 0);
    signal phase_p1 : std_logic_vector(LUT_DEPTH -1 downto 0);

    signal lut_addr : std_logic_vector(LUT_DEPTH- 1 downto 0);
    signal ram_rd_data : std_logic_vector(LUT_WIDTH - 1 downto 0);
    signal ram_rd_en : std_logic;
    signal quadrant_p0 : std_logic_vector(1 downto 0);
    signal quadrant_p1 : std_logic_vector(1 downto 0);
    signal quadrant_p2 : std_logic_vector(1 downto 0);
    signal quadrant_p3 : std_logic_vector(1 downto 0);
    signal i_p1 : std_logic_vector(LUT_WIDTH-1 downto 0);
    signal i_p2 : std_logic_vector(LUT_WIDTH downto 0);
    signal q_p2 : std_logic_vector(LUT_WIDTH-1 downto 0);
    signal q_p3 : std_logic_vector(LUT_WIDTH downto 0);
begin

    bramx: BRAM
    generic map (
        DATA_WIDTH => LUT_WIDTH,
        ADDR_WIDTH => LUT_DEPTH
    )
    port map (
        rst => rst,

        wr_clk => lut_wr_clk,
        wr_en => lut_wr_en,
        wr_addr => lut_wr_addr(LUT_DEPTH-1 downto 0),
        wr_data => lut_wr_data,

        rd_clk => clk,
        rd_en => ram_rd_en,
        rd_addr => lut_addr,
        rd_data => ram_rd_data
    );

    process(clk, rst)
    begin
        if rst = '1' then
            process_pipeline <= (others => '0');
            phase_p0 <= (others => '0');
            phase_p1 <= (others => '0');
            quadrant_p0 <= (others => '0');
            quadrant_p1 <= (others => '0');
            quadrant_p2 <= (others => '0');
            quadrant_p3 <= (others => '0');
        elsif rising_edge(clk) then
            process_pipeline <= process_pipeline(process_pipeline'left-1 downto 0) & di_strobe;
            phase_p0 <= phase(phase'left - 2 downto 0);
            phase_p1 <= phase_p0;
            quadrant_p0 <= phase(phase'left downto phase'left - 1);
            quadrant_p1 <= quadrant_p0;
            quadrant_p2 <= quadrant_p1;
            quadrant_p3 <= quadrant_p2;

        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            lut_addr <= (others => '0');
            ram_rd_en <= '0';
        elsif rising_edge(clk) then
            ram_rd_en <= '0';
            if process_pipeline(0) = '1' then
                if quadrant_p0 = "00" then
                    lut_addr <= phase_p0;
                elsif quadrant_p0 = "01" then
                    lut_addr <= std_logic_vector((2**LUT_DEPTH - 1) - unsigned(phase_p0));
                elsif quadrant_p0 = "10" then
                    lut_addr <= phase_p0;
                elsif quadrant_p0 = "11" then
                    lut_addr <= std_logic_vector((2**LUT_DEPTH - 1) - unsigned(phase_p0));
                end if;
                ram_rd_en <= '1';
            elsif process_pipeline(1) = '1' then
                if quadrant_p1 = "00" then
                    lut_addr <= std_logic_vector((2**LUT_DEPTH - 1) - unsigned(phase_p0));
                elsif quadrant_p1 = "01" then
                    lut_addr <= phase_p0;
                elsif quadrant_p1 = "10" then
                    lut_addr <= std_logic_vector((2**LUT_DEPTH - 1) - unsigned(phase_p0));
                elsif quadrant_p1 = "11" then
                    lut_addr <= phase_p0;
                end if;
                ram_rd_en <= '1';
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            i_p1 <= (others => '0');
            i_p2 <= (others => '0');
            q_p2 <= (others => '0');
            q_p3 <= (others => '0');
        elsif rising_edge(clk) then
            if process_pipeline(2) = '1' then
                i_p1 <= ram_rd_data;
            end if;
            if process_pipeline(3) = '1' then
                q_p2 <= ram_rd_data;

                if quadrant_p2 = "10" or quadrant_p2 = "11" then
                    i_p2 <= std_logic_vector(-signed("0" & i_p1));
                else
                    i_p2 <= "0" & i_p1;
                end if;
            end if;
            if process_pipeline(4) = '1' then    
                if quadrant_p3 = "01" or quadrant_p3 = "10" then
                    q_p3 <= std_logic_vector(-signed("0" & q_p2));
                else
                    q_p3 <= "0" & q_p2;
                end if;
            end if;
        end if;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
            out_i_strobe <= '0';
            out_q_strobe <= '0';
        elsif rising_edge(clk) then
            out_i_strobe <= '0';
            out_q_strobe <= '0';

            if process_pipeline(4) = '1' then
                data_out <= i_p2;
                out_i_strobe <= '1';
            elsif process_pipeline(5) = '1' then
                data_out <= q_p3;
                out_q_strobe <= '1';
            end if;
        end if;
    end process;
end Behavioral;
