-------------------------------------------------------------------------------
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
-- 1.0 	    2011-10-12   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : DVI, HDMI, TMDS, AXI4-Stream
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.ALL;
use ieee.std_logic_arith.conv_std_logic_vector;

library unisim;
use unisim.vcomponents.all;

library work;
use work.Video.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity axi_hdmi_transmitter is
    generic(
        C_USE_MM2S_DATA_ALIGN   : integer := 0;
        C_AXI_STREAM_DATA_WIDTH : integer := 32
    );
    port(
        -- Other Signals
        ACLK                    : in    std_logic; -- System clock
        ARESETN                 : in    std_logic; -- System reset
        MM2S_FSYNC_IN           : in    std_logic; -- VDMA Frame Sync
        MM2S_BUFFER_ALMOST_EMPTY: in    std_logic;
        DISP_RES                : in    std_logic_vector(31 downto 0); -- Display Resolution
        
        -- AXI4-Stream Interface
        M_AXIS_MM2S_ACLK        : out   std_logic; -- Dynamicaly generated pixel clock
        M_AXIS_MM2S_TREADY      : out   std_logic; -- Ready to accept data in
        M_AXIS_MM2S_TDATA       : in    std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0); -- Data in 
        M_AXIS_MM2S_TKEEP       : in    std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
        M_AXIS_MM2S_TLAST       : in    std_logic; -- Optional data in qualifier
        M_AXIS_MM2S_TVALID      : in    std_logic; -- Data in is valid
        
        -- DVI Signals
        TMDS_TX_CLK_P           : out   std_logic;
        TMDS_TX_CLK_N           : out   std_logic;
        TMDS_TX_2_P             : out   std_logic;
        TMDS_TX_2_N             : out   std_logic;
        TMDS_TX_1_P             : out   std_logic;
        TMDS_TX_1_N             : out   std_logic;
        TMDS_TX_0_P             : out   std_logic;
        TMDS_TX_0_N             : out   std_logic
    );
end axi_hdmi_transmitter;

architecture Behavioral of axi_hdmi_transmitter is

------------------------------------------------------------------------
-- Local Types
------------------------------------------------------------------------

-- States of the main FSM
type States is (sIdle, sWaitTvalid, sReady);

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal Reset                : std_logic;

-- Dealignment engine signals
signal DealignAE            : std_logic;
signal DealignDE            : std_logic;
signal DataDealigned        : std_logic_vector(23 downto 0);

-- Indicates that generated clock is stable
signal Ready                : std_logic;

-- Current and Next State signals, for the main FSM
signal CState               : States;
signal NState               : States;

-- Initial reset for the VideoTimingCtl
signal InitReset            : std_logic;

-- Resolution selection
signal RES_SEL              : RESOLUTION;

-- Synchro signals
signal VDE                  : std_logic;
signal HS                   : std_logic;
signal VS                   : std_logic;

-- first stage delay
signal VDE_dly              : std_logic;
signal HS_dly               : std_logic;
signal VS_dly               : std_logic;

-- second stage delay
signal VDE_2_dly            : std_logic;
signal HS_2_dly             : std_logic;
signal VS_2_dly             : std_logic;

-- Colour signals
signal Red                  : std_logic_vector(7 downto 0);
signal Green                : std_logic_vector(7 downto 0);
signal Blue                 : std_logic_vector(7 downto 0);

-- Pixel and serialization clocks
signal PClk                 : std_logic;
signal PClk_x2              : std_logic;
signal PClk_x10             : std_logic;

-- Serdes Strobe signal
signal SerdesStrb           : std_logic;

signal resltn               : std_logic_vector(31 downto 0);

-- FSYNC sync signals
signal fsync                : std_logic;
signal fsync_int            : std_logic;
signal fsync_int2           : std_logic := '0';
signal fsync_int3           : std_logic;
signal fsync_int4           : std_logic;

signal buf_almost_empty     : std_logic;
signal buf_almost_empty_int : std_logic;
signal tvalid               : std_logic;
signal tvalid_int           : std_logic;
signal vde_sync             : std_logic;
signal vde_sync_int         : std_logic;
signal ready_sync           : std_logic;
signal ready_sync_int       : std_logic;

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
-- Data dealignment module
component data_dealign
    port(
        CLK_I           : in    std_logic;
        RST_I           : in    std_logic;
        AE_I            : in    std_logic;
        D_I             : in    std_logic_vector(31 downto 0);
        D_O             : out   std_logic_vector(23 downto 0);
        DE_O            : out   std_logic);
end component;

-- DVI Transmitter - serializes and encodes according to DVI 1.0 specs
component DVITransmitter
    port(  
        RED_I           : in    std_logic_vector(7 downto 0);
        GREEN_I         : in    std_logic_vector(7 downto 0);
        BLUE_I          : in    std_logic_vector(7 downto 0);
        HS_I            : in    std_logic;
        VS_I            : in    std_logic;
        VDE_I           : in    std_logic;
        PCLK_I          : in    std_logic;
        PCLK_X2_I       : in    std_logic;
        SERCLK_I        : in    std_logic;
        SERSTB_I        : in    std_logic;
        TMDS_TX_CLK_P   : out   std_logic;
        TMDS_TX_CLK_N   : out   std_logic;
        TMDS_TX_2_P     : out   std_logic;
        TMDS_TX_2_N     : out   std_logic;
        TMDS_TX_1_P     : out   std_logic;
        TMDS_TX_1_N     : out   std_logic;
        TMDS_TX_0_P     : out   std_logic;
        TMDS_TX_0_N     : out   std_logic);
end component;

-- Video Timing Controller - generates the synchro signals
component VideoTimingCtl
    port(  
        PCLK_I          : in    std_logic;
        RST_I           : in    std_logic;
		RSEL_I          : in    RESOLUTION;
        VDE_O           : out   std_logic;
        HS_O            : out   std_logic;
        VS_O            : out   std_logic;
        HCNT_O          : out   natural;
        VCNT_O          : out   natural);
end component;

-- Clock generator
component clk_gen
    port(
        CLK_I           : in    std_logic;
        RST_I           : in    std_logic;
        RES_I           : in    std_logic_vector(31 downto 0);
        CLK_O           : out   std_logic;
        CLK_X2_O        : out   std_logic;
        CLK_X10_O       : out   std_logic;
        SERSTRB_O       : out   std_logic;
        READY_O         : out   std_logic);
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

    Reset <= not ARESETN;
    M_AXIS_MM2S_ACLK <= PClk;

------------------------------------------------------------------------
-- Instantiate data dealignment module
------------------------------------------------------------------------    
    USE_DATA_DEALIGN: if C_USE_MM2S_DATA_ALIGN = 1 generate
    Inst_DataDealign: data_dealign
    port map(
        CLK_I           => PClk,
        RST_I           => ARESETN,
        AE_I            => DealignAE,
        D_I             => M_AXIS_MM2S_TDATA,
        D_O             => DataDealigned,
        DE_O            => DealignDE);
    end generate;
    
------------------------------------------------------------------------
-- Instantiate the DVI Transmitter module
------------------------------------------------------------------------
    Inst_DVITransmitter: DVITransmitter
    port map(   
        RED_I           => Red,
        GREEN_I         => Green,
        BLUE_I          => Blue,
        HS_I            => HS_dly,--HS_2_dly,
        VS_I            => VS_dly,--VS_2_dly,
        VDE_I           => VDE_dly,--VDE_2_dly,
        PCLK_I          => PClk,
        PCLK_X2_I       => PClk_x2,
        SERCLK_I        => PClk_x10,
        SERSTB_I        => SerdesStrb,
        TMDS_TX_CLK_P   => TMDS_TX_CLK_P,
        TMDS_TX_CLK_N   => TMDS_TX_CLK_N,
        TMDS_TX_2_P     => TMDS_TX_2_P,
        TMDS_TX_2_N     => TMDS_TX_2_N,
        TMDS_TX_1_P     => TMDS_TX_1_P,
        TMDS_TX_1_N     => TMDS_TX_1_N,
        TMDS_TX_0_P     => TMDS_TX_0_P,
        TMDS_TX_0_N     => TMDS_TX_0_N);

------------------------------------------------------------------------
-- Instantiate the Video Timing Control module
------------------------------------------------------------------------
    Inst_VideoTimingCtl: VideoTimingCtl
    port map(
        PCLK_I          => PClk,
        RST_I           => InitReset,
        RSEL_I          => RES_SEL,
        VDE_O           => VDE,
        HS_O            => HS,
        VS_O            => VS,
        HCNT_O          => open,
        VCNT_O          => open);

------------------------------------------------------------------------
-- Instantiate the Clock Generator module
------------------------------------------------------------------------
    Inst_DynClkGen: clk_gen
    port map(
        CLK_I           => ACLK,
        RST_I           => Reset,
        RES_I           => DISP_RES,--resltn,
        CLK_O           => PClk,
        CLK_X2_O        => PClk_x2,
        CLK_X10_O       => PClk_x10,
        SERSTRB_O       => SerdesStrb,
        READY_O         => Ready);

------------------------------------------------------------------------
-- Synchronizing FSYNC impulse to ACLK clock domain
------------------------------------------------------------------------
    -- first stage
    SYNC_FSYNC_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => fsync_int,
        C       => PClk,
        D       => MM2S_FSYNC_IN);
    
    -- second stage
    SYNC_FSYNC_2: process(PClk)
    begin
        if rising_edge(PClk) then
            if fsync_int = '1' then
                fsync_int2 <= not fsync_int2;
            end if;
        end if;
    end process SYNC_FSYNC_2;
    
    -- third stage
    SYNC_FSYNC_3: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => fsync_int3,
        C       => ACLK,
        D       => fsync_int2);
    
    -- fourth stage
    SYNC_FSYNC_4: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => fsync_int4,
        C       => ACLK,
        D       => fsync_int3);
    
    -- generate the one pulse fsync (synchronous to ACLK)
    fsync <= fsync_int3 xor fsync_int4;
    
------------------------------------------------------------------------
-- Synchronizing BUFFER_ALMOST_EMPTY, TVALID, VDE and READY to ACLK
------------------------------------------------------------------------
    -- first stage of BUFFER_ALMOST_EMPTY
    BUF_SYNC_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => buf_almost_empty_int,
        C       => ACLK,
        D       => MM2S_BUFFER_ALMOST_EMPTY);
    
    -- second stage of BUFFER_ALMOST_EMPTY
    BUF_SYNC_2: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => buf_almost_empty,
        C       => ACLK,
        D       => buf_almost_empty_int);
    
    -- first stage of TVALID
    TVALID_SYNC_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => tvalid_int,
        C       => ACLK,
        D       => M_AXIS_MM2S_TVALID);
    
    -- second stage of TVALID
    TVALID_SYNC_2: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => tvalid,
        C       => ACLK,
        D       => tvalid_int);
    
    -- first stage of READY
    READY_SYNC_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => ready_sync_int,
        C       => ACLK,
        D       => Ready);
    
    -- second stage of READY
    READY_SYNC_2: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => ready_sync,
        C       => ACLK,
        D       => ready_sync_int);
        
------------------------------------------------------------------------    
-- Assigning the Display Resolution according to DISP_RES
--
-- Also make sure you set the correct ACLK value for the chosen
-- resolution, as shown bellow:
--     ------------------------------------------------
--     | PCLK  | RESOLUTION | REFRESH RATE| BANDWIDTH |
--     | (MHz) |    (px)    |     (Hz)    |  (Mpx/s)  |
--     |-------|------------|-------------|-----------|
--     |   25  |   640x480  |      60     |    18.4   |    640x480
--     |   25  |   720x480  |      60     |    20.7   |    480p
--     |   40  |   800x600  |      60     |    28.8   |    800x600
--     |   75  |  1280x720  |      60     |    55.2   |    720p
--     |  108  |  1600x900  |      60     |    86.4   |    1600x900
--     | 74.40 | 1920x1080  |      30     |    62.2   |    1080p30
--     ------------------------------------------------
--
------------------------------------------------------------------------
--    process(ACLK)
--    begin
--        if rising_edge(ACLK) then
--            resltn <= DISP_RES;
--        end if;
--    end process;
    
    --resltn <= DISP_RES;
    
    RES_SEL <= R720_480P   when DISP_RES = x"00054600" else
               R800_600P   when DISP_RES = x"00075300" else
               R1280_720P  when DISP_RES = x"000E1000" else
               R1600_900P  when DISP_RES = x"0015F900" else
               R1920_1080P when DISP_RES = x"001FA400" else
               R640_480P; -- resltn -> x"0004B000"

------------------------------------------------------------------------    
-- Delay process for VDE, HS and VS
------------------------------------------------------------------------    
    DELAY_VDE: process(Pclk)
    begin
        if rising_edge(Pclk) then
            VDE_dly <= VDE;
            VDE_2_dly <= VDE_dly;
            HS_dly <= HS;
            HS_2_dly <= HS_dly;
            VS_dly <= VS;
            VS_2_dly <= VS_dly;
        end if;
    end process DELAY_VDE;

------------------------------------------------------------------------    
-- Initialization of the State Machine
------------------------------------------------------------------------
    FSM_REGISTER_STATES: process(ACLK)
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                CState <= sIdle;
            else
                CState <= NState;
            end if;
        end if;
    end process FSM_REGISTER_STATES;

------------------------------------------------------------------------    
-- The Finite State Machine transitions
--
-- This is how the initial transfer looks like:
--           _   _        _   _   _   _   _   _   _   _   _
-- ACLK   __| |_| |_... _| |_| |_| |_| |_| |_| |_| |_| |_| |__
--           ___                     |
-- FSYNC  __|   |__ ... _____________|________________________
--                        ___________|________________________
-- TVALID _________ ... _|           |
-- INIT_  _________     _____        |
-- RESET            ...      |_______|________________________
--                                ___|________________________
-- VDE    _________ ... _________|   | 
--                                ___|________________________
-- TREADY _________ ... _________|   |
--        _________     _____________|_ ___ ___ ___ ___ ___ __
-- TDATA  _________/////_______________X___X___X___X___X___X__
--
-- Note:    In state sWaitTvalid an initial wait is issued until locking 
--      bits of PLL and BUFPLL are cleaned and also unil 
--      MM2S_BUFFER_ALMOST_EMPTY deasserts indicating that the buffer is 
--      full (because the line buffer contained by the VDMA does not 
--      provide a "full" status bit, setting parameter 
--      C_MM2S_LINEBFFER_THRESH to C_MM2S_LINEBUFFER_DEPTH-1 should 
--      resolve this issue).
------------------------------------------------------------------------
    FSM_TRANSITIONS: process(CState, ready_sync, fsync, tvalid, 
    buf_almost_empty)
    begin
        NState <= CState;
        case CState is
            when sIdle =>
                if fsync = '1' then
                    NState <= sWaitTvalid;
                else
                    NState <= sIdle;
                end if;
            when sWaitTvalid =>
                if tvalid = '1' and buf_almost_empty = '0' and ready_sync = '1' then
                    NState <= sReady;
                else
                    NState <= sWaitTvalid;
                end if;
            when sReady => NState <= sReady;
            when others => NState <= sIdle;
        end case;
    end process FSM_TRANSITIONS;
    
    -- Initial reset
    InitReset <= '1' when CState = sIdle or CState = sWaitTvalid else '0';
    
    -- TREADY
    M_AXIS_MM2S_TREADY <= DealignDE and VDE_dly when C_USE_MM2S_DATA_ALIGN = 1 else VDE_dly;
    
    -- Dealignment engine enable
    DealignAE <= VDE;
    
    -- Pixel components
    Red <= DataDealigned(23 downto 16) when C_USE_MM2S_DATA_ALIGN = 1 else M_AXIS_MM2S_TDATA(23 downto 16);
    Green <= DataDealigned(15 downto 8) when C_USE_MM2S_DATA_ALIGN = 1 else M_AXIS_MM2S_TDATA(15 downto 8);
    Blue <= DataDealigned(7 downto 0) when C_USE_MM2S_DATA_ALIGN = 1 else M_AXIS_MM2S_TDATA(7 downto 0);

end Behavioral;

