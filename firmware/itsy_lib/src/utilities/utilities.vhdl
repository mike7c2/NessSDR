library ieee;
use ieee.std_logic_1164.all;

package utilities is

    function calculate_bit_width(n : natural) return integer;

end package utilities;

package body utilities is

    function calculate_bit_width(n : natural) return integer is
        variable width : integer := 0;
        variable temp : natural := n;
    begin
        while temp > 0 loop
            width := width + 1;
            temp := temp / 2;
        end loop;
        return width;
    end function;

end package body;