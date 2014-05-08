library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

entity Xample is
	generic (
		constant mywidth : integer := 8
	);
	port (
		clock    : in    std_logic;
		data_bus : inout std_logic_vector(mywidth-1 downto 0);
		parity   :   out std_logic
	);
end Xample;

architecture asdf of Xample is
begin
	--data_bus <= (others => '0');
	process (clock)
		variable p : bit;
		variable i : integer;
	begin
		if rising_edge(clock) then
			parity <= '0';
--			for i in mywidth-1 to 0 loop
--				p := p xor to_bit(data_bus(i));
--			end loop;
--			parity <= p;
		end if;
	end process;
end asdf;

--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use ieee.math_real.log2;
--use ieee.math_real.ceil;
--
--entity EusKase is
--end EusKase;
--
--architecture asdf of EusKase is
--	constant db_width : integer := 32;
--	signal clk  : std_logic := '0';
--	signal data : std_logic_vector(db_width-1 downto 0) := x"aaaa5555";
--	signal par  : std_logic := '0';
--	constant other_width : integer := integer(ceil(log2(1300.0)));
--	signal mycounter : unsigned(other_width-1 downto 0);
--begin
--	pgen : entity work.Xample
--		generic map (
--			mywidth => db_width
--		)
--		port map (
--			clock    => clk,
--			data_bus => data,
--			parity   => par
--		);
--	process begin
--		clk <= '0';
--		data <= (others => '0');
--		wait for 10 ns;
--		clk <= '1';
--		data <= x"12345678";
--		wait for 10 ns;
--		clk <= '0';
--		wait for 10 ns;
--		clk <= '1';
--		data <= x"87654321";
--		wait for 10 ns;
--		clk <= '0';
--		wait;
--	end process;
--end asdf;
