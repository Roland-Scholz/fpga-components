-- megafunction wizard: %ALTCLKLOCK%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altclklock 

-- ============================================================
-- File Name: pll1.vhd
-- Megafunction Name(s):
-- 			altclklock
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
-- ************************************************************


--Copyright (C) 1991-2000 Altera Corporation
--Any megafunction design, and related net list (encrypted or decrypted),
--support information, device programming or simulation file, and any other
--associated documentation or information provided by Altera or a partner
--under Altera's Megafunction Partnership Program may be used only to
--program PLD devices (but not masked PLD devices) from Altera.  Any other
--use of such megafunction design, net list, support information, device
--programming or simulation file, or any other related documentation or
--information is prohibited for any other purpose, including, but not
--limited to modification, reverse engineering, de-compiling, or use with
--any other silicon devices, unless such use is explicitly licensed under
--a separate agreement with Altera or a megafunction partner.  Title to
--the intellectual property, including patents, copyrights, trademarks,
--trade secrets, or maskworks, embodied in any such megafunction design,
--net list, support information, device programming or simulation file, or
--any other related documentation or information provided by Altera or a
--megafunction partner, remains with Altera, the megafunction partner, or
--their respective licensors.  No other licenses, including any licenses
--needed under any third party's intellectual property, are provided herein.

LIBRARY ieee;
USE ieee.std_logic_1164.all;
--LIBRARY lpm;
--USE lpm.lpm_components.all;

ENTITY pll1 IS
	PORT
	(
		inclock		: IN STD_LOGIC ;
		locked		: OUT STD_LOGIC ;
		clock1		: OUT STD_LOGIC 
	);
END pll1;


ARCHITECTURE SYN OF pll1 IS

	SIGNAL sub_wire0	: STD_LOGIC ;
	SIGNAL sub_wire1	: STD_LOGIC ;



	COMPONENT altclklock
	GENERIC (
		inclock_period		: NATURAL;
		clock1_boost		: NATURAL;
		operation_mode		: STRING;
		valid_lock_cycles		: NATURAL;
		invalid_lock_cycles		: NATURAL;
		valid_lock_multiplier		: NATURAL;
		invalid_lock_multiplier		: NATURAL;
		clock1_divide		: NATURAL;
		outclock_phase_shift		: NATURAL
	);
	PORT (
			inclock	: IN STD_LOGIC ;
			clock1	: OUT STD_LOGIC ;
			locked	: OUT STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	clock1    <= sub_wire0;
	locked    <= sub_wire1;

	altclklock_component : altclklock
	GENERIC MAP (
		inclock_period => 7500,                      -- for 133mhz operation
--		inclock_period => 10000,                      -- for 100mhz operation
		clock1_boost => 1,
		operation_mode => "NORMAL",
		valid_lock_cycles => 15,
		invalid_lock_cycles => 15,
		valid_lock_multiplier => 5,
		invalid_lock_multiplier => 5,
		clock1_divide => 1,
		outclock_phase_shift => 0
	)
	PORT MAP (
		inclock => inclock,
		clock1 => sub_wire0,
		locked => sub_wire1
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: DISPLAY_FREQUENCY STRING "133"
-- Retrieval info: PRIVATE: USING_FREQUENCY NUMERIC "0"
-- Retrieval info: PRIVATE: DEVICE_FAMILY NUMERIC "1"
-- Retrieval info: PRIVATE: FEEDBACK_SOURCE NUMERIC "1"
-- Retrieval info: PRIVATE: PHASE_UNIT NUMERIC "0"
-- Retrieval info: PRIVATE: USING_PROGRAMMABLE_PHASE_SHIFT NUMERIC "1"
-- Retrieval info: CONSTANT: INCLOCK_PERIOD NUMERIC "7518"
-- Retrieval info: CONSTANT: CLOCK1_BOOST NUMERIC "1"
-- Retrieval info: CONSTANT: OPERATION_MODE STRING "NORMAL"
-- Retrieval info: CONSTANT: VALID_LOCK_CYCLES NUMERIC "15"
-- Retrieval info: CONSTANT: INVALID_LOCK_CYCLES NUMERIC "15"
-- Retrieval info: CONSTANT: VALID_LOCK_MULTIPLIER NUMERIC "5"
-- Retrieval info: CONSTANT: INVALID_LOCK_MULTIPLIER NUMERIC "5"
-- Retrieval info: CONSTANT: CLOCK1_DIVIDE NUMERIC "1"
-- Retrieval info: CONSTANT: OUTCLOCK_PHASE_SHIFT NUMERIC "0"
-- Retrieval info: USED_PORT: inclock 0 0 0 0 INPUT NODEFVAL inclock
-- Retrieval info: USED_PORT: locked 0 0 0 0 OUTPUT NODEFVAL locked
-- Retrieval info: USED_PORT: clock1 0 0 0 0 OUTPUT NODEFVAL clock1
-- Retrieval info: CONNECT: @inclock 0 0 0 0 inclock 0 0 0 0
-- Retrieval info: CONNECT: locked 0 0 0 0 @locked 0 0 0 0
-- Retrieval info: CONNECT: clock1 0 0 0 0 @clock1 0 0 0 0