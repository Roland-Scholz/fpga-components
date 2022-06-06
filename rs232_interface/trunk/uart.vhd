----------------------------------------------------------------------------------
-- Creation Date: 21:12:48 05/06/2010 
-- Module Name: RS232/UART Interface - Behavioral
-- Used TAB of 4 Spaces
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart is
generic (
	CLK_FREQ	: integer := 50;		-- Main frequency (MHz)
	SER_FREQ	: integer := 9600		-- Baud rate (bps)
);
port (
	-- Control
	clk			: in	std_logic;		-- Main clock
	rst			: in	std_logic;		-- Main reset
	-- External Interface
	rx			: in	std_logic;		-- RS232 received serial data
	tx			: out	std_logic;		-- RS232 transmitted serial data
	-- RS232/UART Configuration
	-- par_en		: in	std_logic;		-- Parity bit enable
	-- uPC Interface
	dataIn		: in	std_logic_vector(7 downto 0);	-- Data to transmit
	dataOut		: out	std_logic_vector(7 downto 0);	-- Received data 
	addr			: in std_logic_vector(2 downto 0);
	cs				: in std_logic;
	rw				: in std_logic;
	intn			: out std_logic
);
end uart;

architecture Behavioral of uart is

	-- Constants
	constant UART_IDLE	:	std_logic := '1';
	constant UART_START	:	std_logic := '0';
	constant PARITY_EN	:	std_logic := '1';
	constant RST_LVL		:	std_logic := '1';
	constant par_en		:  std_logic := '0';
	constant charA			:	std_logic_vector(7 downto 0) := x"41";
	

	-- Types
	type state is (idle,data,parity,stop1,stop2);			-- Stop1 and Stop2 are inter frame gap signals

	-- RX Signals
	signal rx_fsm			:	state;							-- Control of reception
	signal rx_clk_en		:	std_logic;						-- Received clock enable
	signal rx_start		:	std_logic;						-- Start of reception
	signal rx_start_bit	:	std_logic;						-- Start of reception
	signal rx_rcv_init	:	std_logic;						-- Start of reception
	signal rx_par_bit		:	std_logic;						-- Calculated Parity bit
	signal rx_data_deb	:	std_logic;						-- Debounce RX data
	signal rx_data			:	std_logic_vector(7 downto 0);	-- Serial to parallel converter
	signal rx_data_tmp	:	std_logic_vector(7 downto 0);	-- Serial to parallel converter
	signal rx_data_cnt	:	std_logic_vector(2 downto 0);	-- Count received bits
	signal rx_ready		:  std_logic;						-- Received data ready to uPC read

	-- TX Signals
	signal tx_fsm			:	state;							-- Control of transmission
	signal tx_clk_en		:	std_logic;						-- Transmited clock enable
	signal tx_par_bit		:	std_logic;						-- Calculated Parity bit
	signal tx_data			:	std_logic_vector(7 downto 0);	-- Parallel to serial converter
	signal tx_data_tmp	:	std_logic_vector(7 downto 0);	-- Parallel to serial converter
	signal tx_data_cnt	:	std_logic_vector(2 downto 0);	-- Count transmited bits
	signal tx_end			:	std_logic;
	signal tx_req			:	std_logic;
	signal rx_data_old	:	std_logic;
	signal counter			:  integer;
	
	-- registers
	signal ier				: std_logic_vector(7 downto 0);	-- Interrupt Enable Register
	signal iir				: std_logic_vector(2 downto 0);	-- Interrupt Enable Register
	
begin

	with addr select 
		dataOut	<=	rx_data										when "000",
						ier											when "001",
						"00000" & iir								when "010",	
						"0" & tx_end & "00000" & rx_ready	when "101",
						x"00"											when others;
								
	tx_clk_gen:process(clk)
		variable counter	:	integer range 0 to conv_integer((CLK_FREQ*1_000_000)/SER_FREQ-1);
	begin
		if clk'event and clk = '1' then
			-- Normal Operation
			if counter = (CLK_FREQ*1_000_000)/SER_FREQ-1 then
				tx_clk_en	<=	'1';
				counter		:=	0;
			else
				tx_clk_en	<=	'0';
				counter		:=	counter + 1;
			end if;
			-- Reset condition
			if rst = RST_LVL then
				tx_clk_en	<=	'0';
				counter		:=	0;
			end if;
		end if;
	end process;

	tx_proc:process(clk)
		variable data_cnt	: std_logic_vector(2 downto 0);
	begin
		if clk'event and clk = '1' then
		
			if cs = '1' and rw = '0' then
				if addr = "000" then
					tx_data <= dataIn;
					tx_req <= '1';
					tx_end <= '0';
				end if;
				
				if addr = "001" then
					ier	<= datain;
				end if;
				
			end if;
			
			if tx_clk_en = '1' then
				-- Default values
				--tx_end					<=	'0';
				tx						<=	UART_IDLE;
				-- FSM description
				case tx_fsm is
					-- Wait to transfer data
					when idle =>
						-- Send Init Bit
						if tx_req = '1' then
							tx			<=	UART_START;
							tx_data_tmp	<=	tx_data;
							tx_fsm		<=	data;
							tx_data_cnt	<=	(others=>'1');
							tx_par_bit	<=	'0';
							tx_req		<= '0';
						end if;
					-- Data receive
					when data =>
						tx				<=	tx_data_tmp(0);
						tx_par_bit		<=	tx_par_bit xor tx_data_tmp(0);
						if tx_data_cnt = 0 then
							if par_en = PARITY_EN then
								tx_fsm	<=	parity;
							else
								tx_fsm	<=	stop1;
								counter <= 0;
							end if;
							tx_data_cnt	<=	(others=>'1');
						else
							tx_data_tmp	<=	'0' & tx_data_tmp(7 downto 1);
							tx_data_cnt	<=	tx_data_cnt - 1;
						end if;
					when parity =>
						tx				<=	tx_par_bit;
						tx_fsm			<=	stop1;
					-- End of communication
					when stop1 =>
						-- Send Stop Bit
						tx				<=	UART_IDLE;
						if counter = 1 then
							tx_fsm		<=	stop2;
							
						else
							counter <= counter + 1;
						end if;
					when stop2 =>
						-- Send Stop Bit
						tx				<=	UART_IDLE;
						tx_fsm		<=	idle;
						tx_end		<= '1';
					-- Invalid States
					when others => null;
				end case;

			end if;
			
			-- Reset condition
			if rst = RST_LVL then
				tx_fsm				<=	idle;
				tx_par_bit			<=	'0';
				tx_data_tmp			<=	(others=>'0');
				tx_data_cnt			<=	(others=>'0');
				tx_req 				<= '0';
				tx_end				<= '1';
				ier					<= (others => '0');
			end if;
			
		end if;
	end process;

	rx_debouncer:process(clk)
		variable deb_buf	:	std_logic_vector(7 downto 0);
	begin
		if clk'event and clk = '1' then
			-- Debounce logic
			if deb_buf = "00000000" then
				rx_data_deb		<=	'0';
			elsif deb_buf = "11111111" then
				rx_data_deb		<=	'1';
			end if;
			-- Data storage to debounce
			deb_buf				:=	deb_buf(6 downto 0) & rx;
		end if;
	end process;

	rx_start_detect:process(clk)
		variable counter : integer := 0;
	begin
		if clk'event and clk = '1' then
			-- Falling edge detection
			if rx_data_old = '1' and rx_data_deb = '0' and rx_start_bit = '0' and rx_fsm = idle then
				rx_start_bit <= '1';
				counter := 0;
--			else
--				rx_rcv_init	<=	'0';
			end if;
							
			rx_rcv_init	<=	'0';
				
			if rx_start_bit = '1' then
				if counter = (CLK_FREQ*500_000)/SER_FREQ-1 then
					rx_start_bit <= '0';
					rx_rcv_init <= '1';
				else
					counter := counter + 1;
				end if;
			end if;
			
			-- Default assignments
			rx_data_old			<=	rx_data_deb;
			-- Reset condition
			if rst = RST_LVL then
				rx_data_old		<=	'0';
				rx_rcv_init		<=	'0';
				rx_start_bit	<= '0';				
			end if;
		end if;
	end process;


	rx_clk_gen:process(clk)
		variable counter	:	integer range 0 to conv_integer((CLK_FREQ*1_000_000)/SER_FREQ-1);
	begin
		if clk'event and clk = '1' then
			-- Normal Operation
			if counter = (CLK_FREQ*1_000_000)/SER_FREQ-1 or rx_rcv_init = '1' then --(CLK_FREQ*1_000_000)/SER_FREQ-1 or rx_rcv_init = '1' then
				rx_clk_en	<=	'1';
				counter		:=	0;
				if rx_rcv_init = '1' then
					rx_start <= '1';
				end if;
			else
				rx_start <= '0';
				rx_clk_en	<=	'0';
				counter		:=	counter + 1;
			end if;
			-- Reset condition
			if rst = RST_LVL then
				rx_clk_en	<=	'0';
				counter		:=	0;
			end if;
		end if;
	end process;

	rx_proc:process(clk)
	begin
		if clk'event and clk = '1' then
						
			if cs = '1' and rw = '1' and addr = "000" then
				rx_ready <= '0';
				intn	<= '1';
				iir	<= "001";
			end if;

			if rx_clk_en = '1' then
				-- FSM description
				case rx_fsm is
					-- Wait to transfer data
					when idle =>
						if rx_start = '1' then
							rx_fsm		<=	data;
						end if;
						rx_par_bit		<=	'0';
						rx_data_cnt		<=	(others=>'0');
					-- Data receive
					when data =>
						-- Check data to generate parity
						if par_en = PARITY_EN then
							rx_par_bit		<=	rx_par_bit xor rx;
						end if;

						-- Data path
						--rx_data			<= rx & rx_data(7 downto 1); --charA(conv_integer(unsigned(rx_data_cnt))) & rx_data(7 downto 1);
						rx_data_tmp		<=	rx & rx_data_tmp(7 downto 1);
						rx_data_cnt		<=	rx_data_cnt + 1;
							
						if rx_data_cnt = 7 then	
							-- With parity verification
							if par_en = PARITY_EN then
								rx_fsm		<=	parity;
							-- Without parity verification
							else
								rx_data		<=	rx & rx_data_tmp(7 downto 1);
								rx_fsm		<=	stop2;
								rx_ready		<=	'1';
								if ier(0) = '1' then
									intn <= '0';
									iir <= "100";
								end if;
							end if;
						end if;
					when parity =>
						-- Check received parity
						rx_fsm				<=	stop1;
						rx_data 				<= rx_data_tmp;
						if par_en = PARITY_EN and rx_par_bit = rx then
							rx_ready			<=	'1';
						end if;
					when stop1 =>
						rx_fsm				<=	idle;
					when stop2 =>
						rx_fsm				<=	idle;
--						rx_data 				<= rx_data_tmp;
--						rx_ready				<=	'1';
					when others => null;
				end case;
				
			end if;
			-- Reset condition
			if rst = RST_LVL then
				rx_fsm			<=	idle;
				rx_ready			<=	'0';
				rx_data			<=	(others=>'0');
				rx_data_tmp		<=	(others=>'0');
				rx_data_cnt		<=	(others=>'0');
				iir				<= "001";
				intn				<= '1';
			end if;
		end if;
	end process;

end Behavioral;

