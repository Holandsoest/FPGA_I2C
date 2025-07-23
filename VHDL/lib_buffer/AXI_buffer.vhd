--This is a full-handshake AXI buffer.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_buffer is
    generic(
        GC_data_width : natural := 32--The width of the data bus.
    );
    port(
        I_clk            : in  std_logic;
        I_reset          : in  std_logic;

        --Data in interface
        O_data_in_ready  : out std_logic;
        I_data_in_valid  : in  std_logic;
        I_data_in        : in  std_logic_vector(GC_data_width-1 downto 0);

        --Data out interface
        I_data_out_ready : in  std_logic;
        O_data_out_valid : out std_logic;
        O_data_out       : out std_logic_vector(GC_data_width-1 downto 0)
    );
end entity AXI_buffer;

architecture AXI_buffer_RTL of AXI_buffer is
    signal S_ihasdata : std_logic; -- Internal signal to indicate if data is available.
begin
    process(I_clk, I_reset)
    begin
        if I_reset = '1' then
            O_data_out <= (others => '0');
            S_ihasdata <= '0';
        elsif rising_edge(I_clk) then

            -- A more comprehensive statement would be as below, but it would require `i_hasdata` to be a variable.
            -- if S_ihasdata = '1' and I_data_out_ready = '1' then -- The next block received the data.
            --     S_ihasdata <= '0';
            -- end if;
            -- if S_ihasdata = '0' and I_data_in_valid = '1' then -- We store the received data.
            --     O_data_out <= I_data_in;
            --     S_ihasdata <= '1';
            -- end if;

            -- But if we use a truth table then we can do it in one go: -- TODO: Check this truth table, logic changed and this may have been broken.
            --     INPUTS
            --┌────────S_ihasdata
            --│┌───────I_data_in_valid
            --││┌──────I_data_out_ready
            --│││  OUTPUTS
            --│││ ┌────O_data_out_valid
            --│││ │┌───O_data_in_ready
            --│││ ││┌──O_data_out <= I_data_in
            --│││ │││┌─S_ihasdata
            --001 0100
            --001 0100
            --010 0111
            --011 0111
            --100 1001
            --101 1110
            --110 1001
            --111 1111
            if ((S_ihasdata = '1' and I_data_out_ready = '1') or S_ihasdata = '0') and I_data_in_valid = '1' then -- TODO: new logic must be tested still.
                O_data_out <= I_data_in;
            end if;
            S_ihasdata <= I_data_in_valid or (S_ihasdata and (not I_data_out_ready)); -- We have data when we get data or when we have data and don't give it. -- TODO: This just does not work on paper, but does work in practice.

        end if;
    end process;



    --Combinatorial logic
    O_data_in_ready  <= '1' when I_reset = '0' and (S_ihasdata = '0' or I_data_out_ready = '0') else '0';
    O_data_out_valid <= '1' when I_reset = '0' and  S_ihasdata = '1'                            else '0';



end architecture AXI_buffer_RTL;