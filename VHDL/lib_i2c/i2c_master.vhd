--This pretty boi is in charge of the entire clock dividing, state checking, and the communication. He is a bit big, but don't tell him he will cry.



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lib_i2c;
use lib_i2c.i2c_pkg.all;



entity i2c_master is
    generic(
        GC_clk_speed        : natural := 50000000; --The speed of the I_clk in Hz, simulation default: 50 MHz.
        GC_i2c_clock_speed  : natural :=   100000  --Standard Mode 100 kHz. Fast Mode 400 kHz. Fast Mode Plus 1 MHz. High-Speed Mode 3.4 MHz.
    );
    port(
        I_clk               : in  std_logic;
        I_reset             : in  std_logic;
    
        O_data_ready        : out std_logic;
        I_data_valid        : in  std_logic;
        I_data              : in  std_logic_vector(8 downto 0);--First send the address of course, we kind of use the same port for this stuff, the MSB is metadata: 1=address, 0=data.

        O_I2C_SDA           : out std_logic;--The 1 will mean floating up, while a zero means 0.
        O_I2C_SCL           : out std_logic;--The 1 will mean floating up, while a zero means 0.
        I_I2C_SDA           : in  std_logic;
        I_I2C_SCL           : in  std_logic
    );
end entity i2c_master;



architecture i2c_master_RTL of i2c_master is
    signal S_data         : std_logic_vector(8 downto 0);
    signal S_data_hasdata : std_logic;
    signal S_started      : std_logic;

    constant C_i2c_clock_divider        : natural := (GC_clk_speed * 4   / GC_i2c_clock_speed);
    constant C_i2c_clock_divider_1_4    : natural := C_i2c_clock_divider / 4 * 1;
    constant C_i2c_clock_divider_3_4    : natural := C_i2c_clock_divider / 4 * 3;
    signal S_i2c_clock_counter          : natural range 0 to C_i2c_clock_divider-1;
    signal S_i2c_data_counter           : natural range 0 to 9;
    signal S_i2c_start_allowed_counter  : natural range 0 to C_i2c_clock_divider-1;
begin
    process (I_clk, I_reset) is
    begin
        if I_reset = '1' then
            S_data           <= (others => '0');
            S_data_hasdata              <= '0';

            S_i2c_clock_counter         <=  0 ;
            S_i2c_data_counter          <=  0 ;
            S_i2c_start_allowed_counter <=  0 ;
            S_started                   <= '0';
        elsif rising_edge(I_clk) then



            --SCL: Set the i2c clock
            if (S_data_hasdata = '1' or I_data_valid = '0') and S_started = '0' and S_data_hasdata = '1' and I_data_valid = '1' and S_i2c_start_allowed_counter = S_i2c_start_allowed_counter'high then
                S_i2c_clock_counter <= 1;--This line only triggers during start condition ↓
            else
                S_i2c_clock_counter <= S_i2c_clock_counter + 1;
                if      S_started = '1' and  S_i2c_clock_counter = C_i2c_clock_divider_1_4  and S_i2c_data_counter /= 9 then O_I2C_SCL <= '1';
                elsif   S_started = '1' and  S_i2c_clock_counter = C_i2c_clock_divider_3_4                              then O_I2C_SCL <= '0';
                elsif   S_started = '0' then O_I2C_SCL <= '1';
                end if;
            end if;



            --SDA: communication
            if S_started = '1' and S_i2c_clock_counter = 0 then
                case S_i2c_data_counter is
                    when  0 => O_I2C_SDA <= S_data(7);
                    when  1 => O_I2C_SDA <= S_data(6);
                    when  2 => O_I2C_SDA <= S_data(5);
                    when  3 => O_I2C_SDA <= S_data(4);
                    when  4 => O_I2C_SDA <= S_data(3);
                    when  5 => O_I2C_SDA <= S_data(2);
                    when  6 => O_I2C_SDA <= S_data(1);
                    when  7 => O_I2C_SDA <= S_data(0);
                    when  9 =>
                        O_I2C_SDA <= '1';
                        S_data_hasdata <= '0';                      --We exhausted this buffer
                        S_started <= I_data_valid and not I_data(8);--Stops when there is no data in the next buffer ready, or when it is another address.
                        S_i2c_start_allowed_counter <= 0;
                    when others => O_I2C_SDA <= '1';--(8:The slave responds with ACK='0', this is also the default state)--WARNING TODO NACK is not handled
                end case;
                S_i2c_data_counter <= S_i2c_data_counter + 1;
                

            --Get data if I have none
            elsif S_data_hasdata = '0' and I_data_valid     = '1' then
                S_data_hasdata <= '1';
                S_data <= I_data;


            --Start condition, when we haven't started yet, and we have 2 or more data to send.
            elsif S_started = '0' and S_data_hasdata = '1' and I_data_valid = '1' then
                if  S_i2c_start_allowed_counter = S_i2c_start_allowed_counter'high then
                    S_started <= '1';
                    O_I2C_SDA <= '0';
                    --This line activates a special SCL state as it also resets the S_i2c_clock_counter
                    S_i2c_start_allowed_counter <= 0;
                elsif I_I2C_SDA = '1' and I_I2C_SCL = '1' then
                    S_i2c_start_allowed_counter <= S_i2c_start_allowed_counter + 1;
                else
                    S_i2c_start_allowed_counter <= 0;
                end if;
            end if;
        end if;
    end process;
    --Combinatorial logic
    O_data_ready <= '1' when I_reset = '0' and S_data_hasdata = '0' and (S_started = '0' or S_i2c_clock_counter /= 0) else '0';
end architecture i2c_master_RTL;