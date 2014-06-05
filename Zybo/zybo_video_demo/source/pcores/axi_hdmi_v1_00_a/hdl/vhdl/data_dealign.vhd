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
-- 1.0 	    2011-11-22   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : DVI, HDMI
-------------------------------------------------------------------------------
-- This module aligns the 4-byte data input to the 3-byte data output in
-- conjunction with the data enable being active (high).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity data_dealign is
    port(
        CLK_I   : in    std_logic;                      -- Input Clock
        RST_I   : in    std_logic;                      -- Input Reset (active high)
        AE_I    : in    std_logic;                      -- deallign enable input (active high)
        D_I     : in    std_logic_vector(31 downto 0);  -- 32-bit data input
        D_O     : out   std_logic_vector(23 downto 0);  -- 24-bit data output
        DE_O    : out   std_logic                       -- data enable output (active high)
    );
end data_dealign;

architecture Behavioral of data_dealign is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

-- Local counter
signal Cnt      : std_logic_vector(1 downto 0);
signal Cnt_dly  : std_logic_vector(1 downto 0);

-- Accumulator register
signal Accum    : std_logic_vector(23 downto 0);

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Counter process
------------------------------------------------------------------------
    COUNT_PROC: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if AE_I = '1' then
                Cnt <= Cnt(0) & not Cnt(1);
            else
                Cnt <= (others => '0');
            end if;
        end if;
    end process COUNT_PROC;
    
------------------------------------------------------------------------
-- Counter delay process
------------------------------------------------------------------------
    DELAY_PROC: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            Cnt_dly <= Cnt;
        end if;
    end process DELAY_PROC;

------------------------------------------------------------------------
-- Registering input data into the accumulator register
------------------------------------------------------------------------
    REG_IN: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            Accum <= D_I(31 downto 8);
        end if;
    end process REG_IN;

------------------------------------------------------------------------
-- Generate Data Enable
------------------------------------------------------------------------    
    GEN_DE: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if Cnt = "10" then
                DE_O <= '0';
            else
                DE_O <= '1';
            end if;
        end if;
    end process GEN_DE;

------------------------------------------------------------------------
-- Output data from the accumulator register
------------------------------------------------------------------------
    DATA_O: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            case Cnt_dly is
                when "00" => D_O <= D_I(23 downto 0);
                when "01" => D_O <= D_I(15 downto 0) & Accum(23 downto 16);
                when "11" => D_O <= D_I(7 downto 0) & Accum(23 downto 8);
                when "10" => D_O <= Accum;
                when others => D_O <= (others => '0');
            end case;
        end if;
    end process DATA_O;

end Behavioral;

