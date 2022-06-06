----------------------------------------------------------------------------------
-- Creation Date: 21:12:48 05/06/2010 
-- Module Name: RS232/UART Interface - Behavioral
-- Used TAB of 4 Spaces
----------------------------------------------------------------------------------
library IEEE;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity special is
port (
	-- Control
	clk			: in	std_logic;		-- Main clock
	rst			: in	std_logic;		-- Main reset
	-- External Interface
	dataIn		: in	std_logic_vector(7 downto 0);
	dataOut		: out	std_logic_vector(7 downto 0);
	cpuAddress	: in	std_logic_vector(23 downto 0);
	cs				: in	std_logic;
	rw				: in	std_logic;
	timerIRQ		: out std_logic;
	softReset	: out std_logic;
	seg7Digit	: out std_logic_vector(3 downto 0);
	seg7			: out std_logic_vector(7 downto 0);
	debug			: in std_logic;
	slow			: out std_logic;
	debugData	: in std_logic_vector(15 downto 0)
		
);
end special;

architecture Behavioral of special is

	type 		t_nibble	is array (0 to 15) of std_logic_vector(6 downto 0);
	type 		t_regs	is array (0 to 15) of std_logic_vector(7 downto 0);
	
	signal 	nibbles		: t_nibble := ("0111111",	
													"0000110",	
													"1011011",	
													"1001111",	
													"1100110",	
													"1101101",	
													"1111101",	
													"0000111",	
													"1111111",	
													"1101111",	
													"1110111",	
													"1111100",	
													"0111001",	
													"1011110",	
													"1111001",	
													"1110001"	);

	signal	regs			: t_regs := (others => (others => '0'));
	
	signal	timerCnt		: std_logic_vector(15 downto 0);
	signal	seg7shift	: std_logic_vector( 3 downto 0) := "0111";
	signal	counter		: std_logic_vector(14 downto 0);
	signal	cpuAddress4	: std_logic_vector( 3 downto 0);
	
	
	constant SOFTRES		: integer := 0;
	constant TIMERLO		: integer := 1;
	constant TIMERHI		: integer := 2;
	constant TIMERSTAT	: integer := 3;
	constant	WORDLO		: integer := 4;
	constant	WORDHI		: integer := 5;
	constant	DOTS			: integer := 6;
		
	
	function adr2int(
		byte : in std_logic_vector(3 downto 0))
		return integer is
	begin
		return to_integer(unsigned(byte));
	end;	
	
begin

	cpuAddress4	<= cpuAddress(3 downto 0);
	softReset	<= regs(SOFTRES)(7);
	slow			<= regs(SOFTRES)(0);

	process (all)
	begin					
		if rising_edge(clk) then
			if rst = '1' then
				regs(SOFTRES)		<= (others => '0');
				regs(TIMERLO)		<= (others => '1');
				regs(TIMERHI)		<= (others => '1');
				regs(TIMERSTAT)	<= (others => '0');
				regs(WORDLO)		<= (others => '0');
				regs(WORDHI)		<= (others => '0');
				regs(DOTS)			<= (others => '0');
				
				timerCnt				<= (others => '1');
				timerIRQ				<= '1';
			else
				if cs = '1' then
					if rw = '0' then
						regs(adr2int(cpuAddress4)) <= dataIn;
						if adr2int(cpuAddress4) = TIMERHI then
							timerCnt	<= dataIn & regs(TIMERLO);
						end if;
					else
						dataOut	<=	regs(adr2int(cpuAddress4));
						if adr2int(cpuAddress4) = TIMERSTAT then
							regs(TIMERSTAT)(7) <= '0';
							timerIRQ	<= '1';
						end if;
					end if;
				end if;
				
				-- 100Mhz / 8 = 12,5 Mhz
				if regs(TIMERSTAT)(0) = '1' and counter(2 downto 0) = 0 then
					timerCnt <= timerCnt - 1;
					if timerCnt = 0 then
						timerCnt <= regs(TIMERHI) & regs(TIMERLO);
						regs(TIMERSTAT)(7) <= '1';
						timerIRQ <= '0';
					end if;
				end if;
				
			end if;
		end if;
	end process;

	with debug & seg7shift select 
	seg7 <=	not regs(DOTS)(0)  & not nibbles(adr2int(regs(WORDLO)(3 downto 0))) when "00111",
				not regs(DOTS)(1)  & not nibbles(adr2int(regs(WORDLO)(7 downto 4))) when "01011",
				not regs(DOTS)(2)  & not nibbles(adr2int(regs(WORDHI)(3 downto 0))) when "01101",
				not regs(DOTS)(3)  & not nibbles(adr2int(regs(WORDHI)(7 downto 4))) when "01110",
				not cpuAddress(16) & not nibbles(adr2int(debugData( 3 downto  0))) when "10111",
				not cpuAddress(17) & not nibbles(adr2int(debugData( 7 downto  4))) when "11011",
				not cpuAddress(18) & not nibbles(adr2int(debugData(11 downto  8))) when "11101",
				not cpuAddress(19) & not nibbles(adr2int(debugData(15 downto 12))) when others;
				
	seg7Digit <= seg7shift;

	process(all)
	begin		
		if rising_edge(clk) then
			counter <= counter + 1;
			if counter = 0 then
				seg7shift <= seg7shift(2 downto 0) & seg7shift(3);
			end if;
		end if;
	end process;
	
end Behavioral;

