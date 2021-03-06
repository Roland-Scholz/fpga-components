
library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity seg7_4 is
	port(
		addrOut		: out std_logic_vector (23 downto 0);
		seg7			: out std_logic_vector (7 downto 0);
		seg7_digit	: out std_logic_vector (3 downto 0);
		dataOut		: out std_logic_vector (7 downto 0);
		clk			: in std_logic;
		data			: in std_logic_vector (7 downto 0) := (others => '0');
		addr			: in std_logic_vector (23 downto 0) := (others => '0');
		adr			: in std_logic_vector (1 downto 0) := (others => '0');
		hexEna		: in std_logic := '0';
		addrEna		: in std_logic := '0';
		segEna		: in std_logic := '0'
	);
end seg7_4;

architecture rtl of seg7_4 is

	signal counter		: integer := 0;
	signal seg7_shift	: std_logic_vector (3 downto 0) := "0111";
	signal seg0			: std_logic_vector (7 downto 0) := "00000000";
	signal seg1			: std_logic_vector (7 downto 0) := "00000000";
	signal seg2			: std_logic_vector (7 downto 0) := "00000000";
	signal seg3			: std_logic_vector (7 downto 0) := "00000000";
	signal data0		: std_logic_vector (7 downto 0) := "00000000";
	signal data1		: std_logic_vector (7 downto 0) := "00000000";
	signal bank			: std_logic_vector (7 downto 0) := "00000000";

	function NIBBLE_TO_HEX (
		NIBBLE_IN : in std_logic_vector(3 downto 0))
		return std_logic_vector is
		variable HEX : std_logic_vector(7 downto 0);
	begin
		if 	NIBBLE_IN =  0 then HEX := "00111111";
		elsif NIBBLE_IN =  1 then HEX := "00000110";
		elsif NIBBLE_IN =  2 then HEX := "01011011";
		elsif NIBBLE_IN =  3 then HEX := "01001111";
		elsif NIBBLE_IN =  4 then HEX := "01100110";
		elsif NIBBLE_IN =  5 then HEX := "01101101";
		elsif NIBBLE_IN =  6 then HEX := "01111101";
		elsif NIBBLE_IN =  7 then HEX := "00000111";
		elsif NIBBLE_IN =  8 then HEX := "01111111";
		elsif NIBBLE_IN =  9 then HEX := "01101111";
		elsif NIBBLE_IN = 10 then HEX := "01110111";
		elsif NIBBLE_IN = 11 then HEX := "01111100";
		elsif NIBBLE_IN = 12 then HEX := "00111001";
		elsif NIBBLE_IN = 13 then HEX := "01011110";
		elsif NIBBLE_IN = 14 then HEX := "01111001";
		else							  HEX := "01110001";  
		end if;
		return std_logic_vector(HEX);
	end;	
	
begin

	
	with seg7_shift select 
	seg7 <=	not seg3 when "1110",
				not seg2 when "1101",
				not seg1 when "1011",
				not seg0 when others;
	
	process(all)
	begin			
		addrOut <= bank & data1 & data0;
		
		if adr(0) = '0' then
			dataOut <= data0;
		else
			dataOut <= data1;
		end if;
		
		if rising_edge(clk) then
			if hexEna = '1' then
				if adr(0) = '0' then
					seg0 <= NIBBLE_TO_HEX(data(3 downto 0));
					seg1 <= NIBBLE_TO_HEX(data(7 downto 4));
					data0 <= data;
					seg2 <= x"00";
					seg3 <= x"00";
				else
					seg2 <= NIBBLE_TO_HEX(data(3 downto 0));
					seg3 <= NIBBLE_TO_HEX(data(7 downto 4));
					data1 <= data;
				end if;
			elsif addrEna = '1'then
				seg0 <= addr(16) & NIBBLE_TO_HEX(addr(3 downto 0)) (6 downto 0);
				seg1 <= addr(17) & NIBBLE_TO_HEX(addr(7 downto 4)) (6 downto 0);
				seg2 <= addr(18) & NIBBLE_TO_HEX(addr(11 downto 8)) (6 downto 0);
				seg3 <= addr(19) & NIBBLE_TO_HEX(addr(15 downto 12)) (6 downto 0);
				
				data0 <= addr(7 downto 0);
				data1 <= addr(15 downto 8);	
				bank	<= addr(23 downto 16);
				
			elsif segEna = '1' then
				case adr is
					when "00" 	=> seg0 <= data;
					when "01" 	=> seg1 <= data;
					when "10" 	=> seg2 <= data;
					when others => seg3 <= data;
				end case;
			end if;
		end if;
	end process;

	process(all)
	begin
					
		seg7_digit	<= seg7_shift;
		
		if rising_edge(clk) then
			counter <= counter + 1;
			if counter = 250000 then
				counter <= 0;
				seg7_shift <= seg7_shift(2 downto 0) & seg7_shift(3);
			end if;
		end if;
	end process;
	

end;
