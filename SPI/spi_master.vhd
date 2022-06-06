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

ENTITY spi_master IS
  GENERIC(
    slaves  	: INTEGER := 1;  --number of spi slaves
    d_width 	: INTEGER := 8); --data bus width
  PORT(
    clock   	: IN     STD_LOGIC;                             --system clock
	 phi2			: IN		STD_LOGIC;
	 wr			: IN     STD_LOGIC;                             --read=1, write=0
	 cs			: IN     STD_LOGIC;                             --chip select aactive low
	 CPUaddr		: IN     STD_LOGIC_VECTOR(3 DOWNTO 0);  			--addr of registers
	 CPUdataIn	: IN     STD_LOGIC_VECTOR(7 DOWNTO 0);  			--data in
	 CPUDataOut	: OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);  			--data out
    reset_n 	: IN     STD_LOGIC;                             --asynchronous reset
    miso    	: IN     STD_LOGIC;                             --master in, slave out
    sclk    	: OUT		STD_LOGIC;                             --spi clock
    ss_n    	: OUT		STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   --slave select
    mosi    	: OUT    STD_LOGIC                             --master out, slave in
	);
END spi_master;

ARCHITECTURE logic OF spi_master IS
  
  SIGNAL count       : STD_LOGIC_VECTOR(8 DOWNTO 0);                           --counter to trigger sclk from system clock
  SIGNAL bitcnt		: STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL spiClk 		: STD_LOGIC := '0';                              
  SIGNAL	control		: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := x"96";  
  SIGNAL	status		: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := x"00";  
  SIGNAL	tx_data		: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)	:= x"FF";  
  SIGNAL	rx_data		: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  
  SIGNAL	ss_reg		: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)	:= x"FF";
  SIGNAL rising		: STD_LOGIC := '0';
  SIGNAL falling		: STD_LOGIC := '0';
  SIGNAL start			: STD_LOGIC := '0';
  
  
  
  
BEGIN
	
	process (all)
	begin			
		if rising_edge(clock) then
			if reset_n = '0' then
				tx_data	<= (others => '1');
				ss_reg	<=	(others => '1');
				control	<= x"96";		-- $96 = 150d; 100Mhz / 2*150 = 333.333Hz
				start		<= '0';
			elsif phi2 = '1' and cs = '1' and wr = '0' then
				case CPUaddr is
					when "0000" => control	<= CPUdataIn;
					when "0001" => ss_reg	<= CPUdataIn;
					when "0010"	=>	tx_data	<= CPUdataIn; start <= '1';
					when others => tx_data  <= "11111111"; start <= '1'; --spiStat
				end case;				
			else
				start <= '0';
			end if;
		end if;
	end process;
	
	process (all)
	begin
		mosi <= tx_data(to_integer(7 - unsigned(bitcnt)));

		if rising_edge(clock) then
			if reset_n = '0' then
				status <= (others => '0');
				bitcnt <= (others => '0');
			else
				if start = '1' then
					bitcnt <= (others => '0');
					status(0) <= '1';
				elsif bitcnt > 7 then
						status(0) <= '0';
				elsif status(0) = '1' then
									
					if rising = '1' then
						rx_data(7 - to_integer(unsigned(bitcnt))) <= miso;
					end if;
						
					if falling = '1' then
						bitcnt <= bitcnt + 1;
					end if;
		
				end if;
			end if;
		end if;	
	end process;

	
	
	process (all)
	begin

		if rising_edge(clock) then
			rising <= '0';
			falling <= '0';
			
			if status(0) = '0' or reset_n = '0' then
				count <= (others => '0');
				spiClk <= '0';
			else
				count <= count + 1;
				if (count = control) then
					if spiClk = '0' then
						rising <= '1';
					else
						falling <= '1';
					end if;
					
					spiClk <= not spiClk;
					count <= (others => '0');
				end if;
			end if;
		end if;
	
	end process;
		
	ss_n(0) <= ss_reg(0);
	sclk <= spiClk;
	
	with CPUaddr select 
		CPUDataOut <=	control	when "0000",
							ss_reg	when "0001",
							rx_data	when "0010",
							status	when others;

END logic;
