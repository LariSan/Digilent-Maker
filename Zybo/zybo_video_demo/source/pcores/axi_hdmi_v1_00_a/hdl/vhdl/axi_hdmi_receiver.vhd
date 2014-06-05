-------------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2011, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME            : axi_dvi_receiver.vhd
-- MODULE NAME          : AXI DVI Receiver
-- AUTHOR               : Mihaita Nagy
-- AUTHOR'S EMAIL       : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0 	    2011-10-21   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : DVI, HDMI, TMDS, AXI4-Stream
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity axi_hdmi_receiver is
    generic(
        C_USE_S2MM_DATA_ALIGN   : integer := 0;
        C_AXI_STREAM_DATA_WIDTH : integer := 32
    );
    port(
        -- Global clock
        ACLK_I                  : in    std_logic;
        
        -- VDMA frame sync
        S2MM_FSYNC_IN           : in    std_logic;
        
        -- AXI4-Stream Interface
        M_AXIS_S2MM_ACLK        : out   std_logic;
		M_AXIS_S2MM_ARESETN     : in    std_logic;
		M_AXIS_S2MM_TVALID      : out   std_logic;
		M_AXIS_S2MM_TDATA       : out   std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        M_AXIS_S2MM_TKEEP       : out   std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		M_AXIS_S2MM_TLAST       : out   std_logic;
		M_AXIS_S2MM_TREADY      : in    std_logic;
        
        -- HDMI Signals
        TMDS_RX_CLK_P           : in    std_logic;
        TMDS_RX_CLK_N           : in    std_logic;
        TMDS_RX_2_P             : in    std_logic;
        TMDS_RX_2_N             : in    std_logic;
        TMDS_RX_1_P             : in    std_logic;
        TMDS_RX_1_N             : in    std_logic;
        TMDS_RX_0_P             : in    std_logic;
        TMDS_RX_0_N             : in    std_logic
    );
end axi_hdmi_receiver;

architecture Behavioral of axi_hdmi_receiver is

------------------------------------------------------------------------
-- Local Types
------------------------------------------------------------------------

-- States of the main FSM
type States is (sIdle, sWaitTready, sWaitVsync, sReleaseReset);

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal Reset        : std_logic;

-- Data alignment engine signals
signal AlignDE      : std_logic;
signal DataAligned  : std_logic_vector(31 downto 0);
signal AlignAE      : std_logic;

-- Current and Next State signals, for the main FSM
signal CState       : States := sIdle;
signal NState       : States := sIdle;

-- Color signals
signal Red          : std_logic_vector(7 downto 0);
signal Green        : std_logic_vector(7 downto 0);
signal Blue         : std_logic_vector(7 downto 0);
signal RGB_int      : std_logic_vector(23 downto 0);
signal RGB_int2     : std_logic_vector(23 downto 0);
signal RGB_dly      : std_logic_vector(23 downto 0);

-- Synchro signals
signal VDE          : std_logic;
signal VDE_dly      : std_logic;
signal VS           : std_logic;

signal CLK_int      : std_logic;
signal ACLK         : std_logic;

signal fsync        : std_logic;
signal fsync_int    : std_logic;
signal fsync_int2   : std_logic;
signal fsync_int3   : std_logic;
signal fsync_int4   : std_logic;

signal vs_int       : std_logic;
signal vs_int2      : std_logic;
signal vs_int3      : std_logic;
signal vs_sync      : std_logic;
signal tready_int   : std_logic;
signal tready       : std_logic;

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

-- Data alignment engine
component data_align
    port(   CLK_I            : in    std_logic;
            RST_I            : in    std_logic;
            AE_I             : in    std_logic;
            D_I              : in    std_logic_vector(23 downto 0);
            D_O              : out   std_logic_vector(31 downto 0);
            DE_O             : out   std_logic);
end component;

-- DVI Decoder
component dvi_decoder
    port (  tmdsclk_p       : in    std_logic;
            tmdsclk_n       : in    std_logic;
            blue_p          : in    std_logic;
            green_p         : in    std_logic;
            red_p           : in    std_logic;
            blue_n          : in    std_logic;
            green_n         : in    std_logic;
            red_n           : in    std_logic;
            exrst           : in    std_logic;
            reset           : out   std_logic;
            pclk            : out   std_logic;
            pclkx2          : out   std_logic;
            pclkx10         : out   std_logic;
            pllclk0         : out   std_logic;
            pllclk1         : out   std_logic;
            pllclk2         : out   std_logic;
            pll_lckd        : out   std_logic;
            serdesstrobe    : out   std_logic;
            tmdsclk         : out   std_logic;
            hsync           : out   std_logic;
            vsync           : out   std_logic;
            de              : out   std_logic;
            blue_vld        : out   std_logic;
            green_vld       : out   std_logic;
            red_vld         : out   std_logic;
            blue_rdy        : out   std_logic;
            green_rdy       : out   std_logic;
            red_rdy         : out   std_logic;
            psalgnerr       : out   std_logic;
            sdout           : out   std_logic_vector(29 downto 0);
            red             : out   std_logic_vector(7 downto 0);
            green           : out   std_logic_vector(7 downto 0);
            blue            : out   std_logic_vector(7 downto 0));
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

    Reset <= not M_AXIS_S2MM_ARESETN;
    M_AXIS_S2MM_ACLK <= ACLK;
    CLK_int <= ACLK;

------------------------------------------------------------------------
-- Instantiate the alignment engine
------------------------------------------------------------------------
    USE_DATA_ALIGN: if C_USE_S2MM_DATA_ALIGN = 1 generate
    Inst_DataAlign: data_align
    port map(   
        CLK_I            => CLK_int,
        RST_I            => Reset,
        AE_I             => AlignAE,
        D_I              => RGB_dly,
        D_O              => DataAligned,
        DE_O             => AlignDE);
    end generate;

------------------------------------------------------------------------    
-- Instantiate the DVI decoder    
------------------------------------------------------------------------    
    Inst_DVIReceiver: dvi_decoder
    port map(
        tmdsclk_p       => TMDS_RX_CLK_P,
        tmdsclk_n       => TMDS_RX_CLK_N,
        blue_p          => TMDS_RX_0_P,
        green_p         => TMDS_RX_1_P,
        red_p           => TMDS_RX_2_P,
        blue_n          => TMDS_RX_0_N,
        green_n         => TMDS_RX_1_N,
        red_n           => TMDS_RX_2_N,
        exrst           => Reset,
        reset           => open,
        pclk            => ACLK,
        pclkx2          => open,
        pclkx10         => open,
        pllclk0         => open,
        pllclk1         => open,
        pllclk2         => open,
        pll_lckd        => open,
        serdesstrobe    => open,
        tmdsclk         => open,
        hsync           => open,
        vsync           => VS,
        de              => VDE,
        blue_vld        => open,
        green_vld       => open,
        red_vld         => open,
        blue_rdy        => open,
        green_rdy       => open,
        red_rdy         => open,
        psalgnerr       => open,
        sdout           => open,
        red             => Red,
        green           => Green,
        blue            => Blue);
    
------------------------------------------------------------------------
-- Synchronizing FSYNC impulse to ACLK clock domain
------------------------------------------------------------------------
    -- first stage
    SYNC_FSYNC_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => fsync_int,
        C       => CLK_int,
        D       => S2MM_FSYNC_IN);
    
    -- second stage
    SYNC_FSYNC_2: process(CLK_int)
    begin
        if rising_edge(CLK_int) then
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
        C       => ACLK_I,
        D       => fsync_int2);
    
    -- fourth stage
    SYNC_FSYNC_4: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => fsync_int4,
        C       => ACLK_I,
        D       => fsync_int3);
    
    -- generate the one pulse fsync (synchronous to ACLK)
    fsync <= fsync_int3 xor fsync_int4;

------------------------------------------------------------------------
-- Synchronizing VS, TREADY and VDE to ACLK_I
------------------------------------------------------------------------
    -- fisrt stage of VS
    SYNC_VS_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => vs_int,
        C       => ACLK_I,
        D       => VS);
    
    -- second stage of VS
    SYNC_VS_2: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => vs_int2,
        C       => ACLK_I,
        D       => vs_int);
    
    -- third stage of VS
    SYNC_VS_3: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => vs_int3,
        C       => ACLK_I,
        D       => vs_int2);
    
    vs_sync <= '1' when vs_int = '1' and vs_int2 = '0' else '0';
    
    -- fisrt stage of TREADY
    SYNC_TREADY_1: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => tready,
        C       => ACLK_I,
        D       => tready_int);
    
    -- second stage of TREADY
    SYNC_TREADY_2: FD
    generic map(
        INIT    => '0') 
    port map(
        Q       => tready_int,
        C       => ACLK_I,
        D       => M_AXIS_S2MM_TREADY);
        
------------------------------------------------------------------------    
-- Delay VDE and RGB data with one clock cycle
------------------------------------------------------------------------
    DELAY: process(CLK_int)
    begin
        if rising_edge(CLK_int) then -- PCLK
            VDE_dly <= VDE;
            RGB_dly <= Red & Green & Blue;
        end if;
    end process DELAY;
    
    M_AXIS_S2MM_TVALID <= VDE_dly and AlignDE when CState = sReleaseReset and C_USE_S2MM_DATA_ALIGN = 1 else 
                          VDE_dly when CState = sReleaseReset else '0';
    AlignAE <= '1' when CState = sReleaseReset else '0';
    M_AXIS_S2MM_TKEEP <= x"F" when VDE_dly = '1' else x"0";
    M_AXIS_S2MM_TLAST <= '1' when VDE = '0' and VDE_dly = '1' and CState = sReleaseReset else '0';

------------------------------------------------------------------------    
-- Initialization of the State Machine
------------------------------------------------------------------------
    FSM_REGISTER_STATES: process(ACLK_I)
    begin
        if rising_edge(ACLK_I) then
            if M_AXIS_S2MM_ARESETN = '0' then
                CState <= sIdle;
            else
                CState <= NState;
            end if;
        end if;
    end process FSM_REGISTER_STATES;

------------------------------------------------------------------------    
-- The Finite State Machine transitions
------------------------------------------------------------------------
    --FSYNC_DBG <= fsync;
    --VS_DBG <= vs_sync;
    --TREADY_DBG <= tready;
    --TVALID_DBG <= VDE_dly and AlignDE when CState = sReleaseReset and C_USE_S2MM_DATA_ALIGN = 1 else 
    --              VDE_dly when CState = sReleaseReset else '0';
    --TLAST_DBG <= '1' when VDE = '0' and VDE_dly = '1' and CState = sReleaseReset else '0';
    
    FSM_TRANSITIONS: process(CState, fsync, vs_sync, tready)
    begin
        NState <= CState;
        case CState is
            when sIdle =>
                if fsync = '1' then
                    NState <= sWaitTready;
                else
                    NState <= sIdle;
                end if;
            when sWaitTready =>
                if tready = '1' then
                    NState <= sWaitVsync;
                else
                    NState <= sWaitTready;
                end if;
            when sWaitVsync =>
                if vs_sync = '1' then
                    NState <= sReleaseReset;
                else
                    NState <= sWaitVsync;
                end if;
            when sReleaseReset => NState <= sReleaseReset;
            when others => NState <= sIdle;
        end case;
    end process FSM_TRANSITIONS;
    
    -- Assigning the output data signals
    gen1: if C_USE_S2MM_DATA_ALIGN = 1 generate
        M_AXIS_S2MM_TDATA <= DataAligned;
    end generate;
    
    gen2: if C_USE_S2MM_DATA_ALIGN = 0 generate
        M_AXIS_S2MM_TDATA(23 downto 0) <= RGB_dly;
        M_AXIS_S2MM_TDATA(31 downto 24) <= (others => '0');
    end generate;

end Behavioral;

