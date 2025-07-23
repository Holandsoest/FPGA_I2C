--TODO: `28` is hardcoded magic number, but is defined as `C_data_width-4`. 

library ieee, lib_buffer, lib_tb;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lib_buffer.all;
use lib_tb.all;

entity AXI_buffer_tb is
end entity AXI_buffer_tb;

architecture AXI_buffer_tb_RTL of AXI_buffer_tb is

    constant C_data_width : natural := 32;
    
    constant C_clock_speed  : natural := 100_000_000; -- 100 MHz clock
    constant C_clock_period : time := 1 sec / C_clock_speed; -- Clock period

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '1';

    -- Data in interface signals
    signal data_in_ready_1buf : std_logic;
--    signal O_data_in_ready_9buf : std_logic;
    signal data_in_valid      : std_logic := '0';
    signal data_in            : std_logic_vector(C_data_width-1 downto 0) := (others => '0');

    -- Data out interface signals
    signal data_out_ready     : std_logic := '0';
    signal data_out_valid_1buf: std_logic;
--    signal O_data_out_valid_9buf: std_logic;
    signal data_out_1buf      : std_logic_vector(C_data_width-1 downto 0);
--    signal O_data_out_9buf      : std_logic_vector(C_data_width-1 downto 0);

    -- Signals for the nine buffers' routing
--    type array_data_buff9 is array (natural range <>) of std_logic_vector(C_data_width-1 downto 0);
--    signal S_buf9_ready : std_logic_vector(9 downto 0);
--    signal S_buf9_valid : std_logic_vector(9 downto 0);
--    signal S_buf9_data  : array_data_buff9(9 downto 0);
begin
    clock_generator: entity lib_tb.tb_clock_generator
        generic map(
            G_clock_frequency => 100000000 -- 100 MHz clock
        )
        port map(
            O_clk => clk
        );

    one_buffer: entity lib_buffer.AXI_buffer
        generic map(
            GC_data_width => C_data_width
        )
        port map(
            I_clk            => clk,
            I_reset          => reset,

            --Data in interface
            O_data_in_ready  => data_in_ready_1buf,
            I_data_in_valid  => data_in_valid,
            I_data_in        => data_in,

            --Data out interface
            I_data_out_ready => data_out_ready,
            O_data_out_valid => data_out_valid_1buf,
            O_data_out       => data_out_1buf
        );
--    nine_buffer: for i in 1 to 9 generate
--        bbuffer: entity lib_buffer.AXI_buffer
--            generic map(
--                GC_data_width => C_data_width
--            )
--            port map(
--                clk            => clk,
--                reset          => reset,
--
--                --Data in interface
--                O_data_in_ready  => S_buf9_ready(i-1),
--                data_in_valid  => S_buf9_valid(i-1),
--                data_in        => S_buf9_data(i-1),
--
--                --Data out interface
--                data_out_ready => S_buf9_ready(i),
--                O_data_out_valid => S_buf9_valid(i),
--                O_data_out       => S_buf9_data(i)
--            );
--    end generate nine_buffer;
--    O_data_in_ready_9buf <= S_buf9_ready(0);
--    S_buf9_valid(0)      <= data_in_valid;
--    S_buf9_data(0)       <= data_in;
--    O_data_out_9buf      <= S_buf9_data(9);
--    O_data_out_valid_9buf<= S_buf9_valid(9);
--    S_buf9_ready(9)      <= data_out_ready;

    stimuli: process is
        variable V_stimuli_test_nr : integer := 0;
        procedure input(
            p_reset   : in std_logic;
            p_valid   : in std_logic;
            p_ready   : in std_logic
        ) is begin
            V_stimuli_test_nr := V_stimuli_test_nr + 1;
            reset           <= p_reset;
            data_in_valid   <= p_valid;
            data_out_ready  <= p_ready;
            if p_reset = '1' or p_valid = '0' then 
                data_in(C_data_width-1 downto C_data_width-4) <= x"F"; -- F for fail.
            else
                data_in(C_data_width-1 downto C_data_width-4) <= x"0"; -- 0 for valid.
            end if;
            data_in(C_data_width-5 downto 0) <= std_logic_vector(to_unsigned(V_stimuli_test_nr, 28));
            wait for C_clock_period; 
        end procedure input;
    begin
        V_stimuli_test_nr := 0;
        wait until falling_edge(clk) for C_clock_period;
        -- reset, valid, ready
        input('1', '0', '0'); -- This is the initial reset. <-test 1
        input('1', '1', '1'); -- See if the reset blocks the data flow.
        input('0', '0', '0'); -- This should not move data.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 1/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 2/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 3/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 4/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 5/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 6/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 7/9. <-test 10
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 8/9.
        input('0', '0', '1'); -- No movement, because there should be nothing in the buffer 9/9.
        input('0', '1', '0'); -- Loads data into the buffer, but does not take it out.
        input('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        input('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        input('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        input('0', '1', '0'); -- Loads data into the buffer, but does not take it out. This looses data. 
        input('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        input('1', '1', '1'); -- reset destroys previous data.
        input('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously. <-test 20
        input('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
    end process stimuli;



    output_checker_1_buffer: process is
        variable V_output_checker_1_buffer_test_nr   : integer := 0;
        variable V_output_checker_1_buffer_last_data : integer := 0;
        procedure output(
            p_reset   : in std_logic;
            p_valid   : in std_logic;
            p_ready   : in std_logic
        ) is begin
            wait for C_clock_period;

            V_output_checker_1_buffer_test_nr := V_output_checker_1_buffer_test_nr + 1;
            assert reset = p_reset report "Reset mismatch, blame the test-writer, for test " & integer'image(V_output_checker_1_buffer_test_nr) severity failure;
            
            -- The x"F" is used to indicate a failure in the test, since it shouldn't be send.
            assert data_out_1buf(C_data_width-1 downto C_data_width-4) /= x"F" report "Data out buffer 1 is not valid, for test " & integer'image(V_output_checker_1_buffer_test_nr) severity failure;

            -- If there is data coming out then we trace back what the test number was, and so what the expected value is.
            if data_out_valid_1buf = '1' and V_output_checker_1_buffer_last_data /= 0 then
                assert data_out_1buf(C_data_width-5 downto 0) = std_logic_vector(to_unsigned(V_output_checker_1_buffer_last_data, 28)) report "Data out buffer 1 does not match the expected value (`" & integer'image(to_integer(unsigned(data_out_1buf(C_data_width-5 downto 0)))) & "`=`" & integer'image(V_output_checker_1_buffer_last_data) & "`), for test " & integer'image(V_output_checker_1_buffer_test_nr) severity failure;
            end if;

            -- Remove the value if the data is released.
            if data_out_valid_1buf = '1' and data_out_ready = '1' and V_output_checker_1_buffer_last_data /= 0 then
                V_output_checker_1_buffer_last_data := 0;
            end if;

            -- Assign new value if the data is set.
            if data_in_valid = '1' and data_in_ready_1buf = '1' then
                V_output_checker_1_buffer_last_data := to_integer(unsigned(data_in(C_data_width-5 downto 0)));
            end if;


        end procedure output;
    begin
        V_output_checker_1_buffer_test_nr   := 0;
        V_output_checker_1_buffer_last_data := 0;
        wait until falling_edge(clk) for C_clock_period;
        -- reset, valid, ready -- This list should match the stimuli.
        output('1', '0', '0'); -- This is the initial reset. <-test 1
        output('1', '1', '1'); -- See if the reset blocks the data flow.
        output('0', '0', '0'); -- This should not move data.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 1/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 2/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 3/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 4/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 5/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 6/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 7/9. <-test 10
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 8/9.
        output('0', '0', '1'); -- No movement, because there should be nothing in the buffer 9/9.
        output('0', '1', '0'); -- Loads data into the buffer, but does not take it out.
        output('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        output('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        output('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        output('0', '1', '0'); -- Loads data into the buffer, but does not take it out. This looses data. 
        output('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.
        output('1', '1', '1'); -- reset destroys previous data.
        output('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously. <-test 20
        output('0', '1', '1'); -- Loads data into the buffer, and takes it out. Both should work simultaneously.

        report "End of test." severity failure;
    end process output_checker_1_buffer;
end architecture AXI_buffer_tb_RTL;