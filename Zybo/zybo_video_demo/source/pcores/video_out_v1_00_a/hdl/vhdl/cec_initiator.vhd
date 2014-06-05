-------------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2013, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME      : cec_initiator.vhd
-- MODULE NAME    : CEC Initiator
-- AUTHOR         : Mihaita Nagy
-- AUTHOR'S EMAIL : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0      2013-10-04   Mihaita Nagy   Created
-------------------------------------------------------------------------------
-- KEYWORDS       : General file searching keywords, leave blank if none.
-------------------------------------------------------------------------------
-- DESCRIPTION    : Short description of functionality.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity cec_initiator is
   generic(
      C_CLOCK_FREQ_MHZ  : integer := 100 -- clk_i frequency in MHz
   );
   port(
      clk_i    : in  std_logic;
      rst_i    : in  std_logic;
      
      -- Data blocks
      data00_i : in  std_logic_vector(8 downto 0);
      data01_i : in  std_logic_vector(8 downto 0);
      data02_i : in  std_logic_vector(8 downto 0);
      data03_i : in  std_logic_vector(8 downto 0);
      data04_i : in  std_logic_vector(8 downto 0);
      data05_i : in  std_logic_vector(8 downto 0);
      data06_i : in  std_logic_vector(8 downto 0);
      data07_i : in  std_logic_vector(8 downto 0);
      data08_i : in  std_logic_vector(8 downto 0);
      data09_i : in  std_logic_vector(8 downto 0);
      data10_i : in  std_logic_vector(8 downto 0);
      data11_i : in  std_logic_vector(8 downto 0);
      data12_i : in  std_logic_vector(8 downto 0);
      data13_i : in  std_logic_vector(8 downto 0);
      data14_i : in  std_logic_vector(8 downto 0);
      data15_i : in  std_logic_vector(8 downto 0);
      
      -- Status flags
      fDone    : out std_logic;
      fBusy    : out std_logic;
      fError   : out std_logic;
      
      -- CEC interface
      cec_i    : in  std_logic;
      cec_o    : out std_logic;
      cec_t    : out std_logic
   );
end cec_initiator;

architecture Behavioral of cec_initiator is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Local Type Declarations
------------------------------------------------------------------------
type state_type is (sIdle, sCheckBusBusy, sWaitOnBusy, sSendStartA, 
   sSendStartB, sSendData, sSendDataA, sSendDataB, sPrepAck, sReadAck, 
   sShiftBit, sCheckEom, sIncByte, sWaitDone, sDone, sWaitError, sError); 
type rom_type is array (0 to 15) of std_logic_vector(8 downto 0);  

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------
-- Nr of retransmit times for a message
constant MESSAGE_RETRANSMIT_TIMES : integer := 5;
-- Max. value for the counters
constant T_MAX_CNT      : integer := 4700 * C_CLOCK_FREQ_MHZ;
-- Start low duration Min/Avg/Max values
constant T_STARTA_MIN   : integer := 3500 * C_CLOCK_FREQ_MHZ;
constant T_STARTA       : integer := 3700 * C_CLOCK_FREQ_MHZ;
constant T_STARTA_MAX   : integer := 3900 * C_CLOCK_FREQ_MHZ;
-- Start total duration Min/Avg/Max values
constant T_STARTB_MIN   : integer := 4300 * C_CLOCK_FREQ_MHZ;
constant T_STARTB       : integer := 4500 * C_CLOCK_FREQ_MHZ;
constant T_STARTB_MAX   : integer := 4700 * C_CLOCK_FREQ_MHZ;
-- Nominal sample time
constant T_SAMPLE_MIN   : integer := 850  * C_CLOCK_FREQ_MHZ;
constant T_SAMPLE       : integer := 1050 * C_CLOCK_FREQ_MHZ;
constant T_SAMPLE_MAX   : integer := 1250 * C_CLOCK_FREQ_MHZ;
-- Low-high transition when indicating logical 1 Min/Avg/Max values
constant T_TRANS_1_MIN  : integer := 400  * C_CLOCK_FREQ_MHZ;
constant T_TRANS_1      : integer := 600  * C_CLOCK_FREQ_MHZ;
constant T_TRANS_1_MAX  : integer := 800  * C_CLOCK_FREQ_MHZ;
-- Low-high transition when indicating logical 0 Min/Avg/Max values
constant T_TRANS_0_MIN  : integer := 1300 * C_CLOCK_FREQ_MHZ;
constant T_TRANS_0      : integer := 1500 * C_CLOCK_FREQ_MHZ;
constant T_TRANS_0_MAX  : integer := 1700 * C_CLOCK_FREQ_MHZ;
-- Normal data bit period Min/Avg/Max values
constant T_BIT_MIN      : integer := 2050 * C_CLOCK_FREQ_MHZ;
constant T_BIT          : integer := 2400 * C_CLOCK_FREQ_MHZ;
constant T_BIT_MAX      : integer := 2750 * C_CLOCK_FREQ_MHZ;
-- Low-High transition when the follower indicates ACK Min/Avg/Max values
constant T_ACKEND_MIN   : integer := 1300 * C_CLOCK_FREQ_MHZ;
constant T_ACKEND       : integer := 1500 * C_CLOCK_FREQ_MHZ;
constant T_ACKEND_MAX   : integer := 1700 * C_CLOCK_FREQ_MHZ;

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- CEC data
signal dCecIn, ddCecIn, dCecOut : std_logic;
-- register data
signal dInput : rom_type;
signal dDataIn, ddDataIn : std_logic_vector(8 downto 0);
signal fStartTx : std_logic;
-- State machine local types
signal cState, nState : state_type;

signal cntByte : integer range 0 to 15 := 0;
signal cntBit : integer range 0 to 8 := 0;
signal cntBit0, cntBit1 : integer range 0 to (T_MAX_CNT * 7) := 0;
signal dTemp : std_logic_vector(8 downto 0);
-- Status flags
signal fBroadcast : std_logic;
--signal fDone, fError : std_logic;

attribute FSM_ENCODING : string;
attribute FSM_ENCODING of cState: signal is "GRAY";

signal cStateDebug, cStateDebugg : std_logic_vector(4 downto 0) := "00000";
signal fErrorDebug, fDoneDebug, fBusyDebug, dCecInDebug, dCecOutDebug, fStartTxDebug : std_logic;
signal cntBit0Debug, cntBit1Debug : std_logic_vector(23 downto 0);

attribute KEEP : string;
attribute KEEP of dCecInDebug: signal is "TRUE";
attribute KEEP of dCecOutDebug: signal is "TRUE";
attribute KEEP of cStateDebug: signal is "TRUE";
attribute KEEP of fStartTxDebug: signal is "TRUE";
attribute KEEP of fErrorDebug: signal is "TRUE";
attribute KEEP of fDoneDebug: signal is "TRUE";
attribute KEEP of fBusyDebug: signal is "TRUE";
attribute KEEP of cntBit0Debug: signal is "TRUE";
attribute KEEP of cntBit1Debug: signal is "TRUE";

begin
   
-- DEBUG
   cStateDebugg <= "00000" when cState = sIdle else         -- 0
                   "00001" when cState = sCheckBusBusy else -- 1
                   "00010" when cState = sWaitOnBusy else   -- 2
                   "00011" when cState = sSendStartA else   -- 3
                   "00100" when cState = sSendStartB else   -- 4
                   "00101" when cState = sSendData else     -- 5
                   "00110" when cState = sSendDataA else    -- 6
                   "00111" when cState = sSendDataB else    -- 7
                   "01000" when cState = sPrepAck else      -- 8
                   "01001" when cState = sReadAck else      -- 9
                   "01010" when cState = sShiftBit else     -- 10
                   "01011" when cState = sCheckEom else     -- 11
                   "01100" when cState = sIncByte else      -- 12
                   "01101" when cState = sWaitDone else     -- 13
                   "01110" when cState = sDone else         -- 14
                   "01111" when cState = sWaitError else    -- 15
                   "10000"; -- sError                       -- 16
   
    process(clk_i) begin
      if rising_edge(clk_i) then
         cStateDebug <= cStateDebugg;
      end if;
   end process;
   
   cntBit0Debug <= conv_std_logic_vector(cntBit0, 24);
   cntBit1Debug <= conv_std_logic_vector(cntBit1, 24);
   
------------------------------------------------------------------------
-- Store input data as an array
------------------------------------------------------------------------
   STORE_REGS: process(clk_i) begin
      if rising_edge(clk_i) then
         dInput(0) <= data00_i;
         dInput(1) <= data01_i;
         dInput(2) <= data02_i;
         dInput(3) <= data03_i;
         dInput(4) <= data04_i;
         dInput(5) <= data05_i;
         dInput(6) <= data06_i;
         dInput(7) <= data07_i;
         dInput(8) <= data08_i;
         dInput(9) <= data09_i;
         dInput(10) <= data10_i;
         dInput(11) <= data11_i;
         dInput(12) <= data12_i;
         dInput(13) <= data13_i;
         dInput(14) <= data14_i;
         dInput(15) <= data15_i;
      end if;
   end process STORE_REGS;

------------------------------------------------------------------------
-- Input edge detection (both falling and rising)
------------------------------------------------------------------------
   DETECT_EDGE: process(clk_i) begin
      if rising_edge(clk_i) then
         dCecIn <= cec_i;
         dCecInDebug <= cec_i;
      end if;
   end process DETECT_EDGE;
   
------------------------------------------------------------------------
-- Start of a transaction detection process, based on the change of data 
-- in the register 'data00_i'.
-- Note: make sure to have all the other registers previously written
-- before writing to this register.
------------------------------------------------------------------------
   DETECT_DATA: process(clk_i) begin
      if rising_edge(clk_i) then
         dDataIn <= dInput(0);
         ddDataIn <= dDataIn;
      end if;
   end process DETECT_DATA;
   
   fStartTx <= '1' when ddDataIn /= dDataIn else '0';
   
   process(clk_i) begin
      if rising_edge(clk_i) then
         fStartTxDebug <= fStartTx;
      end if;
   end process;

------------------------------------------------------------------------
-- FSM
------------------------------------------------------------------------
   SYNC_PROC: process(clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i = '1' then
            cState <= sIdle;
            fDone <= '0';
            fError <= '0';
            fErrorDebug <= '0';
            fDoneDebug <= '0';
         else
            cState <= nState;
            case(cState) is
               when sIdle =>
                  cntByte <= 0;
                  cntBit0 <= 0;
                  cntBit1 <= 0;
                  cntBit <= 0;
                  fBroadcast <= '0';
                  fBusy <= '0';
                  fBusyDebug <= '0';
                  dCecOut <= '1';
               when sCheckBusBusy =>
                  cntBit0 <= 0;
                  cntBit1 <= cntBit1 + 1;
                  dCecOut <= '1';
               when sWaitOnBusy =>
                  cntBit0 <= cntBit0 + 1;
                  fBusy <= '1';
                  fBusyDebug <= '1';
                  dCecOut <= '1';
               when sSendStartA =>
                  cntBit1 <= 0;
                  cntBit0 <= cntBit0 + 1;
                  fDone <= '0';
                  fError <= '0';
                  fErrorDebug <= '0';
                  fDoneDebug <= '0';
                  dCecOut <= '0';
               when sSendStartB =>
                  cntBit0 <= 0;
                  cntBit1 <= cntBit1 + 1;
                  dCecOut <= '1';
               when sSendData =>
                  cntBit1 <= 0;
                  cntBit <= 0;
                  dTemp <= dInput(cntByte);
                  fBroadcast <= dInput(cntByte)(4) and 
                                dInput(cntByte)(3) and 
                                dInput(cntByte)(2) and 
                                dInput(cntByte)(1);
                  dCecOut <= '1';
               when sSendDataA =>
                  cntBit0 <= cntBit0 + 1;
                  dCecOut <= '0';
               when sSendDataB =>
                  cntBit0 <= 0;
                  cntBit1 <= cntBit1 + 1;
                  dCecOut <= '1';
               when sPrepAck =>
                  cntBit1 <= 0;
                  cntBit0 <= cntBit0 + 1;
                  dCecOut <= '0';
               when sReadAck =>
                  cntBit0 <= 0;
                  cntBit1 <= cntBit1 + 1;
                  dCecOut <= '1';
               when sShiftBit =>
                  cntBit1 <= 0;
                  cntBit <= cntBit + 1;
                  dTemp <= dTemp(7 downto 0) & '0';
                  dCecOut <= '1';
               when sCheckEom =>
                  cntBit0 <= cntBit0 + 1;
                  dCecOut <= '1';
               when sIncByte =>
                  cntBit0 <= 0;
                  cntByte <= cntByte + 1;
                  dCecOut <= '1';
               when sWaitDone =>
                  cntBit0 <= cntBit0 + 1;
                  dCecOut <= '1';
               when sDone =>
                  fDone <= '1';
                  fDoneDebug <= '1';
                  dCecOut <= '1';
               when sWaitError =>
                  cntBit1 <= 0;
                  cntBit0 <= cntBit0 + 1;
                  dCecOut <= '1';
               when sError =>
                  fError <= '1';
                  fErrorDebug <= '1';
                  dCecOut <= '1';
               when others =>
                  cntByte <= 0;
                  cntBit0 <= 0;
                  cntBit1 <= 0;
                  cntBit <= 0;
                  dTemp <= dInput(cntByte);
                  fDone <= '0';
                  fError <= '0';
                  fErrorDebug <= '0';
                  fDoneDebug <= '0';
                  fBroadcast <= '0';
                  dCecOut <= '1';
            end case;
         end if;
      end if;
   end process SYNC_PROC;
   
   cec_o <= dCecOut;
   cec_t <= dCecOut;
   dCecOutDebug <= dCecOut;
 
   NEXT_STATE_DECODE: process(cState, fStartTx, fBroadcast, 
   cntBit0, cntBit1, dCecIn, cntBit, cntByte, dTemp)
   begin
      nState <= cState;
      case(cState) is
         when sIdle => -- 0
            if fStartTx = '1' then
               nState <= sCheckBusBusy;
            end if;
         when sCheckBusBusy => -- 1
            if dCecIn = '0' then
               nState <= sWaitOnBusy;
            else -- bus is free
               if cntByte /= 0 then
                  nState <= sSendData;
               else
                  nState <= sSendStartA;
               end if;
            end if;
         when sWaitOnBusy => -- 2
            if cntBit1 = MESSAGE_RETRANSMIT_TIMES then
               nState <= sWaitError;
            elsif cntBit0 = T_BIT * 7 then
               nState <= sCheckBusBusy;
            end if;
         when sSendStartA => -- 3
            if cntBit0 = T_STARTA then
               nState <= sSendStartB;
            end if;
         when sSendStartB => -- 4
            if cntBit1 = (T_STARTB - T_STARTA) then
               nState <= sSendData;
            end if;
         when sSendData => nState <= sSendDataA; -- 5
         when sSendDataA => -- 6
            if dTemp(8) = '1' then -- send logical 1
               if cntBit0 = T_TRANS_1 then
                  nState <= sSendDataB;
               end if;
            else -- send logical 0
               if cntBit0 = T_TRANS_0 then
                  nState <= sSendDataB;
               end if;
            end if;
         when sSendDataB => -- 7
            if dTemp(8) = '1' then -- send logical 1
               if cntBit1 = (T_BIT - T_TRANS_1) then
                  if cntBit = 8 then -- done sending a byte
                     nState <= sPrepAck;
                  else
                     nState <= sShiftBit;
                  end if;
               end if;
            else
               if cntBit1 = (T_BIT - T_TRANS_0) then
                  if cntBit = 8 then -- done sending a byte
                     nState <= sPrepAck;
                  else
                     nState <= sShiftBit;
                  end if;
               end if;
            end if;
         when sPrepAck => -- 8
            if cntBit0 = T_TRANS_1 then
               nState <= sReadAck;
            end if;
         when sReadAck => -- 9
            if cntBit1 = (T_SAMPLE_MAX - T_TRANS_1) then
               nState <= sWaitError; -- not acknowledged
            elsif cntBit1 >= (T_SAMPLE_MAX - T_SAMPLE_MIN) then
               if fBroadcast = '1' then -- broadcast message
                  if dCecIn = '0' then
                     nState <= sReadAck;
                  else -- acknowledged before timeout
                     nState <= sCheckEom;
                  end if;
               else
                  if dCecIn = '1' then
                     nState <= sReadAck;
                  else -- acknowledged before timeout
                     nState <= sCheckEom;
                  end if;
               end if;
            end if;
         when sShiftBit => nState <= sSendDataA; -- 10
         when sCheckEom => -- 11
            if cntBit0 = (T_BIT - T_TRANS_1 - cntBit1) then
               if dTemp(8) = '1' then
                  nState <= sWaitDone;
               else
                  nState <= sIncByte;
               end if;
            end if;
         when sIncByte => nState <= sCheckBusBusy; -- 12
         when sWaitDone => -- 13
            if cntBit0 = T_BIT * 7 then
               nState <= sDone;
            end if;
         when sDone => nState <= sIdle; -- 14
         when sWaitError => -- 15
            if cntBit0 = T_BIT * 7 then
               nState <= sError;
            end if;
         when sError => nState <= sIdle;
         when others => nState <= sIdle;
      end case;      
   end process NEXT_STATE_DECODE;

end Behavioral;

