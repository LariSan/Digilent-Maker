----------------------------------------------------------------------------------
-- Company: Digilent Ro
-- Engineer: Elod Gyorgy
-- 
-- Create Date:    17:53:38 04/06/2011 
-- Design Name: 
-- Module Name:    DVITransmitter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: DVITransmitter takes 24-bit RGB video data with proper sync
-- signals and transmits them on a DVI/HDMI port. The encoding and serialization
-- is done according to the Digital Visual Interface (DVI) specifications Rev 1.0.
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

--library digilent;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DVITransmitter is
    Port ( RED_I : in  STD_LOGIC_VECTOR (7 downto 0);
           GREEN_I : in  STD_LOGIC_VECTOR (7 downto 0);
           BLUE_I : in  STD_LOGIC_VECTOR (7 downto 0);
           HS_I : in  STD_LOGIC;
           VS_I : in  STD_LOGIC;
           VDE_I : in  STD_LOGIC;
           PCLK_I : in  STD_LOGIC;
           PCLK_X2_I : in  STD_LOGIC;
           SERCLK_I : in  STD_LOGIC;
           SERSTB_I : in  STD_LOGIC;
           TMDS_TX_CLK_P : out  STD_LOGIC;
           TMDS_TX_CLK_N : out  STD_LOGIC;
           TMDS_TX_2_P : out  STD_LOGIC;
           TMDS_TX_2_N : out  STD_LOGIC;
           TMDS_TX_1_P : out  STD_LOGIC;
           TMDS_TX_1_N : out  STD_LOGIC;
           TMDS_TX_0_P : out  STD_LOGIC;
           TMDS_TX_0_N : out  STD_LOGIC);
end DVITransmitter;

architecture Behavioral of DVITransmitter is

signal intTmdsRed, intTmdsGreen, intTmdsBlue : std_logic_vector(9 downto 0);

component TMDSEncoder
    port(
        D_I : in  STD_LOGIC_VECTOR(7 downto 0);
        C0_I : in  STD_LOGIC;
        C1_I : in  STD_LOGIC;
        DE_I : in  STD_LOGIC;
		CLK_I: in STD_LOGIC;
		RST_I: in STD_LOGIC;
        D_O : out  STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

component SerializerN_1
    generic(N : NATURAL := 10);
    port(
        DP_I : in  STD_LOGIC_VECTOR(N-1 downto 0);
        PCLK_I : in  STD_LOGIC;
        PCLK_X2_I : in  STD_LOGIC;
		SERCLK_I : in STD_LOGIC;
		SERSTB_I : in STD_LOGIC;
		RST_I : in STD_LOGIC;
        DSP_O : out  STD_LOGIC;
        DSN_O : out  STD_LOGIC);
end component;

begin

----------------------------------------------------------------------------------
-- DVI Encoder; DVI 1.0 Specifications
-- This component encodes 24-bit RGB video frames with sync signals into 10-bit
-- TMDS characters.
----------------------------------------------------------------------------------
	Inst_TMDSEncoder_red: TMDSEncoder PORT MAP(
		D_I => RED_I,
		C0_I => '0',
		C1_I => '0',
		DE_I => VDE_I,
		CLK_I => PCLK_I,
		RST_I => '0',
		D_O => intTmdsRed
	);
	Inst_TMDSEncoder_green: TMDSEncoder PORT MAP(
		D_I => GREEN_I,
		C0_I => '0',
		C1_I => '0',
		DE_I => VDE_I,
		CLK_I => PCLK_I,
		RST_I => '0',
		D_O => intTmdsGreen
	);
	Inst_TMDSEncoder_blue: TMDSEncoder PORT MAP(
		D_I => BLUE_I,
		C0_I => HS_I,
		C1_I => VS_I,
		DE_I => VDE_I,
		CLK_I => PCLK_I,
		RST_I => '0',
		D_O => intTmdsBlue
	);
	
----------------------------------------------------------------------------------
-- TMDS serializer; ratio of 10:1; 3 data & 1 clock channel
-- Since the TMDS clock's period is character-long (10-bit periods), the
-- serialization of "1111100000" will result in a 10-bit long clock period.
----------------------------------------------------------------------------------	
	Inst_clk_serializer_10_1: SerializerN_1 GENERIC MAP (10)
	PORT MAP(
		DP_I => "1111100000",
		PCLK_I => PCLK_I,
		PCLK_X2_I => PCLK_X2_I,
		SERCLK_I => SERCLK_I,
		SERSTB_I => SERSTB_I,
		RST_I => '0',
		DSP_O => TMDS_TX_CLK_P,
		DSN_O => TMDS_TX_CLK_N
	);
	Inst_d2_serializer_10_1: SerializerN_1 GENERIC MAP (10)
	PORT MAP(
		DP_I => intTmdsRed,
		PCLK_I => PCLK_I,
		PCLK_X2_I => PCLK_X2_I,
		SERCLK_I => SERCLK_I,
		SERSTB_I => SERSTB_I,
		RST_I => '0',
		DSP_O => TMDS_TX_2_P,
		DSN_O => TMDS_TX_2_N
	);
	Inst_d1_serializer_10_1: SerializerN_1 GENERIC MAP (10)
	PORT MAP(
		DP_I => intTmdsGreen,
		PCLK_I => PCLK_I,
		PCLK_X2_I => PCLK_X2_I,
		SERCLK_I => SERCLK_I,
		SERSTB_I => SERSTB_I,
		RST_I => '0',
		DSP_O => TMDS_TX_1_P,
		DSN_O => TMDS_TX_1_N
	);
	Inst_d0_serializer_10_1: SerializerN_1 GENERIC MAP (10)
	PORT MAP(
		DP_I => intTmdsBlue,
		PCLK_I => PCLK_I,
		PCLK_X2_I => PCLK_X2_I,
		SERCLK_I => SERCLK_I,
		SERSTB_I => SERSTB_I,
		RST_I => '0',
		DSP_O => TMDS_TX_0_P,
		DSN_O => TMDS_TX_0_N
	);

end Behavioral;

