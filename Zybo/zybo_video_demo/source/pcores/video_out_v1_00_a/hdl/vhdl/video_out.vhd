----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:55:27 11/14/2013 
-- Design Name: 
-- Module Name:    video_out - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;


library work;
use work.Video.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity video_out is
	Port (
		SYSCLK : in STD_LOGIC;
		RST : in STD_LOGIC;
      
      -- DDC result
      DDC_CCKSUM_ERR_O : out std_logic;
      DDC_ERR_O : out std_logic;
      DDC_RUN_O : out std_logic;
      HDMI_HPD_O : out std_logic;
      -- CEC result
      CEC_TX_DONE_O : out std_logic;
      CEC_TX_BUSY_O : out std_logic;
      CEC_TX_ERR_O : out std_logic;
		
      --VGA
		VGA_HS : out std_logic;
		VGA_VS : out std_logic;
		VGA_R : out std_logic_vector(4 downto 0);
		VGA_G : out std_logic_vector(5 downto 0);
		VGA_B : out std_logic_vector(4 downto 0);
      
      --HDMI TX
      HDMI1_SDA_I : in std_logic;
      HDMI1_SDA_O : out std_logic;
      HDMI1_SDA_T : out std_logic;
        --HDMI1_SDA :  inout std_logic;
      HDMI1_SCL_I : in std_logic;
      HDMI1_SCL_O : out std_logic;
      HDMI1_SCL_T : out std_logic;
        --HDMI1_SCL   : inout std_logic; 
		HDMI1_OUT_EN : out  STD_LOGIC;
		HDMI1_HPD : in  STD_LOGIC;
      HDMI1_CEC_T : out std_logic;
      HDMI1_CEC_O : out std_logic;
      HDMI1_CEC_I : in std_logic;
        --HDMI1_CEC   : inout std_logic;
		HDMI1_CLK_P : out  STD_LOGIC;
		HDMI1_CLK_N : out  STD_LOGIC;
		HDMI1_D2_P : out  STD_LOGIC;
		HDMI1_D2_N : out  STD_LOGIC;
		HDMI1_D1_P : out  STD_LOGIC;
		HDMI1_D1_N : out  STD_LOGIC;
		HDMI1_D0_P : out  STD_LOGIC;
		HDMI1_D0_N : out  STD_LOGIC
	);
			  
end video_out;

architecture Behavioral of video_out is

component dcm7
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  PCLK          : out    std_logic;
  PCLK_X5          : out    std_logic;
  -- Status and control signals
  RESET             : in     std_logic;
  LOCKED            : out    std_logic
 );
end component;

component hdmi_ddc_r is
   port(
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      start_i        : in  std_logic;
      twiRun_o       : out std_logic;
      twiErr_o       : out std_logic;
      chckSumErr_o   : out std_logic;
      sda_i          : in std_logic;
      sda_o          : out std_logic;
      sda_t          : out std_logic;
      scl_i          : in std_logic;
      scl_o          : out std_logic;
      scl_t          : out std_logic);
      --scl            : inout std_logic;
      --sda            : inout std_logic);
end component;

component VideoTimingCtl is
	Port (
			  PCLK_I : in  STD_LOGIC; --variable depending on RSEL_I
           RST_I : in  STD_LOGIC; --reset
			  RSEL_I : in RESOLUTION;
			  VDE_O : out STD_LOGIC; --data enable for pixel bus
			  HS_O : out STD_LOGIC;
			  VS_O : out STD_LOGIC;
			  HCNT_O : out NATURAL;
			  VCNT_O : out NATURAL);
end component;

component DVITransmitter is
	 Generic (FAMILY : STRING := "spartan6");
    Port ( RED_I : in  STD_LOGIC_VECTOR (7 downto 0);
           GREEN_I : in  STD_LOGIC_VECTOR (7 downto 0);
           BLUE_I : in  STD_LOGIC_VECTOR (7 downto 0);
           HS_I : in  STD_LOGIC;
           VS_I : in  STD_LOGIC;
           VDE_I : in  STD_LOGIC;
			  RST_I : in STD_LOGIC;
           PCLK_I : in  STD_LOGIC;
           PCLK_X5_I : in  STD_LOGIC;
           TMDS_TX_CLK_P : out  STD_LOGIC;
           TMDS_TX_CLK_N : out  STD_LOGIC;
           TMDS_TX_2_P : out  STD_LOGIC;
           TMDS_TX_2_N : out  STD_LOGIC;
           TMDS_TX_1_P : out  STD_LOGIC;
           TMDS_TX_1_N : out  STD_LOGIC;
           TMDS_TX_0_P : out  STD_LOGIC;
           TMDS_TX_0_N : out  STD_LOGIC);
end component;

component cec_initiator is
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
end component;

signal PClkLckd, PllRst, SysRst, VtcVde, VtcHs, VtcVs, VtcVde_d, VtcHs_d, VtcVs_d: std_logic;
signal red, green, blue : std_logic_vector(7 downto 0);
signal VtcHCnt, VtcVCnt : natural;
signal PClk, PClk_dbg, PClk_x5, int_PClk, int_PClk_x5, int_SysClk : std_logic;
signal ddc_start: std_logic;--, ddc_checksum_err_o, ddc_err_o, ddc_run_o : std_logic;
signal cecData : std_logic_vector(8 downto 0);

signal dummy, dummy0 : std_logic_vector(8 downto 0);

--signal  HDMI1_SDA_I :  std_logic;
--signal  HDMI1_SDA_O :  std_logic;
--signal  HDMI1_SDA_T :  std_logic;
--signal  HDMI1_SCL_I :  std_logic;
--signal  HDMI1_SCL_O :  std_logic;
--signal  HDMI1_SCL_T :  std_logic;
--
--signal  HDMI1_CEC_T :  std_logic;
--signal  HDMI1_CEC_O :  std_logic;
--signal  HDMI1_CEC_I :  std_logic;


begin

--HDMI1_SDA_I <= HDMI1_SDA;
--HDMI1_SDA <= 'Z' when HDMI1_SDA_T = '1' else HDMI1_SDA_O;
--
--HDMI1_SCL_I <= HDMI1_SCL;
--HDMI1_SCL <= 'Z' when HDMI1_SCL_T = '1' else HDMI1_SCL_O;

--HDMI1_CEC_I <= HDMI1_CEC;
--HDMI1_CEC <= 'Z' when HDMI1_CEC_T = '1' else HDMI1_CEC_O;


HDMI_HPD_O <= HDMI1_HPD;

PllRst <= RST;

----------------------------------------------------------------------------------
-- Clock routing stuff
----------------------------------------------------------------------------------	
--   IBUFG_inst : IBUFG
--   generic map (
--      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
--      IOSTANDARD => "DEFAULT")
--   port map (
--      O => int_SysClk,  -- Clock buffer output
--      I => SYSCLK  -- Diff_p clock buffer input (connect directly to top-level port)
--   );
	
   int_SysClk <= SYSCLK;
   
Pixel_clock_gen : dcm7
  port map
   (-- Clock in ports
    CLK_IN1 => int_SysClk,
    -- Clock out ports
    PCLK => int_PClk,
	 PCLK_X5 => int_PClk_x5,
    -- Status and control signals
    RESET  => PllRst,
    LOCKED => PClkLckd);

   BUFIO_inst : BUFIO
   port map (
      O => PClk_x5, -- 1-bit output: Clock output (connect to I/O clock loads).
      I => int_PClk_x5  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
   );
	BUFR_inst : BUFR
	generic map (
      BUFR_DIVIDE => "5",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
   )
   port map (
      O => PClk,     -- 1-bit output: Clock output port
      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
      CLR => '0', -- 1-bit input: Active high, asynchronous clear (Divided modes only)		
      I => int_PClk_x5      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
   );
	
SysRst <= not PClkLckd;

----------------------------------------------------------------------------------
-- Video Timing Generator
----------------------------------------------------------------------------------		 
	Inst_VideoTimingCtl: VideoTimingCtl PORT MAP(
		PCLK_I => PClk,
		RST_I => SysRst,
		RSEL_I => R1600_900P,--R1280_1024_60P, --R1920_1080_60P
		VDE_O => VtcVde,
		HS_O => VtcHs,
		VS_O => VtcVs,
		
		HCNT_O => VtcHCnt,
		VCNT_O => VtcVCnt
	);

----------------------------------------------------------------------------------
-- DVI/HDMI Transmitter
----------------------------------------------------------------------------------		
	Inst_DVITransmitter: DVITransmitter 
	GENERIC MAP ("artix7")
	PORT MAP(
		RED_I => red,
		GREEN_I => green,
		BLUE_I => blue,
		HS_I => VtcHs_d,
		VS_I => VtcVs_d,
		VDE_I => VtcVde_d,
		RST_I => SysRst,
		PCLK_I => PClk,
		PCLK_X5_I => PClk_x5,
		TMDS_TX_CLK_P => HDMI1_CLK_P,
		TMDS_TX_CLK_N => HDMI1_CLK_N,
		TMDS_TX_2_P => HDMI1_D2_P,
		TMDS_TX_2_N => HDMI1_D2_N,
		TMDS_TX_1_P => HDMI1_D1_P,
		TMDS_TX_1_N => HDMI1_D1_N,
		TMDS_TX_0_P => HDMI1_D0_P,
		TMDS_TX_0_N => HDMI1_D0_N 
	);
	
	HDMI1_OUT_EN <= '1';
----------------------------------------------------------------------------------
-- Pattern Generator
----------------------------------------------------------------------------------	
process(PClk)
begin
	if Rising_Edge(PClk) then
		VtcHs_d <= VtcHs;
		VtcVs_d <= VtcVs;
		VtcVde_d <= VtcVde;
		red <= conv_std_logic_vector(VtcHCnt, 8);
		green <= conv_std_logic_vector(VtcVCnt, 8);
		blue <= x"AA";
	end if;
end process;	

----------------------------------------------------------------------------------
-- VGA Output
----------------------------------------------------------------------------------	
	VGA_HS <= VtcHs_d;
	VGA_VS <= VtcVs_d;
	VGA_R <= red(red'high downto red'high-VGA_R'high) when VtcVde_d = '1' else (others => '0');
	VGA_G <= green(green'high downto green'high-VGA_G'high) when VtcVde_d = '1' else (others => '0');
	VGA_B <= blue(blue'high downto blue'high-VGA_B'high) when VtcVde_d = '1' else (others => '0');

----------------------------------------------------------------------------------
-- EDID reader
----------------------------------------------------------------------------------
   --ddc_start <= PClkLckd;
   
   Inst_Edid: hdmi_ddc_r
   port map(
      clk_i                => int_SysClk,
      rst_i                => RST,
      start_i              => '1',
      twiRun_o             => DDC_RUN_O,
      twiErr_o             => DDC_ERR_O,
      chckSumErr_o         => DDC_CCKSUM_ERR_O,
      sda_i                => HDMI1_SDA_I,
      sda_o                => HDMI1_SDA_O,
      sda_t                => HDMI1_SDA_T,
      scl_i                => HDMI1_SCL_I,
      scl_o                => HDMI1_SCL_O,
      scl_t                => HDMI1_SCL_T);
      --scl                  => HDMI1_SCL,
      --sda                  => HDMI1_SDA);

----------------------------------------------------------------------------------
-- CEC brodcast test
----------------------------------------------------------------------------------
   process(int_SysClk)
   begin
      if rising_edge(int_SysClk) then
         if PllRst = '1' then
            cecData <= "000000000";
         elsif PClkLckd = '1' then
            cecData <= "111100001";
         end if;
      end if;
   end process;
   
   CecInit: cec_initiator
   generic map(
      C_CLOCK_FREQ_MHZ => 125)
   port map(
      clk_i    => int_SysClk,
      rst_i    => PllRst,
      data00_i => cecData,
      data01_i => cecData,
      data02_i => cecData,
      data03_i => cecData,
      data04_i => cecData,
      data05_i => cecData,
      data06_i => cecData,
      data07_i => cecData,
      data08_i => cecData,
      data09_i => cecData,
      data10_i => cecData,
      data11_i => cecData,
      data12_i => cecData,
      data13_i => cecData,
      data14_i => cecData,
      data15_i => cecData,
      fDone    => CEC_TX_DONE_O,
      fBusy    => CEC_TX_BUSY_O,
      fError   => CEC_TX_ERR_O,
      cec_i    => HDMI1_CEC_I,
      cec_o    => HDMI1_CEC_O,
      cec_t    => HDMI1_CEC_T);   
   
   
end Behavioral;

