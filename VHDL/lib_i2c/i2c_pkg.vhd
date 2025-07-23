library ieee;
use ieee.std_logic_1164.all;
package i2c_pkg is
    type i2c_clock_speed is (i2c_clock_speed_standard, i2c_clock_speed_fast, i2c_clock_speed_plus, i2c_clock_speed_high);

end package i2c_pkg;
package body i2c_pkg is
    function i2c_clock_speed_to_Hz (i2c_clock: i2c_clock_speed) return natural is
    begin
        case i2c_clock is
            when i2c_clock_speed_standard => return  100000;
            when i2c_clock_speed_fast     => return  400000;
            when i2c_clock_speed_plus     => return 1000000;
            when i2c_clock_speed_high     => return 3400000;
            when others =>                   return       0;--Hopefully this throws an error.
        end case;
    end function i2c_clock_speed_to_Hz;
end package body i2c_pkg;