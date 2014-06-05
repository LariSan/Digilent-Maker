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
-- KEYWORDS : DVI, HDMI, DDC2B, EDID, TWI, I2C
-------------------------------------------------------------------------------
-- This module implements the DDC2B standard by sending thru an I2C interface
-- the Digilent Atlys board EDID.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity hdmi_ddc is
    port(
        -- Other signals
        CLK_I : in  std_logic; -- System clock
        RSTN_I: in  std_logic; -- System reset
        EN_I  : in  std_logic; -- Enable DDC (active high)
        
        -- I2C signals
        SCL_I : in  std_logic;
        SDA_I : in  std_logic;
        SDA_T : out std_logic;
        SDA_O : out std_logic
    );
end hdmi_ddc;

architecture Behavioral of hdmi_ddc is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal Rst  : std_logic;
signal Reset: std_logic;
signal DReq : std_logic;
signal Data : std_logic_vector(7 downto 0);

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

component twi_slave
    generic(
        ADDR    : std_logic_vector(7 downto 0) := x"A0");    
    port(
        CLK_I   : in  std_logic;
        RST_I   : in  std_logic;
        EN_I    : in  std_logic;
        D_REQ_O : out std_logic;
        RST_O   : out std_logic;
        D_I     : in  std_logic_vector(7 downto 0);
        SCL_I   : in  std_logic;        
        SDA_I   : in  std_logic;
        SDA_T   : out std_logic;
        SDA_O   : out std_logic);
end component;

component twi_slave_rom
    generic(
        DEPTH   : std_logic_vector(7 downto 0) := x"80");    
    port(
        CLK_I   : in  std_logic;
        RST_I   : in  std_logic;
        RD_EN_I : in  std_logic;
        D_O     : out std_logic_vector(7 downto 0));
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Instantiate the I2C Slave Transmitter
------------------------------------------------------------------------    
    Inst_TwiSlave: twi_slave
    generic map(
        -- Slave address A0/A1
        ADDR    => x"A0")
    port map(
        CLK_I   => CLK_I,
        RST_I   => Reset,
        EN_I    => EN_I,
        D_REQ_O => DReq,
        RST_O   => Rst,
        D_I     => Data,
        SCL_I   => SCL_I,       
        SDA_I   => SDA_I,
        SDA_T   => SDA_T,
        SDA_O   => SDA_O);
    
    Reset <= not RSTN_I;

------------------------------------------------------------------------
-- Instantiate the I2C ROM
------------------------------------------------------------------------    
    Inst_TwiTxRom: twi_slave_rom
    generic map(
        -- 128-bit EDID
        DEPTH   => x"80")
    port map(
        CLK_I   => CLK_I,
        RST_I   => Rst,
        RD_EN_I => DReq,
        D_O     => Data);

end Behavioral;

