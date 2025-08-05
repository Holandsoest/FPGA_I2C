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

            if S_ihasdata = '1' and I_data_out_ready = '1' and I_data_in_valid = '1' then-- We no longer have data + we store the received data and we now have data.
                O_data_out <= I_data_in;
            elsif S_ihasdata = '1' and I_data_out_ready = '1' then -- We no longer have data.
                S_ihasdata <= '0';
            elsif S_ihasdata = '0' and I_data_in_valid = '1' then -- we store the received data and we now have data.
                O_data_out <= I_data_in;
                S_ihasdata <= '1';
            end if;

        end if;
    end process;

    --Combinatorial logic
    O_data_in_ready  <= '1' when I_reset = '0' and (S_ihasdata = '0' or I_data_out_ready = '1') else '0';
    O_data_out_valid <= '1' when I_reset = '0' and  S_ihasdata = '1'                            else '0';

end architecture AXI_buffer_RTL;