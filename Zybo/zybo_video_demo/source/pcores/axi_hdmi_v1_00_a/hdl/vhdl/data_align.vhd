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
-- This module aligns the 3-byte data input to the 4-byte data output in
-- conjunction with the data enable being active (high).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity data_align is
    port(
        CLK_I   : in    std_logic;                      -- Input Clock
        RST_I   : in    std_logic;                      -- Input Reset (active high)
        AE_I    : in    std_logic;                      -- allign enable input (active high)
        D_I     : in    std_logic_vector(23 downto 0);  -- 24-bit data input
        D_O     : out   std_logic_vector(31 downto 0);  -- 32-bit data output
        DE_O    : out   std_logic                       -- data enable output (active high)
    );
end data_align;

architecture Behavioral of data_align is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

-- Local counter
signal Cnt      : std_logic_vector(1 downto 0);

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
            if RST_I = '1' then
                Cnt <= (others => '0');
            elsif AE_I = '1' then
                Cnt <= Cnt + '1';
            else
                Cnt <= (others => '0');
            end if;
        end if;
    end process COUNT_PROC;

------------------------------------------------------------------------
-- Registering input data into the accumulator register
------------------------------------------------------------------------
    REG_IN: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            Accum <= D_I;
        end if;
    end process REG_IN;

------------------------------------------------------------------------
-- Combinational part of output data and the accumulator register
------------------------------------------------------------------------
    DATA_O: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            case Cnt is
                when "00" =>
                    D_O <= (others => '0');
                    DE_O <= '0';
                when "01" =>
                    D_O <= D_I(7 downto 0) & Accum;
                    DE_O <= '1';
                when "10" =>
                    D_O <= D_I(15 downto 0) & Accum(23 downto 8);
                    DE_O <= '1';
                when "11" =>
                    D_O <= D_I & Accum(23 downto 16);
                    DE_O <= '1';
                when others =>
                    D_O <= (others => '0');
                    DE_O <= '0';
            end case;
        end if;
    end process DATA_O;

end Behavioral;

