library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lib_i2c;
use lib_i2c.i2c_pkg.all;

entity i2c_slave is
    generic(
        GC_clk_speed        : natural := 50_000_000; --The speed of the I_clk in Hz, simulation default: 50 MHz.
        GC_i2c_clock_speed  : natural :=    100_000  --Standard Mode 100 kHz. Fast Mode 400 kHz. Fast Mode Plus 1 MHz. High-Speed Mode 3.4 MHz.
    );
    port(
        I_clk               : in  std_logic;
        I_reset             : in  std_logic;

        I_data_ready        : in std_logic;
        O_data_valid        : in  std_logic;
        I_data              : out std_logic_vector(8 downto 0);--First send the address of course, we kind of use the same port for this stuff, the MSB is metadata: 1=address, 0=data.

        O_I2C_SDA           : out std_logic;--The 1 will mean floating up, while a zero means 0.
        I_I2C_SDA           : in  std_logic;
        I_I2C_SCL           : in  std_logic
    );
end entity i2c_slave;