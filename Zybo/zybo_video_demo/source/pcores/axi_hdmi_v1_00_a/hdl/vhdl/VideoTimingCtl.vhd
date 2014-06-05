----------------------------------------------------------------------------------
-- Company: Digilent Ro
-- Engineer: Elod Gyorgy
-- 
-- Create Date:    14:35:21 02/23/2009 
-- Design Name: 
-- Module Name:    VideoTimingCtl - Behavioral 
-- Project Name:
-- Target Devices: 
-- Tool versions: 
-- Description: VideoTimingCtl generates the proper synchronization signals
-- according to the selected resolution.
--
-- Dependencies: digilent.Video
--
-- Revision: 
-- Revision 0.03 - Moved the Active Video area to the first part of the counter
-- Revision 0.02 - Added resolution 480x272 progressive
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.Video.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VideoTimingCtl is
	Port (
			  PCLK_I : in  STD_LOGIC; --variable depending on RSEL_I
              RST_I : in  STD_LOGIC; --reset
			  RSEL_I : in RESOLUTION;
			  VDE_O : out STD_LOGIC; --data enable for pixel bus
			  HS_O : out STD_LOGIC;
			  VS_O : out STD_LOGIC;
			  HCNT_O : out NATURAL;
			  VCNT_O : out NATURAL);
end VideoTimingCtl;

architecture Behavioral of VideoTimingCtl is
----------------------------------------------------------------------------------
-- VGA Timing Signals
----------------------------------------------------------------------------------
signal HCnt : NATURAL range 0 to H_MAX := 0; --horizontal counter
signal VCnt : NATURAL range 0 to V_MAX := 0; --vertical counter

signal H_AV, V_AV, H_AV_FP, V_AV_FP, H_AV_FP_S, V_AV_FP_S, H_AV_FP_S_BP, V_AV_FP_S_BP : NATURAL;

signal hs, vs: std_logic; -- horizontal/vertical sync
signal vde : std_logic; -- data enable
signal SRst : std_logic;

signal H_POL, V_POL : BOOLEAN;

component LocalRst
    generic(RESET_PERIOD : natural := 4);
    port(
        RST_I : in  STD_LOGIC;
        CLK_I : in  STD_LOGIC;
        SRST_O : out  STD_LOGIC);
end component;

begin
    
----------------------------------------------------------------------------------
-- Resolution Selector
----------------------------------------------------------------------------------
with RSEL_I select
H_AV <= 	H_640_480p_AV 	when R640_480P,
			H_720_480p_AV	when R720_480P,
			H_480_272p_AV	when R480_272P,
			H_1280_720p_AV	when R1280_720P,
			H_1600_900p_AV  when R1600_900P,
            H_1920_1080p_AV when R1920_1080P,
			H_800_600p_AV 	when R800_600P,
			H_640_480p_AV   when others;
			
with RSEL_I select			
V_AV <= 	V_640_480p_AV 	when R640_480P,
			V_720_480p_AV	when R720_480P,
			V_480_272p_AV	when R480_272P,
			V_1280_720p_AV	when R1280_720P,
			V_1600_900p_AV  when R1600_900P,
            V_1920_1080p_AV	when R1920_1080P,
			V_800_600p_AV 	when R800_600P,
			V_640_480p_AV   when others;
			
with RSEL_I select
H_AV_FP <= 	H_640_480p_AV_FP 	when R640_480P,
			H_720_480p_AV_FP	when R720_480P,
			H_480_272p_AV_FP	when R480_272P,
			H_1280_720p_AV_FP   when R1280_720P,
			H_1600_900p_AV_FP   when R1600_900P,
            H_1920_1080p_AV_FP  when R1920_1080P,
			H_800_600p_AV_FP 	when R800_600P,
			H_640_480p_AV_FP    when others;
			
with RSEL_I select			
V_AV_FP <= 	V_640_480p_AV_FP 	when R640_480P,
			V_720_480p_AV_FP	when R720_480P,
			V_480_272p_AV_FP	when R480_272P,
			V_1280_720p_AV_FP	when R1280_720P,
			V_1600_900p_AV_FP   when R1600_900P,
            V_1920_1080p_AV_FP  when R1920_1080P,
			V_800_600p_AV_FP 	when R800_600P,			
			V_640_480p_AV_FP    when others;
			
with RSEL_I select			
H_AV_FP_S <= 	H_640_480p_AV_FP_S 	when R640_480P,
				H_720_480p_AV_FP_S	when R720_480P,
				H_480_272p_AV_FP_S	when R480_272P,
				H_1280_720p_AV_FP_S	when R1280_720P,
				H_1600_900p_AV_FP_S when R1600_900P,
                H_1920_1080p_AV_FP_S when R1920_1080P,
				H_800_600p_AV_FP_S 	when R800_600P,				
				H_640_480p_AV_FP_S  when others;			

with RSEL_I select			
V_AV_FP_S <= 	V_640_480p_AV_FP_S 	when R640_480P,
				V_720_480p_AV_FP_S	when R720_480P,
				V_480_272p_AV_FP_S	when R480_272P,
				V_1280_720p_AV_FP_S	when R1280_720P,
				V_1600_900p_AV_FP_S when R1600_900P,
                V_1920_1080p_AV_FP_S when R1920_1080P,
				V_800_600p_AV_FP_S 	when R800_600P,				
				V_640_480p_AV_FP_S  when others;
				
with RSEL_I select
H_AV_FP_S_BP <=	H_640_480p_AV_FP_S_BP 	when R640_480P,
				H_720_480p_AV_FP_S_BP	when R720_480P,
				H_480_272p_AV_FP_S_BP	when R480_272P,
				H_1280_720p_AV_FP_S_BP	when R1280_720P,
				H_1600_900p_AV_FP_S_BP 	when R1600_900P,
                H_1920_1080p_AV_FP_S_BP when R1920_1080P,
				H_800_600p_AV_FP_S_BP 	when R800_600P,
				H_640_480p_AV_FP_S_BP   when others;

with RSEL_I select
V_AV_FP_S_BP <=	V_640_480p_AV_FP_S_BP 	when R640_480P,
				V_720_480p_AV_FP_S_BP	when R720_480P,
				V_480_272p_AV_FP_S_BP	when R480_272P,
				V_1280_720p_AV_FP_S_BP	when R1280_720P,
				V_1600_900p_AV_FP_S_BP 	when R1600_900P,
                V_1920_1080p_AV_FP_S_BP when R1920_1080P,
				V_800_600p_AV_FP_S_BP 	when R800_600P,					
				V_640_480p_AV_FP_S_BP   when others;

with RSEL_I select
H_POL <=		H_640_480p_POL	when R640_480P,
				H_720_480p_POL	when R720_480P,
				H_480_272p_POL	when R480_272P,
				H_1280_720p_POL	when R1280_720P,
				H_1600_900p_POL when R1600_900P,
                H_1920_1080p_POL when R1920_1080P,
				H_800_600p_POL 	when R800_600P,		
				H_640_480p_POL  when others;

with RSEL_I select
V_POL <=		V_640_480p_POL	when R640_480P,
				V_720_480p_POL	when R720_480P,
				V_480_272p_POL	when R480_272P,
				V_1280_720p_POL	when R1280_720P,
				V_1600_900p_POL when R1600_900P,
                V_1920_1080p_POL when R1920_1080P,
				V_800_600p_POL 	when R800_600P,
				V_640_480p_POL  when others;
				
----------------------------------------------------------------------------------
-- Local Reset
----------------------------------------------------------------------------------
Inst_LocalRst: LocalRst PORT MAP(
		RST_I => RST_I,
		CLK_I => PCLK_I,
		SRST_O => SRst
	);
----------------------------------------------------------------------------------
-- Video Timing Counter
----------------------------------------------------------------------------------
process (PCLK_I)
begin
	if Rising_Edge(PCLK_I) then
		if (SRst = '1') then
			HCnt <= H_AV_FP_S_BP - 1; -- 0 is an active pixel
			VCnt <= V_AV_FP_S_BP - 1;
			vde <= '0';
			hs <= '1';
			vs <= '1';
		else
			--pixel/line counters and video data enable
			if (HCnt = H_AV_FP_S_BP - 1) then
				HCnt <= 0;
				if (VCnt = V_AV_FP_S_BP - 1) then
					VCnt <= 0;
				else
					VCnt <= VCnt + 1;
				end if;
			else
				HCnt <= HCnt + 1;
			end if;
			
			--sync pulse in sync phase
			if (HCnt >= H_AV_FP-1) and (HCnt < H_AV_FP_S-1) then -- one cycle earlier (registered)
				hs <= '0';
				if (VCnt >= V_AV_FP) and (VCnt < V_AV_FP_S) then
					vs <= '0';
				else
					vs <= '1';
				end if;				
			else
				hs <= '1';
			end if;
			
			--video data enable
			if ((HCnt = H_AV_FP_S_BP - 1 and (VCnt = V_AV_FP_S_BP - 1 or VCnt < V_AV - 1)) or -- first pixel in frame
				 (HCnt < H_AV - 1 and VCnt < V_AV)) then
				vde <= '1';
			else
				vde <= '0';
			end if;
		end if;
	end if;
end process;

HCNT_O <= HCnt;
VCNT_O <= VCnt;
HS_O <= not hs	when H_POL else
			hs;
VS_O <= not vs	when V_POL else
			vs;
VDE_O <= vde;

end Behavioral;

