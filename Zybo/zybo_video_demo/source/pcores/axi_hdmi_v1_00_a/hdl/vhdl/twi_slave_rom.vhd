-----------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2011, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME            : axi_dvi_transmitter.vhd
-- MODULE NAME          : AXI DVI Transmitter
-- AUTHOR               : Mihaita Nagy
-- AUTHOR'S EMAIL       : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0 	    2011-11-15   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : DVI, HDMI, DDC, EDID, TWI, I2C
-------------------------------------------------------------------------------
-- This module implements a ROM in which the EDID is stored and on every Read
-- Enable assertion a new byte is sent to D_O.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity twi_slave_rom is
    generic(
        DEPTH   : std_logic_vector(7 downto 0) := x"80"
    );    
    port(
        CLK_I   : in  std_logic; -- System clock
        RST_I   : in  std_logic; -- Active high reset input
        RD_EN_I : in  std_logic; -- Read Enable
        D_O     : out std_logic_vector(7 downto 0) -- 8-bit data out
    );
end twi_slave_rom;

architecture Behavioral of twi_slave_rom is

------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------

type Memory is array(0 to conv_integer(DEPTH)-1) of std_logic_vector(7 downto 0);

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------

-- Digilent Atlys EDID
constant Mem : Memory := (

----00    01    02    03    04    05    06    07    08    09    0A    0B    0C    0D    0E    0F
---------------------------------------------------------------------------------------------------
--x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"11",x"27",x"01",x"00",x"00",x"00",x"00",x"00", -- 00
--x"2E",x"15",x"01",x"03",x"80",x"00",x"00",x"00",x"0A",x"DE",x"95",x"A3",x"54",x"4C",x"99",x"26", -- 10
--x"0F",x"50",x"54",x"20",x"00",x"00",x"A9",x"C0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01", -- 20
--x"01",x"01",x"01",x"01",x"01",x"01",x"8C",x"0A",x"D0",x"8A",x"20",x"E0",x"2D",x"10",x"10",x"3E", -- 30
--x"96",x"00",x"58",x"90",x"21",x"00",x"00",x"18",x"01",x"1D",x"00",x"72",x"51",x"D0",x"1E",x"20", -- 40
--x"6E",x"28",x"55",x"00",x"20",x"C2",x"31",x"00",x"00",x"1E",x"01",x"1D",x"80",x"18",x"71",x"38", -- 50
--x"2D",x"40",x"58",x"2C",x"45",x"00",x"20",x"C2",x"31",x"00",x"00",x"1E",x"00",x"00",x"00",x"FC", -- 60
--x"00",x"44",x"69",x"67",x"69",x"6C",x"65",x"6E",x"74",x"41",x"74",x"6C",x"79",x"73",x"00",x"01");-- 70

--00    01    02    03    04    05    06    07    08    09    0A    0B    0C    0D    0E    0F
-------------------------------------------------------------------------------------------------
x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"11",x"27",x"01",x"00",x"00",x"00",x"00",x"00", -- 00
x"2E",x"15",x"01",x"03",x"81",x"00",x"00",x"00",x"08",x"DE",x"95",x"A3",x"54",x"4C",x"99",x"26", -- 10
x"0F",x"50",x"54",x"21",x"00",x"00",x"A9",x"C0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01", -- 20
x"01",x"01",x"01",x"01",x"01",x"01",x"C4",x"09",x"D0",x"8A",x"20",x"E0",x"2D",x"10",x"10",x"3E", -- 30
x"96",x"00",x"58",x"90",x"21",x"00",x"00",x"18",x"4C",x"1D",x"00",x"72",x"51",x"D0",x"1E",x"20", -- 40
x"6E",x"28",x"55",x"00",x"20",x"C2",x"31",x"00",x"00",x"1E",x"10",x"1D",x"80",x"18",x"71",x"38", -- 50
x"2D",x"40",x"58",x"2C",x"45",x"00",x"20",x"C2",x"31",x"00",x"00",x"1E",x"00",x"00",x"00",x"FC", -- 60
x"00",x"44",x"69",x"67",x"69",x"6C",x"65",x"6E",x"74",x"41",x"74",x"6C",x"79",x"73",x"00",x"70");-- 70

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

-- Read/Write pointers
signal RdPtr : std_logic_vector(7 downto 0) := x"00";

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Byte read from memory process
------------------------------------------------------------------------
    READ_MEM: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' or RdPtr = x"FF" then
                RdPtr <= x"00";
            elsif RD_EN_I = '1' then
                RdPtr <= RdPtr + '1';
            else
                null;
            end if;       
        end if;
    end process READ_MEM;
    
    -- Assign the output byte
    D_O <= Mem(conv_integer(RdPtr));

end Behavioral;

