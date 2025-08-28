library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lib_i2c;
use lib_i2c.i2c_pkg.all;

entity i2c_slave is
    generic(
        GC_clk_frequency    : natural := 50_000_000; --The speed of the I_clk in Hz, simulation default: 50 MHz.
        GC_i2c_clk_frequency: natural :=    100_000; --Standard Mode 100 kHz. Fast Mode 400 kHz. Fast Mode Plus 1 MHz. High-Speed Mode 3.4 MHz.
        GC_i2c_address   : std_logic_vector(7 downto 0) := x"00"
    );
    port(
        I_clk                 : in  std_logic;
        I_reset               : in  std_logic;
      
        I_data_out_ready      : in  std_logic;
        O_data_out_valid      : out std_logic;
        O_data_out            : out std_logic_vector(7 downto 0);
      
        O_data_response_ready : out std_logic;
        I_data_response_valid : in  std_logic;
        I_data_response       : in  std_logic_vector(9 downto 0);
      
        O_I2C_SDA             : out std_logic;--The 1 will mean floating up, while a zero means 0.
        I_I2C_SDA             : in  std_logic;
        I_I2C_SCL             : in  std_logic
    );
end entity i2c_slave;

architecture i2c_slave_RTL of i2c_slave is
    constant C_i2c_clock_divider      : natural := (GC_clk_frequency / GC_i2c_clk_frequency);--WARNING: There is unsafety here, if the clock is not a multiple of the i2c clock, then it will not work. Use MATH lib.
    constant C_i2c_clock_divider_half : natural := C_i2c_clock_divider / 2;

    -- Incoming
    type T_i2c_state is (not_started,  started, started_not_ours, started_ours);
    signal S_i2c_state              : T_i2c_state; 
    signal S_i2c_incoming_data      : std_logic_vector(7 downto 0);
    signal S_i2c_incoming_data_flip : std_logic;
    signal S_i2c_incoming_data_counter : natural range 0 to 8;--counts at what part of data it is 8:ack/nack, 7-0: msb-lsb data. It increments at Rising edge of SCL&clk
    signal S_i2c_inactivity_counter : natural range 0 to C_i2c_clock_divider_half+1;

    -- Address_match_response
    signal S_i2c_sda_address_match : std_logic;
    signal S_i2c_sda_data_match    : std_logic;
    signal S_i2c_sda_response      : std_logic;
    signal S_responding            : std_logic_vector(1 downto 0);  -- "00" when NOT "responding" with `S_i2c_sda_response`, it stops the slave from listening from its own SDA influence.
begin

    --This process turn all the SCL,SDA data into: A state, and a data-register that should be processed when flip changes state.
    Incoming: process(I_clk, I_reset)
        --These are only here for abstraction reasons, only read and THEN write to them ONCE per clk.
        variable V_previous_I_I2C_SCL : std_logic; -- To detect rising edge of SCL.
    begin
        if I_reset = '1' then
            S_i2c_state                 <= not_started;
            S_i2c_incoming_data         <= (others => '0');
            S_i2c_incoming_data_flip    <= '0';
            S_i2c_incoming_data_counter <=  0;
            S_i2c_inactivity_counter    <= C_i2c_clock_divider_half+1;

            V_previous_I_I2C_SCL        := '1'; -- Initialize previous SCL state

        elsif rising_edge(I_clk) then
            if I_I2C_SCL = '1' and V_previous_I_I2C_SCL = '0' then --Rising edge* of SCL
                V_previous_I_I2C_SCL     := I_I2C_SCL;
                S_i2c_inactivity_counter <= 0;

                if S_i2c_state = not_started then
                    S_i2c_state <= started;
                end if;
                
                case S_i2c_incoming_data_counter is
                    when 0 =>   S_i2c_incoming_data(7) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 1;
                    when 1 =>   S_i2c_incoming_data(6) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 2;
                    when 2 =>   S_i2c_incoming_data(5) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 3;
                    when 3 =>   S_i2c_incoming_data(4) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 4;
                    when 4 =>   S_i2c_incoming_data(3) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 5;
                    when 5 =>   S_i2c_incoming_data(2) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 6;
                    when 6 =>   S_i2c_incoming_data(1) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 7;
                    when 7 =>   S_i2c_incoming_data(0) <= I_I2C_SDA;    S_i2c_incoming_data_counter <= 8;
                        if S_i2c_state = started then--If we have not have started yet, then this is an address byte.
                            if S_i2c_incoming_data = GC_i2c_address then--Note down if it is our address.
                                S_i2c_state <= started_ours;
                            else
                                S_i2c_state <= started_not_ours;
                            end if;
                        elsif S_i2c_state = started_ours and S_responding = "00" then--If it is ours then send it, unless we are talking, then we should not listen.
                            S_i2c_incoming_data_flip <= not S_i2c_incoming_data_flip;--Send this data up and away to be processed.
                        end if;
                        
                    when others => S_i2c_incoming_data_counter <= 0;-- this happens when ack/nack, and here we prepare for the MSB of the next data also.
                end case;

            elsif I_I2C_SCL = '0' then
                V_previous_I_I2C_SCL     := '0';
                S_i2c_inactivity_counter <= 0;

            elsif S_i2c_inactivity_counter /= C_i2c_clock_divider_half+1 then
                S_i2c_inactivity_counter <= S_i2c_inactivity_counter +1;

            else--S_i2c_inactivity_counter = C_i2c_clock_divider_half+1
                S_i2c_state <= not_started;

            end if;--rising_edge(I_I2C_SCL)
        end if;--rising_edge(I_clk)
    end process Incoming;

    --That change in our signal data must be send up to the buffers
    Incoming_sender: process (I_clk, I_reset)
        variable V_ihasdata_out  : boolean;
        variable V_previous_flip : std_logic;
    begin
        if I_reset = '1' then
            O_data_out_valid      <= '0';
            O_data_out            <= (others=>'0');

            V_ihasdata_out        := FALSE;
            V_previous_flip       := '0';
        elsif rising_edge(I_clk) then
            if V_previous_flip /= S_i2c_incoming_data_flip and not V_ihasdata_out then
                V_previous_flip := S_i2c_incoming_data_flip;
                O_data_out      <= S_i2c_incoming_data;
                O_data_out_valid<= '1';
                V_ihasdata_out  := TRUE;
            elsif V_ihasdata_out and I_data_out_ready = '1' then
                O_data_out_valid<= '0';
                V_ihasdata_out  := FALSE;
            end if;
        end if;
    end process Incoming_sender;


    --Then the buffers SEND back behavior to mimic on the I2C bus.
    O_I2C_SDA <= S_i2c_sda_address_match and S_i2c_sda_data_match and S_i2c_sda_response;
    Response: process (I_clk, I_reset)
        variable V_last_state         : T_i2c_state;-- To detect if our address is called for ACK.
        variable V_previous_I_I2C_SCL : std_logic;  -- To detect falling edge of SCL.

        variable V_data     : std_logic_vector (7 downto 0);

        variable V_data_match_ack : boolean;

        variable V_previous_data_response_ready : std_logic;
    begin
        if I_reset = '1' then
            O_data_response_ready   <= '0';
            V_previous_data_response_ready := '0';

            S_i2c_sda_address_match <= '1';
            S_i2c_sda_data_match    <= '1';
            S_i2c_sda_response      <= '1';
            S_responding            <= "00";

            V_last_state := not_started;
            V_previous_I_I2C_SCL := '0';

            V_data_match_ack := false;

        elsif rising_edge(I_clk) then
            if V_previous_I_I2C_SCL /= I_I2C_SCL and I_I2C_SCL = '0' then --falling edge*(I_I2C_SCL)
                V_previous_I_I2C_SCL := I_I2C_SCL;


                -- respond with ACK at an address hit
                if V_last_state /= S_i2c_state then
                    if S_i2c_state = started_ours then
                        S_i2c_sda_address_match <= '0';
                    else
                        S_i2c_sda_address_match <= '1';   
                    end if;
                    V_last_state := S_i2c_state;
                else
                    S_i2c_sda_address_match <= '1';
                end if;


                -- respond with ACK at an internal data hit
                if S_i2c_state = started_ours and S_i2c_incoming_data_counter = 8 and V_data_match_ack then
                    V_data_match_ack := false;
                    S_i2c_sda_data_match    <= '0';
                else
                    S_i2c_sda_data_match    <= '1';
                end if;


                -- if we have data then send it
                if S_responding /= "00" then
                    case S_i2c_incoming_data_counter is
                        when 0 =>      S_i2c_sda_response <= V_data(7);
                        when 1 =>      S_i2c_sda_response <= V_data(6);
                        when 2 =>      S_i2c_sda_response <= V_data(5);
                        when 3 =>      S_i2c_sda_response <= V_data(4);
                        when 4 =>      S_i2c_sda_response <= V_data(3);
                        when 5 =>      S_i2c_sda_response <= V_data(2);
                        when 6 =>      S_i2c_sda_response <= V_data(1);
                        when 7 =>      S_i2c_sda_response <= V_data(0);    S_responding <= "10";
                        when others => S_i2c_sda_response <= '1';       if S_responding  = "10" then S_responding <= "00"; end if;
                    end case;
                else
                    S_i2c_sda_response <= '1';
                end if;


            elsif V_previous_I_I2C_SCL /= I_I2C_SCL then --rising edge*(I_I2C_SCL)
                V_previous_I_I2C_SCL := I_I2C_SCL;
            end if;--falling edge*(I_I2C_SCL)


            -- If we don't have data and there is data, and next bit is the first one.
            if S_responding = "00" and S_i2c_incoming_data_counter = 8 then
                if I_data_response_valid = '1' and V_previous_data_response_ready = '1' then
                    if I_data_response(8) = '1' then
                        S_responding <= "11";
                        V_data := I_data_response(7 downto 0);
                        V_previous_data_response_ready := '0';

                        if I_data_response(9) = '0' then--Read the ACK suppressor
                            V_data_match_ack := true;
                        end if;
                    else
                        V_previous_data_response_ready := '1';
                        V_data_match_ack := true;
                    end if;
                else
                    V_previous_data_response_ready := '1';
                end if;

            else
                V_previous_data_response_ready := '0';
            end if;
            O_data_response_ready <= V_previous_data_response_ready;
        end if;--rising_edge(I_clk)
    end process Response;

end architecture i2c_slave_RTL;
