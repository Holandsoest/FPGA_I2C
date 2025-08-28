-- vhdl-linter-disable type-resolved
library ieee, lib_i2c, lib_tb;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lib_i2c.all;
use lib_tb.all;

entity i2c_tb is
end entity i2c_tb;

architecture i2c_tb_RTL of i2c_tb is
    signal error_count       : natural := 0;
    signal stimulus_M1_done  : boolean := false;

    constant C_clk_frequency : positive := 100_000_000; -- 100 MHz clock
    constant C_clk_period    : time := 1 sec / C_clk_frequency;
    signal clk               : std_logic;
    signal reset             : std_logic := '1';

    constant C_i2c_clk_frequency : natural  := 1_000_000; -- Standard Mode 100 kHz -- Fast Mode 400 kHz -- Fast Mode Plus 1 MHz -- High-Speed Mode 3.4 MHz.
    constant C_i2c_clk_period    : time := 1 sec / C_i2c_clk_frequency;
    signal I2C_SDA           : std_logic;
    signal I2C_SCL           : std_logic;
    
    signal M1_in_ready  : std_logic;
    signal M1_in_valid  : std_logic;
    signal M1_in_data   : std_logic_vector(9 downto 0);
    signal M1_out_ready : std_logic;
    signal M1_out_valid : std_logic;
    signal M1_out_data  : std_logic_vector(8 downto 0);
    signal M1_SCL       : std_logic;
    signal M1_SDA       : std_logic;
    
    signal S1_in_ready  : std_logic;
    signal S1_in_valid  : std_logic;
    signal S1_in_data   : std_logic_vector(8 downto 0);
    signal S1_out_ready : std_logic;
    signal S1_out_valid : std_logic;
    signal S1_out_data  : std_logic_vector(7 downto 0);
    signal S1_SDA       : std_logic;

    type S1_buff is array (natural range <>) of std_logic_vector(8 downto 0);
    signal RS1_responses          : S1_buff(0 to 1);--0 will be send first
begin
    I2C_SCL <= M1_SCL;
    I2C_SDA <= M1_SDA and S1_SDA;

    clock_generator: entity lib_tb.tb_clock_generator
        generic map(
            G_clock_frequency => C_clk_frequency
        )
        port map(
            O_clk => clk
        );
    M1: entity lib_i2c.i2c_master
        generic map(
            GC_clk_frequency      => C_clk_frequency,
            GC_i2c_clk_frequency  => C_i2c_clk_frequency
        )
        port map(
            I_clk               => clk,
            I_reset             => reset,
    
            O_data_in_ready     => M1_in_ready,
            I_data_in_valid     => M1_in_valid,
            I_data_in           => M1_in_data,
            I_data_out_ready    => M1_out_ready,
            O_data_out_valid    => M1_out_valid,
            O_data_out          => M1_out_data,

            O_I2C_SDA           => M1_SDA,
            O_I2C_SCL           => M1_SCL,
            I_I2C_SDA           => I2C_SDA,
            I_I2C_SCL           => I2C_SCL
        );
    S1: entity lib_i2c.i2c_slave
        generic map(
            GC_clk_frequency    => C_clk_frequency,
            GC_i2c_clk_frequency=> C_i2c_clk_frequency,
            GC_i2c_address      => x"10"
        )
        port map(
            I_clk                 => clk,
            I_reset               => reset,
        
            I_data_out_ready      => S1_out_ready,
            O_data_out_valid      => S1_out_valid,
            O_data_out            => S1_out_data, 
            O_data_response_ready => S1_in_ready,
            I_data_response_valid => S1_in_valid,
            I_data_response       => S1_in_data,
        
            O_I2C_SDA             => S1_SDA,
            I_I2C_SDA             => I2C_SDA,
            I_I2C_SCL             => I2C_SCL
        );
    stimulus_M1: process
        procedure submit is begin
            M1_in_valid <= '1';
            wait until M1_in_ready = '1' and rising_edge(clk) for C_i2c_clk_period*100;
            if not (M1_in_ready = '1' and rising_edge(clk)) then error_count <= error_count + 1; end if;
            assert  M1_in_ready = '1' and rising_edge(clk) report "System never accepted the data in > 100 i2c-clock-cycles." severity failure;
            M1_in_valid <= '0';
        end procedure submit;
        procedure que_address(
            address : in std_logic_vector(7 downto 0)
        ) is begin
            M1_in_data(9 downto 8) <= "01"; -- Address
            M1_in_data(7 downto 0) <= address;
            submit;
        end procedure que_address;
        procedure que_data(
            data1 : in std_logic_vector(7 downto 0)
        ) is begin
            M1_in_data(9 downto 8) <= "00"; -- Data
            M1_in_data(7 downto 0) <= data1;
            submit;
        end procedure que_data;
        procedure que_listen is begin
            M1_in_data(9 downto 8) <= "10"; -- Listen for slave response
            M1_in_data(7 downto 0) <= (others => '1'); -- No data
            submit;
        end procedure que_listen;
    begin
        reset <= '1';
        wait for C_clk_period * 10;
        reset <= '0';
        M1_out_ready <= '1';

        que_address(x"00");
        que_data   (x"01");
        que_data   (x"02");
        que_data   (x"03");
        que_data   (x"04");
        que_data   (x"05");
        que_data   (x"06");
        que_data   (x"07");
        que_data   (x"08");
        que_data   (x"09");
        que_data   (x"0A");
        que_data   (x"0B");
        que_data   (x"0C");
        que_data   (x"0D");
        que_data   (x"0E");
        que_data   (x"0F");
        que_listen;--(x"0E");
        que_listen;--(x"0F");

        que_address(x"10");
        que_data   (x"11");
        que_data   (x"12");
        que_data   (x"13");
        que_data   (x"14");
        que_data   (x"15");
        que_data   (x"16");
        que_data   (x"17");
        que_data   (x"18");
        que_data   (x"19");
        que_data   (x"1A");
        que_data   (x"1B");
        que_data   (x"1C");
        que_data   (x"1D");
        que_listen;--(x"1E");
        que_listen;--(x"1F");

        que_address(x"20");
        que_data   (x"21");
        que_data   (x"22");
        que_data   (x"23");
        que_data   (x"24");
        que_data   (x"25");
        que_data   (x"26");
        que_data   (x"27");
        que_data   (x"28");
        que_data   (x"29");
        que_data   (x"2A");
        que_data   (x"2B");
        que_data   (x"2C");
        que_data   (x"2D");
        que_data   (x"2E");
        que_data   (x"2F");
        
        que_address(x"30");
        que_address(x"40");
        stimulus_M1_done <= true;

        --flush the queue
        wait until M1_in_valid = '0' and M1_in_ready = '1' and rising_edge(clk) for C_i2c_clk_period*100;
        wait for C_i2c_clk_period *10;

        report "Stimulus M1 done." severity failure;
        wait;
    end process stimulus_M1;

    response_S1: process (clk, reset)
        variable V_responses_ihasdata : natural range 0 to RS1_responses'high+1;
        variable V_ihasdata           : boolean;
    begin
        if reset = '1' then
            S1_in_valid <= '0';
            S1_in_data  <= (others=>'0');
            S1_out_ready <= '0';

            RS1_responses          <= (others=>(others=>'0'));
            V_responses_ihasdata := 0;
            V_ihasdata           := false;
        elsif rising_edge(clk) then

            --Capture new data
            if S1_out_valid = '1' and V_responses_ihasdata = 0 then--if new data available, the buffer is empty
                --Set the new V_responses_ihasdata value
                case S1_out_data is
                                                                                                                                      --┌ 0: only send ACK, but do not send/schedule data,  1: Send ACK and also send data            (discussed below this line).
                                                                                                                                      --│    ┌┬ This is the data that will be send, contents only matter when it is preceded with '1' (discussed above this line).
                                                                                                                                      --│    ││                                                          ┌ The amount of data you assigned as a natural
                    when x"11"                                                                                  => RS1_responses(0) <= '0'&x"00";                                V_responses_ihasdata := 1;
                    when x"12" | x"13" | x"14" | x"15" | x"16" | x"17" | x"18" | x"19" | x"1A" | x"1B" | x"1C"  => RS1_responses(0) <= '0'&x"00";                                V_responses_ihasdata := 1;
                    when x"1D"                                                                                  => RS1_responses(0) <= '1'&x"AB"; RS1_responses(1) <= '1'&x"CD"; V_responses_ihasdata := 2;
                    when others                                                                                 => NULL;--This is not a response and results into a NACK.
                end case;
                S1_in_valid <= '0';
            
            --Send data
            elsif (    V_ihasdata) and S1_in_ready = '1' and V_responses_ihasdata /= 0 then--If we have data out that is captured and there is data left to send
                --Put new data on the output, and move the buffer.
                S1_in_data <= RS1_responses(0);
                for i in RS1_responses'low to RS1_responses'high-1 loop
                    RS1_responses(i) <= RS1_responses(i+1);
                end loop;
                V_responses_ihasdata := V_responses_ihasdata -1;

            elsif (    V_ihasdata) and S1_in_ready = '1'                               then--If we have data out that is captured
                S1_in_data <= '0'&x"00";
                V_ihasdata := false;

            elsif (not V_ihasdata) and                       V_responses_ihasdata /= 0 then--If we don't have data out that is captured and there is data left to send
                --Put new data on the output, and move the buffer.
                S1_in_data <= RS1_responses(0);
                for i in RS1_responses'low to RS1_responses'high-1 loop
                    RS1_responses(i) <= RS1_responses(i+1);
                end loop;
                V_responses_ihasdata := V_responses_ihasdata -1;
                V_ihasdata := true;
            end if;

            --Adjust ready and valid
            if V_responses_ihasdata = 0 then
                S1_out_ready <= '1';
            else
                S1_out_ready <= '0';
            end if;
            if V_ihasdata then
                S1_in_valid  <= '1';
            else
                S1_in_valid  <= '0';
            end if;
        end if;--rising_edge(clk)
    end process response_S1;
end architecture i2c_tb_RTL;
