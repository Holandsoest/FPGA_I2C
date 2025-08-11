-- vhdl-linter-disable type-resolved


--This pretty boi is in charge of the entire clock dividing, state checking, and the communication. He is a bit big, but don't tell him he will cry.--TODO: oh no, language.


-- ACK/NACK: If a NACK gets received, and the data is an address, then the system will attempt to resend the address 3 times, and then issue a STOP EVENT.--TODO: this whole shit.
--                                       If it is not an address, then it will just issue a STOP EVENT, since it already forgot all the previous data.   --WARNING: I AM CRYING



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lib_i2c;
use lib_i2c.i2c_pkg.all;



entity i2c_master is
    generic(
        GC_clk_frequency    : natural := 50_000_000; --The speed of the I_clk in Hz, simulation default: 50 MHz.
        GC_i2c_clk_frequency: natural :=    100_000  --Standard Mode 100 kHz. Fast Mode 400 kHz. Fast Mode Plus 1 MHz. High-Speed Mode 3.4 MHz.
    );
    port(
        I_clk               : in  std_logic;
        I_reset             : in  std_logic;
    
        O_data_in_ready     : out std_logic;
        I_data_in_valid     : in  std_logic;
        I_data_in           : in  std_logic_vector(9 downto 0);
        --"in" dictates that the data is coming from the (AXI) buffer and out trough the I2C bus.
        --Bit 9-8: Metadata, 00 = data, 01 = address, 10 = read-response, 11 = UNUSED.
        --Bit 7-0: Data bits
        I_data_out_ready    : in  std_logic;
        O_data_out_valid    : out std_logic;
        O_data_out          : out std_logic_vector(7 downto 0);
        --"out" dictates that the data is coming from the I2C bus and out trough the (AXI) buffer.
        --Bit 7-0: Data bits

        O_I2C_SDA           : out std_logic;--The 1 will mean floating up, while a zero means 0.
        O_I2C_SCL           : out std_logic;--The 1 will mean floating up, while a zero means 0.
        I_I2C_SDA           : in  std_logic;
        I_I2C_SCL           : in  std_logic
    );
end entity i2c_master;



architecture i2c_master_RTL of i2c_master is
    --SCL
    constant C_i2c_clock_divider        : natural := (GC_clk_frequency / GC_i2c_clk_frequency);--WARNING: There is unsafety here, if the clock is not a multiple of the i2c clock, then it will not work. Use MATH lib.
    constant C_i2c_clock_divider_1_4    : natural := C_i2c_clock_divider / 4 * 1;
    constant C_i2c_clock_divider_3_4    : natural := C_i2c_clock_divider / 4 * 3;
    signal S_i2c_clock_counter          : natural range 0 to C_i2c_clock_divider-1;

    --SDA
    signal S_i2c_data_counter_next      : natural range 0 to 11;
    signal S_i2c_data_counter_this      : natural range 0 to 11;

    --Full AXI buffers
    signal S_data_in         : std_logic_vector(9 downto 0);
        --"in" dictates that the data is coming from the (AXI) buffer and out trough the I2C bus.
        --Bit 9-8: Metadata, 00 = data, 01 = address, 10 = read-response, 11 = UNUSED.
        --Bit 7-0: Data bits
    signal S_data_in_hasdata : std_logic;
    signal S_data_out        : std_logic_vector(7 downto 0); -- TODO: Responses are not implemented yet.
        --"out" dictates that the data is coming from the I2C bus and out trough the (AXI) buffer.
        --Bit 7-0: Data bits
    signal S_data_out_hasdata: std_logic; -- TODO: Responses are not implemented yet.

    signal S_start_ready : std_logic; -- send by SDA process, shows the data is ready to start the I2C communication, and requests the SCL process to set the clock.
    signal S_start_done  : std_logic; -- send by SCL process in response, the SDA can now set S_started to begin.
    signal S_start_timer : natural range 0 to C_i2c_clock_divider/2; -- When ^ is set, this timer will count down to 0 if it gets there and no pulses where captured then it can truly start.
    signal S_started     : std_logic;

    signal S_latest_device_address : std_logic_vector(7 downto 0);--The latest device address that was sent, used for the ACK/NACK. -- TODO: ACK/NACK is not implemented yet.

begin

    --SCL: Set the i2c clock
    SCL: process (I_clk, I_reset) is
    begin
        if I_reset = '1' then
            O_I2C_SCL                   <= '1';
            S_i2c_clock_counter         <=  0 ;
            S_start_done                <= '0';
        elsif rising_edge(I_clk) then

            if S_start_ready = '1' and (S_i2c_clock_counter = C_i2c_clock_divider_1_4 or S_i2c_clock_counter = C_i2c_clock_divider-2) then
                S_i2c_clock_counter <= C_i2c_clock_divider-2; -- This will give the SDA enough time to start the start condition 2 clock cycles from now.
                S_start_done <= '1'; --We can start the SDA process.
                O_I2C_SCL <= '1';
            else -- TODO: is the clock really nesseary if we dont have data on the axi-bus? We can save some power here.
                S_start_done <= '0'; --We are not starting.

                -- S_i2c_clock_counter++, and wrap around.
                if S_i2c_clock_counter = C_i2c_clock_divider-1 then S_i2c_clock_counter <= 0; else S_i2c_clock_counter <= S_i2c_clock_counter + 1; end if;

                -- SCL behavior
                if      S_started = '1' and  S_i2c_clock_counter = C_i2c_clock_divider_1_4 and S_i2c_data_counter_this /= 10 then O_I2C_SCL <= '1';
                elsif   S_started = '1' and  S_i2c_clock_counter = C_i2c_clock_divider_3_4                                   then O_I2C_SCL <= '0';
                elsif   S_started = '0' then O_I2C_SCL <= '1';
                end if;
            end if;

        end if;
    end process SCL;

    --SDA: communication
    SDA: process (I_clk, I_reset) is
    begin
        if I_reset = '1' then
            S_data_in          <= (others => '0');
            S_data_in_hasdata  <= '0';

            S_i2c_data_counter_next <=  0 ;
            S_i2c_data_counter_this <=  0 ;

            S_start_ready      <= '0';
            S_start_timer      <= C_i2c_clock_divider/2;
            S_started          <= '0';

            O_I2C_SDA          <= '1';
        elsif rising_edge(I_clk) then


            if S_started = '1' and S_i2c_clock_counter = 0 then
                S_i2c_data_counter_this <= S_i2c_data_counter_next;
                case S_i2c_data_counter_next is --this is the new "*this"
                    when  0 => -- Start condition, can be skipped if data is concurrent.
                        O_I2C_SDA <= '0';
                        S_i2c_data_counter_next <= 1;
                    when  1 => -- MSB
                        O_I2C_SDA <= S_data_in(7);
                        S_i2c_data_counter_next <= 2;
                    when  2 =>
                        O_I2C_SDA <= S_data_in(6);
                        S_i2c_data_counter_next <= 3;
                    when  3 =>
                        O_I2C_SDA <= S_data_in(5);
                        S_i2c_data_counter_next <= 4;
                    when  4 =>
                        O_I2C_SDA <= S_data_in(4);
                        S_i2c_data_counter_next <= 5;
                    when  5 =>
                        O_I2C_SDA <= S_data_in(3);
                        S_i2c_data_counter_next <= 6;
                    when  6 =>
                        O_I2C_SDA <= S_data_in(2);
                        S_i2c_data_counter_next <= 7;
                    when  7 =>
                        O_I2C_SDA <= S_data_in(1);
                        S_i2c_data_counter_next <= 8;
                    when  8 => --LSB
                        O_I2C_SDA <= S_data_in(0);
                        S_i2c_data_counter_next <= 9;
                    when  9 => -- ACK/NACK -- TODO: Read and respond at i2c_clk_fall_event
                        O_I2C_SDA <= '1';
                        S_i2c_data_counter_next <= 10;
                    when 10 => -- Wait for interrupts at target to finish
                        O_I2C_SDA <= '1';
                        -- Transition →0 & →1 explained below, they require being one clock cycle earlier, to allow our system to grab the next data.
                        S_data_in_hasdata <= '0';--We exhausted this buffer
                    when others => 
                        O_I2C_SDA <= '1';
                        S_i2c_data_counter_next <=  0;
                end case;


            -- Transition 10→0 and 10→1, that is processed just before the next i2c clock cycle.
            elsif S_started = '1' and S_i2c_clock_counter = C_i2c_clock_divider-1 and S_i2c_data_counter_this = 10 then
                if S_data_in_hasdata = '1' and S_data_in(9 downto 8) /= "01" then
                    S_i2c_data_counter_next <= 1; -- If we do have data and it is not an address, We can continue with next piece of data.
                elsif S_data_in_hasdata = '1' and S_data_in(9 downto 8) = "01" then
                    S_i2c_data_counter_next <= 0; -- If we do have data and it is an address, We can continue with the start condition.
                else
                    S_i2c_data_counter_next <= 0;
                    S_started               <='0';-- If we don't have data, we move to the start condition, but wait for the next data.
                end if;


            --Get data if I have none, but only accept an address if we have not started yet, and if we did start then we accept any.
            elsif S_data_in_hasdata = '0' and I_data_in_valid = '1' and (S_started = '1' or I_data_in(9 downto 8) = "01") then
                S_data_in <= I_data_in;
                S_data_in_hasdata <= '1';
                if I_data_in(9 downto 8) = "01" then    S_start_ready <= '1'; --Request SCL process to restart the clock, if it is an address.
                else                                    S_start_ready <= '0'; --Otherwise we don't need to restart the clock.
                end if;


            -- We are ready to start, but is the bus free?
            elsif S_start_ready = '1' and S_start_done = '1' then -- Response on "Request SCL process to restart the clock" comment from the SCL process.
                if S_start_timer = 0 and I_I2C_SDA = '1' and I_I2C_SCL = '1' then
                    S_start_ready <= '0';
                    S_started     <= '1';
                    S_start_timer <= C_i2c_clock_divider/2; --  Reset the timer, so that it can count down to 0.
                elsif I_I2C_SDA = '1' and I_I2C_SCL = '1' then
                    S_start_timer <= S_start_timer - 1; -- Count down the timer, so that it can count down to 0.
                else
                    S_start_timer <= C_i2c_clock_divider/2; --  Reset the timer, so that it can count down to 0.
                end if;
            end if;
        end if;--rising_edge(I_clk)
    end process SDA;


    --Combinatorial logic
    O_data_in_ready <= '1' when I_reset = '0' and S_data_in_hasdata = '0' and (S_started = '0' or S_i2c_clock_counter /= 0) else '0';


end architecture i2c_master_RTL;