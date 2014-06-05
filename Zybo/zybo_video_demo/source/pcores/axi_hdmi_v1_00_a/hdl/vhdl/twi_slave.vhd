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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity twi_slave is
    generic(
        ADDR    : std_logic_vector(7 downto 0) := x"A0"
    );    
    port(
        -- Other signals
        CLK_I   : in  std_logic; -- System clock
        RST_I   : in  std_logic; -- Active high reset input
        EN_I    : in  std_logic; -- Enable
        D_REQ_O : out std_logic; -- Data request
        RST_O   : out std_logic; -- Reset output (for FIFO's pointers)
        D_I     : in  std_logic_vector(7 downto 0); -- 8-bit data input to be written
        
        -- IIC signals
        SCL_I   : in  std_logic;        
        SDA_I   : in  std_logic;
        SDA_T   : out std_logic;
        SDA_O   : out std_logic
    );
end twi_slave;

architecture Behavioral of twi_slave is

------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------

type States is (sIdle, sReadAddr, sCheckRnw, sSendAck, sSendReadAck, 
                sReadData, sWriteData, sReadAck);

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

-- Current and Next state of the main FSM
signal CState, NState       : States := sIdle;

-- Temporary shifting registers to detect rising/falling edges of SCL 
-- and Start/Stop conditions
signal SampleSda, SampleScl : std_logic_vector(3 downto 0);

-- Start/Stop signals
signal S, P                 : std_logic;

-- Rising/Falling edge of SCL
signal FallScl, RiseScl     : std_logic;

-- Read/Write and Ack (0 - Nack, 1 - Ack) flags
signal Rnw, Ack             : std_logic;

-- Counters for the send/read data
signal CntRead, CntSend     : std_logic_vector(3 downto 0);

-- Temporary registers to store input/output data
signal TempIn, TempOut      : std_logic_vector(7 downto 0) := (others => '0');

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------   
-- Sample SCL and SDA to detect Start and Stop conditions
------------------------------------------------------------------------
    S_P: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            SampleSda <= SampleSda(2 downto 0) & SDA_I;
            SampleScl <= SampleScl(2 downto 0) & SCL_I;
        end if;
    end process S_P;
    
    -- Rising/Falling edge of SCL
    RiseScl <= '1' when SampleScl = "0011" else '0';
    FallScl <= '1' when SampleScl = "1100" else '0';
    
    -- Start/Stop conditions
    S <= '1' when SampleSda = "1100" and SampleScl = "1111" else '0';
    P <= '1' when SampleSda = "0011" and SampleScl = "1111" else '0';

------------------------------------------------------------------------       
-- Register the Current and Next states
------------------------------------------------------------------------
    REG_STATES: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RST_I = '1' then
                CState <= sIdle;
            else
                CState <= NState;
            end if;
        end if;
    end process REG_STATES;

------------------------------------------------------------------------       
-- Main FSM, Next state decode
------------------------------------------------------------------------
    MAIN_FSM: process(CState, EN_I, S, P, CntRead, CntSend, RiseScl, 
                      FallScl, Rnw, Ack, TempIn)
    begin
        NState <= CState;
        case CState is
            when sIdle =>
                if EN_I = '1' and S = '1' then
                    NState <= sReadAddr;
                end if;
            when sReadAddr =>
                if RiseScl = '1' and CntRead = x"7" then
                    NState <= sCheckRnw;
                end if;
            when sCheckRnw =>
                if FallScl = '1' then
                    NState <= sSendAck;
                end if;
            when sSendAck =>
                if FallScl = '1' then
                    if TempIn(7 downto 1) = ADDR(7 downto 1) then
                        if Rnw = '1' then
                            NState <= sWriteData;
                        else
                            NState <= sReadData;
                        end if;
                    else
                        NState <= sIdle;
                    end if;
                end if;
            when sSendReadAck =>
                if FallScl = '1' then
                    NState <= sReadData;
                end if;
            when sReadData =>
                if FallScl = '1' and CntRead = x"8" then
                    NState <= sSendReadAck;
                end if;
            when sWriteData =>
                if FallScl = '1' and CntSend = x"8" then
                    NState <= sReadAck;
                end if;
            when sReadAck =>
                if FallScl = '1' and Ack = '1' then -- ACK
                    NState <= sWriteData;
                elsif FallScl = '1' and Ack = '0' then --NACK
                    NState <= sIdle;
                end if;
            when others => NState <= sIdle;
        end case;
        
        -- Reset in case of Start condition
        if S = '1' then
            NState <= sReadAddr;
        end if;
        
        -- Reset in case of Stop condition
        if P = '1' then
            NState <= sIdle;
        end if;
    end process MAIN_FSM;

------------------------------------------------------------------------       
-- Read data counter process
------------------------------------------------------------------------
    READ_COUNTER: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if CState = sReadAddr or CState = sReadData then
                if RiseScl = '1' then
                    CntRead <= CntRead + '1';
                end if;
            else
                CntRead <= (others => '0');
            end if;
        end if;
    end process READ_COUNTER;

------------------------------------------------------------------------       
-- Write data counter process
------------------------------------------------------------------------    
    WRITE_COUNTER: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if CState = sWriteData or CState = sSendAck then
                if FallScl = '1' then
                    CntSend <= CntSend + '1';
                end if;
            elsif CState = sReadAck then
                CntSend <= "0001";
            else
                CntSend <= (others => '0');
            end if;
        end if;
    end process WRITE_COUNTER;

------------------------------------------------------------------------       
-- Shift in data process
------------------------------------------------------------------------    
    READ_DATA: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if CState = sReadAddr or CState = sReadData or 
               CState = sCheckRnw or CState = sReadAck then
                if RiseScl = '1' then
                    TempIn <= TempIn(6 downto 0) & SDA_I;
                end if;
            end if;
        end if;
    end process READ_DATA;

------------------------------------------------------------------------       
-- Shift out data process
------------------------------------------------------------------------    
    WRITE_DATA: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if CState = sWriteData or CState = sSendAck or 
               CState = sReadAck then
                if FallScl = '1' then
                    SDA_O <= TempOut(7);
                    TempOut <= TempOut(6 downto 0) & '0';
                end if;
                if CState = sReadAck then
                    if RiseScl = '1' then
                        TempOut <= D_I;
                    end if;
                end if;
            else
                SDA_O <= '0'; -- Ack
            end if;
        end if;
    end process WRITE_DATA;

------------------------------------------------------------------------       
-- Read the RnW command bit process
------------------------------------------------------------------------    
    READ_RNW: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if CState = sCheckRnw then
                Rnw <= TempIn(0);
            end if;
        end if;
    end process READ_RNW;
    
    READ_ACK: process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if CState = sReadAck then
                if RiseScl = '1' then
                    Ack <= not SDA_I;
                end if;
            end if;
        end if;
    end process READ_ACK;
    
    -- Generate buffer select bit (T)
    SDA_T <= '0' when CState = sSendAck or CState = sSendReadAck or 
                      CState = sWriteData else '1';
    
    -- Generate data request signal
    D_REQ_O <= '1' when CState = sWriteData and NState = sReadAck else '0';
    
    -- Generate output reset (when transaction is over)
    RST_O <= '1' when P = '1' else '0';

end Behavioral;

