-------------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2011, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME            : ClkGen.vhd
-- MODULE NAME          : Clock Generator
-- AUTHOR               : Mihaita Nagy
-- AUTHOR'S EMAIL       : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0 	    2011-11-02   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : DVI, HDMI, TMDS, AXI4-Stream
-------------------------------------------------------------------------------
-- NOTE : This entity generates the clocks needed for the DVI Transmitter
-- according to the user-given display resolution.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
use ieee.math_real.all;
use ieee.std_logic_unsigned.ALL;

library unisim;
use unisim.vcomponents.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity clk_gen is
    port(
        CLK_I       : in    std_logic; -- System clock (100MHz)
        RST_I       : in    std_logic; -- System reset
        RES_I       : in    std_logic_vector(31 downto 0); -- Display resolution
        CLK_O       : out   std_logic; -- Output clock x1
        CLK_X2_O    : out   std_logic; -- Output clock x2
        CLK_X10_O   : out   std_logic; -- Output clock x10
        SERSTRB_O   : out   std_logic; -- Serdes Strobe
        READY_O     : out   std_logic
    );
end clk_gen;

architecture Behavioral of clk_gen is

------------------------------------------------------------------------
-- Local types
------------------------------------------------------------------------

type StateType is (sIdle, sProgM, sProgMWait, sProgD, sProgDWait, sGo, sWait);

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal CState       : StateType;
signal NState       : StateType;

signal DcmProgClk   : std_logic;
signal DcmProgEn    : std_logic;
signal DcmProgD     : std_logic;
signal DcmProgDone  : std_logic;
signal DcmLckd      : std_logic;
signal DcmRst       : std_logic;
signal RstDbnc      : std_logic;
signal RstDbncQ     : std_logic_vector(9 downto 0);
signal RstDbncTemp  : std_logic_vector(9 downto 0);
signal RstQ         : std_logic_vector(99 downto 0) := (99 => '0', others => '1');
signal Start_Up_Rst : std_logic;

signal progEn       : std_logic;
signal loadRegEn    : std_logic;
signal shiftReg     : std_logic;

signal DcmProgReg   : std_logic_vector(9 downto 0);
signal loadReg      : std_logic_vector(9 downto 0);
signal prevRes      : std_logic_vector(31 downto 0);

signal DcmM         : integer range 0 to 255;
signal DcmD         : integer range 0 to 255;
signal bitCount     : integer range 0 to 15 := 0;

signal DcmClkO      : std_logic;
signal ClkFb        : std_logic;
signal PllRst       : std_logic;
signal PllOut_x10   : std_logic;
signal PllOut_x2    : std_logic;
signal PllOut_x1    : std_logic;
signal CLK_X2_int   : std_logic;
signal BufPllLckd   : std_logic;
signal PllLckd      : std_logic;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin
    
------------------------------------------------------------------------
--4-bit Shift Register For resetting the DCM on startup (Xilinx AR14425)
--Asserts Start_Up_Rst for 4 clock periods
------------------------------------------------------------------------
    SRL16_inst: SRL16
    generic map (
        INIT => X"000F"
    )
    port map (
        Q => Start_Up_Rst,  -- SRL data output
        A0 => '1',          -- Select[0] input
        A1 => '1',          -- Select[1] input
        A2 => '0',          -- Select[2] input
        A3 => '0',          -- Select[3] input
        CLK => CLK_I,       -- Clock input
        D => '0'            -- SRL data input
    );	

------------------------------------------------------------------------
-- Debounce Reset
------------------------------------------------------------------------
    RstDbncQ(0) <= RST_I;
    
    DBNC_PROC: for i in 1 to RstDbncQ'high generate
        process(CLK_I)
        begin
            if rising_edge(CLK_I) then
                RstDbncQ(i) <= RstDbncQ(i-1);
            end if;
        end process;
    end generate;

    RstDbncTemp(0) <= RstDbncQ(0);

    DBNCTEMP_PROC: for i in 1 to RstDbncQ'high-1 generate
        RstDbncTemp(i) <= RstDbncTemp(i-1) and RstDbncQ(i);
    end generate;	

    RstDbnc <= RstDbncTemp(RstDbncQ'high-1) and (not RstDbncQ(RstDbncQ'high));

    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if RstDbnc = '1' or RstQ(99) = '1' then
                RstQ <= RstQ(98 downto 0) & RstQ(99);
            end if;
        end if;
    end process;
	
	DcmRst <= not RstQ(98) or not RstQ(97) or not RstQ(96) or Start_Up_Rst;
    
------------------------------------------------------------------------
-- Instantiate reconfigurable DCM
------------------------------------------------------------------------
    DCM_CLKGEN_inst: DCM_CLKGEN
    generic map (
        CLKFXDV_DIVIDE  => 2,           -- CLKFXDV divide value (2, 4, 8, 16, 32)
        CLKFX_DIVIDE    => 125,         -- Divide value - D - (1-256)
        CLKFX_MULTIPLY  => 93,          -- Multiply value - M - (2-256)
        CLKFX_MD_MAX    => 0.0,         -- Specify maximum M/D ratio for timing anlysis
        CLKIN_PERIOD    => 10.0,        -- Input clock period specified in nS
        SPREAD_SPECTRUM => "NONE",      -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
                                        -- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
        STARTUP_WAIT    => FALSE        -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
    )
    port map (
        CLKFX           => DcmClkO,     -- 1-bit output: Generated clock output
        CLKFX180        => open,        -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
        CLKFXDV         => open,        -- 1-bit output: Divided clock output
        LOCKED          => DcmLckd,     -- 1-bit output: Locked output
        PROGDONE        => DcmProgDone, -- 1-bit output: Active high output to indicate the successful re-programming
        PROGCLK         => DcmProgClk,  -- 1-bit input: Clock input for M/D reconfiguration
        PROGDATA        => DcmProgD,    -- 1-bit input: Serial data input for M/D reconfiguration
        PROGEN          => DcmProgEn,   -- 1-bit input: Active high program enable
        STATUS          => open,        -- 2-bit output: DCM_CLKGEN status
        CLKIN           => CLK_I,       -- 1-bit input: Input clock
        FREEZEDCM       => open,        -- 1-bit input: Prevents frequency adjustments to input clock
        RST             => DcmRst       -- 1-bit input: Reset input pin
    );

------------------------------------------------------------------------    
-- PLL Base - it generates the x2 and x10 clocks
------------------------------------------------------------------------
    PLL_BASE_inst: PLL_BASE
    generic map (
        BANDWIDTH               => "OPTIMIZED", -- "HIGH", "LOW" or "OPTIMIZED" 
        CLKFBOUT_MULT           => 10,          -- Multiply value for all CLKOUT clock outputs (1-64)
        CLKFBOUT_PHASE          => 0.0,         -- Phase offset in degrees of the clock feedback output (0.0-360.0).
        CLKIN_PERIOD            => 10.0,        -- Input clock period in ns to ps resolution (i.e. 33.333 is 30MHz).
        -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
        CLKOUT0_DIVIDE          => 1,
        CLKOUT1_DIVIDE          => 10,
        CLKOUT2_DIVIDE          => 1,
        CLKOUT3_DIVIDE          => 5,
        CLKOUT4_DIVIDE          => 1,
        CLKOUT5_DIVIDE          => 1,
        -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
        CLKOUT0_DUTY_CYCLE      => 0.5,
        CLKOUT1_DUTY_CYCLE      => 0.5,
        CLKOUT2_DUTY_CYCLE      => 0.5,
        CLKOUT3_DUTY_CYCLE      => 0.5,
        CLKOUT4_DUTY_CYCLE      => 0.5,
        CLKOUT5_DUTY_CYCLE      => 0.5,
        -- CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
        CLKOUT0_PHASE           => 0.0,
        CLKOUT1_PHASE           => 0.0,
        CLKOUT2_PHASE           => 0.0,
        CLKOUT3_PHASE           => 0.0,
        CLKOUT4_PHASE           => 0.0,
        CLKOUT5_PHASE           => 0.0,
        CLK_FEEDBACK            => "CLKFBOUT",  -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
        COMPENSATION            => "INTERNAL",  -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL" 
        DIVCLK_DIVIDE           => 1,           -- Division value for all output clocks (1-52)
        REF_JITTER              => 0.025,       -- Reference Clock Jitter in UI (0.000-0.999).
        RESET_ON_LOSS_OF_LOCK   => FALSE        -- Must be set to FALSE
    )
    port map (
        CLKFBOUT                => ClkFb,       -- 1-bit output: PLL_BASE feedback output
        -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
        CLKOUT0                 => PllOut_x10,
        CLKOUT1                 => PllOut_x1,
        CLKOUT2                 => open,
        CLKOUT3                 => PllOut_x2,
        CLKOUT4                 => open,
        CLKOUT5                 => open,
        LOCKED                  => PllLckd,     -- 1-bit output: PLL_BASE lock status output
        CLKFBIN                 => ClkFb,       -- 1-bit input: Feedback clock input
        CLKIN                   => DcmClkO,     -- 1-bit input: Clock input
        RST                     => PllRst       -- 1-bit input: Reset input
    );
    
    PllRst <= DcmRst or not DcmLckd;

------------------------------------------------------------------------
-- Route x1 clock through the global clock network
------------------------------------------------------------------------
    BUFG_inst_x1: BUFG
    port map (
        O => CLK_O,         -- 1-bit output: Clock buffer output
        I => PllOut_x1      -- 1-bit input: Clock buffer input
    );

------------------------------------------------------------------------
-- Route x2 clock through the global clock network
------------------------------------------------------------------------
    BUFG_inst_x2: BUFG
    port map (
        O => CLK_X2_int,    -- 1-bit output: Clock buffer output
        I => PllOut_x2      -- 1-bit input: Clock buffer input
    );
    
    CLK_X2_O <= CLK_X2_int;
    
------------------------------------------------------------------------
-- Route x10 clock
------------------------------------------------------------------------
    BUFPLL_inst: BUFPLL
    generic map (
        DIVIDE          => 5,           -- DIVCLK divider (1-8)
        ENABLE_SYNC     => TRUE         -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
    )
    port map (
        IOCLK           => CLK_X10_O,   -- 1-bit output: Output I/O clock
        LOCK            => BufPllLckd,  -- 1-bit output: Synchronized LOCK output
        SERDESSTROBE    => SERSTRB_O,   -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
        GCLK            => CLK_X2_int,  -- 1-bit input: BUFG clock input
        LOCKED          => PllLckd,     -- 1-bit input: LOCKED input from PLL
        PLLIN           => PllOut_x10   -- 1-bit input: Clock input from PLL
    );
    
    READY_O <= BufPllLckd;

------------------------------------------------------------------------
-- Select the appropriate DCM Multiply and Divide values according to 
-- the resolution
------------------------------------------------------------------------    
    DcmProgClk <= CLK_I;
    DcmProgEn <= progEn;
    DcmProgD <= DcmProgReg(0);
    
    M_D_SEL: process(RES_I)
    begin
        case(RES_I) is
            when x"0004B000" => -- 640x480 @ 60Hz -> 25MHz
                DcmM <= 2 - 1;
                DcmD <= 8 - 1;
            when x"00054600" => -- 720x480 @ 60Hz -> 25MHz
                DcmM <= 2 - 1;
                DcmD <= 8 - 1;
            when x"00075300" => -- 800x600 @ 60Hz -> 40MHz
                DcmM <= 2 - 1;
                DcmD <= 5 - 1;
            when x"000E1000" => -- 1280x720 @ 60Hz -> 75MHz
                DcmM <= 6 - 1;
                DcmD <= 8 - 1;
            when x"0015F900" => -- 1600x900 @ 60Hz -> 108MHz
                DcmM <= 27 - 1;
                DcmD <= 25 - 1;
            when x"001FA400" => -- 1920x1080 @ 30Hz -> 74.40MHz
                DcmM <= 93 - 1;
                DcmD <= 125 - 1;
            when others => -- 25MHz
                DcmM <= 2 - 1;
                DcmD <= 8 - 1;
        end case;
    end process M_D_SEL;
    
------------------------------------------------------------------------
-- The FSM that controls the DCM
------------------------------------------------------------------------     
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if DcmRst = '1' then
                CState <= sIdle;
            else
                CState <= NState;
            end if;
        end if;
    end process;
    
    NEXT_STATE_DECODE: process(CState, RES_I, prevRes, DcmProgDone, DcmLckd, bitCount)
    begin
        NState <= CState;
        case(CState) is
            when sIdle =>
                if DcmProgDone = '1' and DcmLckd = '1' and prevRes /= RES_I then
                    NState <= sProgD;
                end if;
            when sProgD =>
                if bitCount = 9 then
                    NState <= sProgDWait;
                end if;
			when sProgDWait =>
				if bitCount = 11 then
					NState <= sProgM;
				end if;
            when sProgM =>
                if bitCount = 9 then
                    NState <= sProgMWait;
                end if;
			when sProgMWait =>
				NState <= sGo;
			when sGo =>
				NState <= sWait;
			when sWait =>
				if DcmProgDone = '1' then
					NState <= sIdle;
				end if;
        end case;      
    end process NEXT_STATE_DECODE;
   
    OUTPUT_DECODE: process(CState, NState, DcmD, DcmM)
    begin
		loadReg <= (others => '-');
		loadRegEn <= '0';
        progEn <= '0';
        shiftReg <= '0';
		
        if CState = sIdle and NState = sProgD then
            loadReg <= conv_std_logic_vector(DcmD, 8) & "01";
			loadRegEn <= '1';
        end if;
		
        if CState = sProgDWait and NState = sProgM then
            loadReg <= conv_std_logic_vector(DcmM, 8) & "11";
			loadRegEn <= '1';
        end if;
        
		if CState = sProgD or CState = sProgM or CState = sProgDWait then
			shiftReg <= '1';
		end if;
		
		if CState = sProgD or CState = sProgM or CState = sGo then
			progEn <= '1';
		end if;
    end process OUTPUT_DECODE;
    
    SYNC_PROC: process(CLK_I)
    begin
        if rising_edge(CLK_I) then			
			if loadRegEn = '1' then
				DcmProgReg <= loadReg;
			elsif shiftReg = '1' then
				DcmProgReg <= '0' & DcmProgReg(DcmProgReg'high downto 1);
			end if;
			if loadRegEn = '1' then
				bitCount <= 0;
			elsif shiftReg = '1' then
				bitCount <= bitCount + 1;
			end if;
        end if;
   end process SYNC_PROC;
   
   process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if DcmRst = '1' then
                prevRes <= x"001FA400"; -- DCM resets to this clock frequency
            elsif CState = sWait and DcmProgDone = '1' then
                prevRes <= RES_I;
            end if;
        end if;
    end process;

end Behavioral;

