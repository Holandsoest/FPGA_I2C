-- vhdl-linter-disable type-resolved
--This pretty boi is in charge of the entire clock dividing, state checking, and the communication. He is a bit big, but don't tell him he will cry.



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
    constant C_i2c_clock_divider        : natural := (GC_clk_frequency * 4   / GC_i2c_clk_frequency);
    constant C_i2c_clock_divider_1_4    : natural := C_i2c_clock_divider / 4 * 1;
    constant C_i2c_clock_divider_3_4    : natural := C_i2c_clock_divider / 4 * 3;
    signal S_i2c_clock_counter          : natural range 0 to C_i2c_clock_divider-1;

    --SDA
    signal S_i2c_data_counter_next      : natural range 0 to 10;
    signal S_i2c_data_counter_this      : natural range 0 to 10;


    signal S_data_in         : std_logic_vector(9 downto 0);
        --"in" dictates that the data is coming from the (AXI) buffer and out trough the I2C bus.
        --Bit 9-8: Metadata, 00 = data, 01 = address, 10 = read-response, 11 = UNUSED.
        --Bit 7-0: Data bits
    signal S_data_in_hasdata : std_logic;
    signal S_data_out        : std_logic_vector(7 downto 0); -- TODO: Responces are not implemented yet.
        --"out" dictates that the data is coming from the I2C bus and out trough the (AXI) buffer.
        --Bit 7-0: Data bits
    signal S_data_out_hasdata: std_logic; -- TODO: Responces are not implemented yet.

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

            if S_start_ready = '1' then
                S_i2c_clock_counter <= C_i2c_clock_divider-1; -- This will give the SDA enough time to start the start condition 1 clock cycle from now.
                S_start_done <= '1'; --We can start the SDA process.
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
                        S_data_in_hasdata <= '0';--We exhausted this buffer
                    when 10 => -- Wait for interrupts at target to finish
                        O_I2C_SDA <= '1';
                        if S_data_in_hasdata = '1' and S_data_in(9 downto 8) /= "01" then
                            S_i2c_data_counter_next <=  1; -- We can continue with next piece of data. 
                        else
                            S_i2c_data_counter_next <=  0; -- We stop after not having data or when getting a new address.
                            S_started          <= '0';
                        end if;

                    when others =>
                        O_I2C_SDA <= '1';
                        report "i2c_master: S_i2c_data_counter_next is out of bounds, this should never happen." severity failure;
                        S_i2c_data_counter_next <=  0;
                        S_started          <= '0';
                end case;

            --Get data if I have none, but only accept an address if we have not started yet, and if we did 
            elsif S_data_in_hasdata = '0' and I_data_in_valid = '1' and (S_started = '1' xor I_data_in(8) = '1') then--TODO: imnot seeing straight check this furture me.
                S_data_in <= I_data_in;
                S_data_in_hasdata <= '1';
                S_start_ready <= not S_started; --Request SCL process to restart the clock, at least when it did not start already.

            -- We are ready to start, but is the bus free?
            elsif S_start_ready = '1' and S_start_done = '1' then -- Response on ^ comment.
                if S_start_timer = 0 and I_I2C_SDA = '1' and I_I2C_SCL = '1' then
                    S_start_ready <= '0';
                    S_started     <= '1';
                    S_start_timer <= C_i2c_clock_divider/2; -- Reset the timer, so that it can count down to 0.
                elsif I_I2C_SDA = '1' and I_I2C_SCL = '1' then
                    S_start_timer <= S_start_timer - 1; -- Count down the timer, so that it can count down to 0.
                else
                    S_start_timer <= C_i2c_clock_divider/2; -- Reset the timer, so that it can count down to 0.
                end if;
            end if;
        end if;
    end process SDA;
    --Combinatorial logic
    O_data_in_ready <= '1' when I_reset = '0' and S_data_in_hasdata = '0' and (S_started = '0' or S_i2c_clock_counter /= 0) else '0';--TODO: imnot seeing straight check this furture me.
end architecture i2c_master_RTL;