--------------------------------------------------------------------------------
--
--   FileName:         spi_master.vhd
--   Dependencies:     none
--   Design Software:  Quartus II Version 9.0 Build 132 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 7/23/2010 Scott Larson
--     Initial Public Release
--   Version 1.1 4/11/2013 Scott Larson
--     Corrected ModelSim simulation error (explicitly reset clk_toggles signal)
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.all;
USE ieee.std_logic_unsigned.all;

ENTITY my6502keyboard IS
  PORT(
    clock   	: IN     STD_LOGIC;                             --system clock
	 phi2			: IN     STD_LOGIC;                             --cpu clock
	 wr			: IN     STD_LOGIC;                             --read=1, write=0
	 cs			: IN     STD_LOGIC;                             --chip select active low
	 CPUaddr		: IN     STD_LOGIC_VECTOR(3 DOWNTO 0);  			--addr of registers
	 CPUdataIn	: IN     STD_LOGIC_VECTOR(7 DOWNTO 0);  			--data in
	 CPUDataOut	: OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  			--data out
    reset_n 	: IN     STD_LOGIC;                             --asynchronous reset
	 intr			: OUT		STD_LOGIC;        
	 PS2_CLK		:	in		std_logic;
	 PS2_DATA	:	in		std_logic
	);
END my6502keyboard;

ARCHITECTURE logic OF my6502keyboard IS

	signal KEYBdata  	:	STD_LOGIC_VECTOR(7 DOWNTO 0);          --keyboard data
	signal KEYavail	:	std_logic;
	
	-- Interface to PS/2 block
	signal keyb_data	:	std_logic_vector(7 downto 0);
	signal keyb_valid	:	std_logic;
	-- signal keyb_error	:	std_logic;
	
BEGIN
		
	ps2 : work.ps2_intf port map (
		clock, reset_n,
		PS2_CLK, PS2_DATA,
		keyb_data, keyb_valid --, keyb_error
	);

	process(all)
	begin
	
		intr <= KEYavail;
		
		if reset_n = '0' then
			KEYavail <= '1';
		elsif rising_edge(clock) then
			if phi2 = '1' and cs = '1' and wr = '1' and cpuaddr(0) = '0' then
				KEYavail <= '1';
			end if;
			
			if keyb_valid = '1' /* and phi2 = '1' */ then
				KEYBdata <= keyb_data;
				KEYavail <= '0';
			end if;
		end if;
		
		if cpuaddr(0) = '0' then
			CPUDataOut <= KEYBdata;
		else
			CPUDataOut <= "0000000" & KEYavail;
		end if;
			
	end process;
	

END logic;
