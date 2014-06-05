----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:06:16 10/27/2010 
-- Design Name: 
-- Module Name:    serializer_40_4 - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SerializerN_1 is
	 Generic ( 	N : NATURAL := 10 );
    Port ( DP_I : in  STD_LOGIC_VECTOR (N-1 downto 0);
           PCLK_I : in  STD_LOGIC;
           PCLK_X2_I : in  STD_LOGIC;
			  SERCLK_I : in STD_LOGIC;
			  SERSTB_I : in STD_LOGIC;
			  RST_I : in STD_LOGIC; --async reset
           DSP_O : out  STD_LOGIC;
           DSN_O : out  STD_LOGIC);
end SerializerN_1;

architecture Behavioral of SerializerN_1 is

signal intDSOut: std_logic;
signal intDPIn : std_logic_vector(N/2-1 downto 0) ;
signal padDPIn : std_logic_vector(7 downto 0) ;
signal cascade_do, cascade_di, cascade_to, cascade_ti : std_logic;
signal gear, gear_s : std_logic := '0';
begin

----------------------------------------------------------------------------------
-- 2:1 gearbox; SerDes is used in 5:1 ratio, we need to double that; The SerDes
-- parallel input will change twice in a pixel clock, thus the need for pixel
-- clock * 2
----------------------------------------------------------------------------------
process (PCLK_I, RST_I)
begin
	if (RST_I = '1') then
		gear <= '0';
	elsif Rising_Edge(PCLK_I) then		
		gear <= not gear;
	end if;
end process;

process (PCLK_X2_I)
begin
	if Rising_Edge(PCLK_X2_I) then		
		gear_s <= gear; --resync gear on x2 domain
	end if;
end process;

process (PCLK_X2_I)
begin
	if Rising_Edge(PCLK_X2_I) then
		if ((gear xor gear_s) = '1') then
			intDPIn <= DP_I(N/2-1 downto 0);
		else
			intDPIn <= DP_I(N-1 downto N/2);
		end if ;
	end if;
end process ;

----------------------------------------------------------------------------------
-- Instantiate Output Buffer
----------------------------------------------------------------------------------
io_datax_out : obufds port map (
	O    			=> DSP_O,
	OB       	=> DSN_O,
	I         	=> intDSOut);

padDPIn(7 downto N/2) <= (others => '0');
padDPIn(N/2-1 downto 0) <= intDPIn(N/2-1 downto 0);
	
----------------------------------------------------------------------------------
-- Cascaded OSERDES for 5:1 ratio
----------------------------------------------------------------------------------
oserdes_m : OSERDES2 generic map (
	DATA_WIDTH     		=> N/2, 		-- SERDES word width.  This should match the setting is BUFPLL
	DATA_RATE_OQ      	=> "SDR", 		-- <SDR>, DDR
	DATA_RATE_OT      	=> "SDR", 		-- <SDR>, DDR
	SERDES_MODE    		=> "MASTER", 		-- <DEFAULT>, MASTER, SLAVE
	OUTPUT_MODE 		=> "DIFFERENTIAL")
port map (
	OQ       		=> intDsOut,	--master outputs serial data in cascaded setup
	OCE     		=> '1',
	CLK0    		=> SERCLK_I,
	CLK1    		=> '0',
	IOCE    		=> SERSTB_I,
	RST     		=> RST_I,			--async reset
	CLKDIV  		=> PCLK_X2_I,			--parallel data transferred at 2x pixel clock (2x 5:1 = 10:1)
	D4  			=> padDPIn(7),					--not used in 5:1
	D3  			=> padDPIn(6),					--not used in 5:1
	D2  			=> padDPIn(5),					--not used in 5:1
	D1  			=> padDPIn(4),	--MSB in 5:1
	TQ  			=> open,					--no tri-state
	T1 			=> '0',
	T2 			=> '0',
	T3 			=> '0',
	T4 			=> '0',
	TRAIN    		=> '0',
	TCE	   		=> '1',
	SHIFTIN1 		=> '1',			-- Dummy input in Master
	SHIFTIN2 		=> '1',			-- Dummy input in Master
	SHIFTIN3 		=> cascade_do,	-- Cascade output D data from slave
	SHIFTIN4 		=> cascade_to,	-- Cascade output T data from slave
	SHIFTOUT1 		=> cascade_di,	-- Cascade input D data to slave
	SHIFTOUT2 		=> cascade_ti,	-- Cascade input T data to slave
	SHIFTOUT3 		=> open,		-- Dummy output in Master
	SHIFTOUT4 		=> open) ;		-- Dummy output in Master

oserdes_s : OSERDES2 generic map(
	DATA_WIDTH     		=> N/2, 		-- SERDES word width.  This should match the setting is BUFPLL
	DATA_RATE_OQ      	=> "SDR", 		-- <SDR>, DDR
	DATA_RATE_OT      	=> "SDR", 		-- <SDR>, DDR
	SERDES_MODE    		=> "SLAVE", 		-- <DEFAULT>, MASTER, SLAVE
	OUTPUT_MODE 		=> "DIFFERENTIAL")
port map (
	OQ       		=> open,			--slave does not output serial data in cascaded setup
	OCE     		=> '1',
	CLK0    		=> SERCLK_I,
	CLK1    		=> '0',
	IOCE    		=> SERSTB_I,
	RST     		=> RST_I,		--async reset
	CLKDIV  		=> PCLK_X2_I,		--parallel data transferred at 2x pixel clock (2x 5:1 = 10:1)
	D4  			=> padDPIn(3),
	D3  			=> padDPIn(2),
	D2  			=> padDPIn(1),
	D1  			=> padDPIn(0),
	TQ  			=> open,				--no tri-state
	T1 			=> '0',
	T2 			=> '0',
	T3  			=> '0',
	T4  			=> '0',
	TRAIN 			=> '0',
	TCE	 			=> '1',
	SHIFTIN1 		=> cascade_di,	-- Cascade input D from Master
	SHIFTIN2 		=> cascade_ti,	-- Cascade input T from Master
	SHIFTIN3 		=> '1',			-- Dummy input in Slave
	SHIFTIN4 		=> '1',			-- Dummy input in Slave
	SHIFTOUT1 		=> open,		-- Dummy output in Slave
	SHIFTOUT2 		=> open,		-- Dummy output in Slave
	SHIFTOUT3 		=> cascade_do,   	-- Cascade output D data to Master
	SHIFTOUT4 		=> cascade_to) ; 	-- Cascade output T data to Master

end Behavioral;

