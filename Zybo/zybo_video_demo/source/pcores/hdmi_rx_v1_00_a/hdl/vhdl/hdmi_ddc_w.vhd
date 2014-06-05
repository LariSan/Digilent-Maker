----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:13:37 05/16/2013 
-- Design Name: 
-- Module Name:    edid2_eeprom - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity hdmi_ddc_w is
    port(
        -- Other signals
        CLK_I : in  std_logic; -- System clock
        
        -- I2C signals
        SCL_I : in std_logic;
		     SDA_I : in std_logic;
		     SDA_O : out std_logic;
		     SDA_T : out std_logic
    );
end hdmi_ddc_w;

architecture Behavioral of hdmi_ddc_w is

type edid_t is array (0 to 127) of std_logic_vector(7 downto 0);
type state_type is (stIdle, stRead, stWrite, stRegAddress); 

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal edid : edid_t := (
 x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"34", x"A9", x"45", x"A0", x"AA", x"AA", x"AA", x"AA",
 x"00", x"0F", x"01", x"03", x"80", x"33", x"1D", x"78", x"0A", x"DA", x"FF", x"A3", x"58", x"4A", x"A2", x"29",
 x"17", x"49", x"4B", x"00", x"00", x"00", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"1D", x"00", x"72", x"51", x"D0", x"1E", x"20", x"6E", x"28",
 x"55", x"00", x"98", x"06", x"32", x"00", x"00", x"1E", x"00", x"00", x"00", x"10", x"00", x"1C", x"16", x"20",
 x"58", x"2C", x"25", x"00", x"98", x"06", x"32", x"00", x"00", x"9E", x"00", x"00", x"00", x"FC", x"00", x"5A",
 x"59", x"42", x"4F", x"20", x"64", x"65", x"6D", x"6F", x"0A", x"0A", x"0A", x"0A", x"00", x"00", x"00", x"FD",
 x"00", x"3B", x"3D", x"0F", x"44", x"0F", x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"01", x"83");
 
--x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"1E", x"6D", x"9F", x"4E", x"5B", x"53", x"03", x"00",
--x"04", x"13", x"01", x"03", x"6A", x"2D", x"19", x"78", x"EA", x"A6", x"80", x"A5", x"55", x"4D", x"9D", x"25",
--x"11", x"50", x"54", x"A7", x"6A", x"80", x"A9", x"C0", x"81", x"80", x"71", x"4F", x"01", x"01", x"01", x"01",
--x"01", x"01", x"01", x"01", x"01", x"01", x"30", x"2A", x"40", x"C8", x"60", x"84", x"64", x"30", x"18", x"50",
--x"13", x"00", x"BB", x"F9", x"10", x"00", x"00", x"1E", x"30", x"2A", x"40", x"C8", x"60", x"84", x"64", x"30",
--x"18", x"50", x"13", x"00", x"BB", x"F9", x"10", x"00", x"00", x"1E", x"00", x"00", x"00", x"FD", x"00", x"38",
--x"4B", x"1E", x"53", x"0D", x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"00", x"00", x"FC",
--x"00", x"57", x"32", x"30", x"35", x"33", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"CA");

--	x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10", x"EC", x"00", x"01", x"00", x"00", x"00", x"00",
--	x"FF", x"16", x"01", x"03", x"81", x"33", x"1D", x"78", x"02", x"01", x"F1", x"A2", x"57", x"52", x"9F", x"27",
--	x"0A", x"50", x"54", x"BF", x"EF", x"80", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01",
--	x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"1D", x"00", x"72", x"51", x"D0", x"1E", x"20", x"6E", x"28",
--	x"55", x"00", x"00", x"D0", x"52", x"00", x"00", x"1E", x"00", x"00", x"00", x"FC", x"00", x"44", x"69", x"67",
--	x"69", x"6C", x"65", x"6E", x"74", x"20", x"48", x"44", x"4D", x"49", x"00", x"00", x"00", x"10", x"00", x"00",
--	x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"10",
--	x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"0E");
   
--	x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10", x"EC", x"00", x"01", x"00", x"00", x"00", x"00", -- 00
--	x"FF", x"16", x"01", x"03", x"81", x"33", x"1D", x"78", x"1A", x"01", x"F1", x"A2", x"57", x"52", x"9F", x"27", -- 10
--	x"0A", x"50", x"54", x"BF", x"EF", x"80", x"71", x"4F", x"81", x"00", x"81", x"40", x"81", x"80", x"95", x"00", -- 20
--	x"95", x"0F", x"B3", x"00", x"01", x"01", x"02", x"3A", x"80", x"18", x"71", x"38", x"2D", x"40", x"58", x"2C", -- 30
--	x"45", x"00", x"FE", x"1F", x"11", x"00", x"00", x"1E", x"66", x"21", x"50", x"B0", x"51", x"00", x"1B", x"30", -- 40
--	x"40", x"70", x"36", x"00", x"FE", x"1F", x"11", x"00", x"00", x"1E", x"00", x"00", x"00", x"FD", x"00", x"18", -- 50
--	x"4B", x"1A", x"51", x"17", x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"00", x"00", x"FC", -- 60
--	x"00", x"44", x"69", x"67", x"69", x"6C", x"65", x"6E", x"74", x"20", x"48", x"44", x"4D", x"49", x"01", x"4E", -- 70
--	x"02", x"03", x"20", x"F0", x"4B", x"90", x"1F", x"04", x"13", x"05", x"14", x"03", x"12", x"20", x"21", x"22", -- 80
--	x"23", x"09", x"07", x"07", x"83", x"01", x"00", x"00", x"67", x"03", x"0C", x"00", x"20", x"00", x"F8", x"2D", -- 90
--	x"01", x"1D", x"00", x"72", x"51", x"D0", x"1E", x"20", x"6E", x"28", x"55", x"00", x"A0", x"5A", x"00", x"00", -- A0
--	x"00", x"1E", x"01", x"1D", x"00", x"BC", x"52", x"D0", x"1E", x"20", x"B8", x"28", x"55", x"40", x"A0", x"5A", -- B0
--	x"00", x"00", x"00", x"1E", x"01", x"1D", x"80", x"18", x"71", x"1C", x"16", x"20", x"58", x"2C", x"25", x"00", -- C0
--	x"A0", x"5A", x"00", x"00", x"00", x"9E", x"01", x"1D", x"80", x"D0", x"72", x"1C", x"16", x"20", x"10", x"2C", -- D0
--	x"25", x"80", x"A0", x"5A", x"00", x"00", x"00", x"9E", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", -- E0
--	x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"6D", x"45");-- F0

-- V1
--   x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10", x"EC", x"00", x"01", x"00", x"00", x"00", x"00",
--   x"FF", x"17", x"01", x"03", x"81", x"33", x"1D", x"78", x"1A", x"01", x"F1", x"A2", x"57", x"52", x"9F", x"27",
--   x"0A", x"50", x"54", x"BF", x"EF", x"80", x"71", x"4F", x"81", x"00", x"81", x"40", x"81", x"80", x"95", x"00",
--   x"95", x"0F", x"B3", x"00", x"81", x"C0", x"02", x"3A", x"80", x"18", x"71", x"38", x"2D", x"40", x"58", x"2C",
--   x"45", x"00", x"FE", x"1F", x"11", x"00", x"00", x"1E", x"00", x"00", x"00", x"FD", x"00", x"18", x"4B", x"1A",
--   x"51", x"17", x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"00", x"00", x"FC", x"00", x"44",
--   x"69", x"67", x"69", x"6C", x"65", x"6E", x"74", x"20", x"48", x"44", x"4D", x"49", x"00", x"00", x"00", x"10",
--   x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"54");
   
   -- x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10", x"EC", x"00", x"01", x"00", x"00", x"00", x"00",
   -- x"FF", x"17", x"01", x"03", x"81", x"33", x"1D", x"78", x"1A", x"01", x"F1", x"A2", x"57", x"52", x"9F", x"27",
   -- x"0A", x"50", x"54", x"BF", x"EF", x"80", x"71", x"4F", x"81", x"00", x"81", x"40", x"81", x"80", x"95", x"00",
   -- x"95", x"0F", x"B3", x"00", x"81", x"C0", x"A0", x"0F", x"20", x"00", x"31", x"58", x"1C", x"20", x"28", x"80",
   -- x"14", x"00", x"90", x"2C", x"11", x"00", x"00", x"1E", x"00", x"00", x"00", x"FD", x"00", x"18", x"4B", x"1A",
   -- x"51", x"17", x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"00", x"00", x"FC", x"00", x"44",
   -- x"69", x"67", x"69", x"6C", x"65", x"6E", x"74", x"20", x"48", x"44", x"4D", x"49", x"00", x"00", x"00", x"10",
   -- x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"18");
   
-- V2
--	x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10", x"EC",
--	x"00", x"01", x"00", x"00", x"00", x"00", x"FF", x"16", x"01", x"03",
--	x"81", x"33", x"1D", x"78", x"1A", x"01", x"F1", x"A2", x"57", x"52",
--	x"9F", x"27", x"0A", x"50", x"54", x"BF", x"EF", x"80", x"71", x"4F",
--	x"81", x"00", x"81", x"40", x"81", x"80", x"95", x"00", x"95", x"0F",
--	x"B3", x"00", x"01", x"01", x"02", x"3A", x"80", x"18", x"71", x"38",
--	x"2D", x"40", x"58", x"2C", x"45", x"00", x"FE", x"1F", x"11", x"00",
--	x"00", x"1E", x"66", x"21", x"50", x"B0", x"51", x"00", x"1B", x"30",
--	x"40", x"70", x"36", x"00", x"FE", x"1F", x"11", x"00", x"00", x"1E",
--	x"00", x"00", x"00", x"FD", x"00", x"18", x"4B", x"1A", x"51", x"17",
--	x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"00",
--	x"00", x"FC", x"00", x"44", x"69", x"67", x"69", x"6C", x"65", x"6E",
--	x"74", x"20", x"48", x"44", x"4D", x"49", x"01", x"4E", x"02", x"03",
--	x"18", x"B0", x"4B", x"90", x"1F", x"04", x"13", x"05", x"14", x"03",
--	x"12", x"20", x"21", x"22", x"67", x"03", x"0C", x"00", x"20", x"00",
--	x"F8", x"2D", x"01", x"1D", x"00", x"72", x"51", x"D0", x"1E", x"20",
--	x"6E", x"28", x"55", x"00", x"A0", x"5A", x"00", x"00", x"00", x"1E",
--	x"01", x"1D", x"00", x"BC", x"52", x"D0", x"1E", x"20", x"B8", x"28",
--	x"55", x"40", x"A0", x"5A", x"00", x"00", x"00", x"1E", x"01", x"1D",
--	x"80", x"18", x"71", x"1C", x"16", x"20", x"58", x"2C", x"25", x"00",
--	x"A0", x"5A", x"00", x"00", x"00", x"9E", x"01", x"1D", x"80", x"D0",
--	x"72", x"1C", x"16", x"20", x"10", x"2C", x"25", x"80", x"A0", x"5A",
--	x"00", x"00", x"00", x"9E", x"00", x"00", x"00", x"00", x"00", x"00",
--	x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
--	x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
--	x"00", x"00", x"00", x"00", x"FF", x"B9");
 
-- V3
 -- x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10", x"EC",
 -- x"00", x"01", x"00", x"00", x"00", x"00", x"FF", x"16", x"01", x"03",
 -- x"81", x"33", x"1D", x"78", x"1A", x"01", x"F1", x"A2", x"57", x"52",
 -- x"9F", x"27", x"0A", x"50", x"54", x"BF", x"EF", x"80", x"71", x"4F",
 -- x"81", x"00", x"81", x"40", x"81", x"80", x"95", x"00", x"95", x"0F",
 -- x"B3", x"00", x"01", x"01", x"02", x"3A", x"80", x"18", x"71", x"38",
 -- x"2D", x"40", x"58", x"2C", x"45", x"00", x"FE", x"1F", x"11", x"00",
 -- x"00", x"1E", x"66", x"21", x"50", x"B0", x"51", x"00", x"1B", x"30",
 -- x"40", x"70", x"36", x"00", x"FE", x"1F", x"11", x"00", x"00", x"1E",
 -- x"00", x"00", x"00", x"FD", x"00", x"18", x"4B", x"1A", x"51", x"17",
 -- x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"00", x"00",
 -- x"00", x"FC", x"00", x"44", x"69", x"67", x"69", x"6C", x"65", x"6E",
 -- x"74", x"20", x"48", x"44", x"4D", x"49", x"01", x"4E", x"02", x"03",
 -- x"10", x"B0", x"4B", x"90", x"1F", x"04", x"13", x"05", x"14", x"03",
 -- x"12", x"20", x"21", x"22", x"01", x"1D", x"00", x"72", x"51", x"D0",
 -- x"1E", x"20", x"6E", x"28", x"55", x"00", x"A0", x"5A", x"00", x"00",
 -- x"00", x"1E", x"01", x"1D", x"00", x"BC", x"52", x"D0", x"1E", x"20",
 -- x"B8", x"28", x"55", x"40", x"A0", x"5A", x"00", x"00", x"00", x"1E",
 -- x"01", x"1D", x"80", x"18", x"71", x"1C", x"16", x"20", x"58", x"2C",
 -- x"25", x"00", x"A0", x"5A", x"00", x"00", x"00", x"9E", x"01", x"1D",
 -- x"80", x"D0", x"72", x"1C", x"16", x"20", x"10", x"2C", x"25", x"80",
 -- x"A0", x"5A", x"00", x"00", x"00", x"9E", x"00", x"00", x"00", x"00",
 -- x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
 -- x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
 -- x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
 -- x"00", x"00", x"00", x"00", x"FF", x"7C");

signal state, nstate : state_type; 
signal regAddr, dataByteIn, dataByteOut : std_logic_vector(7 downto 0) := x"00";
signal xfer_end, xfer_done, xfer_stb, rd_wrn : std_logic;

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

component TWISlaveCtl
	 generic(
        SLAVE_ADDRESS : std_logic_vector(7 downto 0) := x"A0"); -- TWI Slave address
    port(
        D_I       : in  STD_LOGIC_VECTOR (7 downto 0);
        D_O       : out STD_LOGIC_VECTOR (7 downto 0);
        RD_WRN_O  : out STD_LOGIC;
		  END_O     : out STD_LOGIC;
        DONE_O    : out STD_LOGIC;
        STB_I     : in  STD_LOGIC;
        CLK       : in  STD_LOGIC;
        SRST      : in  STD_LOGIC;
		     SDA_I : in std_logic;
		     SDA_O : out std_logic;
		     SDA_T : out std_logic;
        SCL_I     : in STD_LOGIC);
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Instantiate the I2C Slave Transmitter
------------------------------------------------------------------------    
    Inst_TwiSlave: TWISlaveCtl
	 generic map(
        SLAVE_ADDRESS => x"A0")
    port map(
        D_I       => dataByteOut,
        D_O       => dataByteIn,
        RD_WRN_O  => rd_wrn,
		  END_O     => xfer_end,
        DONE_O    => xfer_done,
        STB_I     => xfer_stb,
        CLK       => CLK_I,
        SRST      => '0',
		     SDA_I      => SDA_I,
		     SDA_O      => SDA_O,
		     SDA_T      => SDA_T,
        SCL_I     => SCL_I);
    
   -- EEPROM
	process (CLK_I)
   begin
      if Rising_Edge(CLK_I) then
			if (xfer_done = '1') then
				if (state = stRegAddress) then
					regAddr <= dataByteIn;
				elsif (state = stRead) then
					regAddr <= regAddr + '1';
				end if;
				
				if (state = stWrite) then
					edid(conv_integer(regAddr)) <= dataByteIn;
				end if;
			
			end if;
			dataByteOut <= edid(conv_integer(regAddr));
      end if;
   end process;
	
 
   --Insert the following in the architecture after the begin keyword
   SYNC_PROC: process (CLK_I)
   begin
      if Rising_Edge(CLK_I) then
         state <= nstate;   
      end if;
   end process;
 
   --MOORE State-Machine - Outputs based on state only
   OUTPUT_DECODE: process (state)
   begin
		xfer_stb <= '0';
		
      if (state = stRegAddress or state = stRead or state = stWrite) then
			xfer_stb <= '1';
		end if;
   end process;
 
   NEXT_STATE_DECODE: process (state, xfer_done, xfer_end, rd_wrn)
   begin
      --declare default state for next_state to avoid latches
      nstate <= state;
      case (state) is
         when stIdle =>
            if (xfer_done = '1') then
               if (rd_wrn = '1') then
						nstate <= stRead;
					else
						nstate <= stRegAddress;
					end if;
            end if;
				
         when stRegAddress =>
				if (xfer_end = '1') then
					nstate <= stIdle;
				elsif (xfer_done = '1') then
               nstate <= stWrite;
            end if;
				
         when stWrite =>
            if (xfer_end = '1') then
					nstate <= stIdle;
				elsif (xfer_done = '1') then
					nstate <= stWrite;
				end if;
				
			when stRead =>
				if (xfer_end = '1') then
					nstate <= stIdle;
				elsif (xfer_done = '1') then
					nstate <= stRead;
				end if;
				
         when others =>
            nstate <= stIdle;
      end case;      
   end process;

end Behavioral;

