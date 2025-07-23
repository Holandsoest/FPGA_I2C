library ieee;
use ieee.std_logic_1164.all;

entity tb_clock_generator is
	generic(
		G_clock_frequency : positive := 50000000
	);
	port(
		-- I_reset : in std_logic;
		O_clk   : out std_logic
	);
end entity tb_clock_generator;

architecture tb_clock_generator_RTL of tb_clock_generator is
	constant C_half_period : time := 1 sec / G_clock_frequency / 2;
begin
	process is
	begin
		O_clk <= '0';
		-- wait until I_reset = '0';
		wait for C_half_period;
		O_clk <= '1';
		wait for C_half_period;
	end process;

end architecture tb_clock_generator_RTL;