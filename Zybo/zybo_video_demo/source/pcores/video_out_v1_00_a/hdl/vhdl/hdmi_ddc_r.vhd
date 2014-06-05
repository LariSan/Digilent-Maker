----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:25:53 08/22/2013 
-- Design Name: 
-- Module Name:    hdmi_ddc_r - Behavioral 
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

entity hdmi_ddc_r is
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
      scl_t          : out std_logic
      --scl            : inout std_logic;
      --sda            : inout std_logic
   );
end hdmi_ddc_r;

architecture Behavioral of hdmi_ddc_r is

component TWICtl is
	generic (CLOCKFREQ : natural := 50); -- input CLK frequency in MHz
	port (
		MSG_I : in STD_LOGIC; --new message
		STB_I : in STD_LOGIC; --strobe
		A_I : in  STD_LOGIC_VECTOR (7 downto 0); --address input bus
		D_I : in  STD_LOGIC_VECTOR (7 downto 0); --data input bus
		D_O : out  STD_LOGIC_VECTOR (7 downto 0); --data output bus
		DONE_O : out  STD_LOGIC; --done status signal
      ERR_O : out  STD_LOGIC; --error status
		CLK : in std_logic;
		SRST : in std_logic;
      SDA_I : in std_logic;
      SDA_O : out std_logic;
      SDA_T : out std_logic;
      SCL_I : in std_logic;
      SCL_O : out std_logic;
      SCL_T : out std_logic
		--SDA : inout std_logic; --TWI SDA
		--SCL : inout std_logic --TWI SCL
	);
end component;

type states is (stIdle, stSendData, stDone, stErr);

signal state, nstate : states := stIdle;
signal int_stb, int_start : std_logic;
signal fDone, fErr : std_logic;
signal cnt : integer range 0 to 270 := 0;
signal bSum, dRead, chckSum : std_logic_vector(7 downto 0);

attribute KEEP : string;
attribute KEEP of dRead: signal is "TRUE";
attribute KEEP of state: signal is "TRUE";

begin
   
   Inst_TwiMaster: TWICtl
	generic map(CLOCKFREQ => 125)
	port map(
		MSG_I    => '0',
		STB_I    => int_stb,
		A_I      => x"A1",
		D_I      => (others => '0'),
		D_O      => dRead,
		DONE_O   => fDone,
      ERR_O    => fErr,
		CLK      => clk_i,
		SRST     => rst_i,
      SDA_I    => sda_i,
      SDA_O    => sda_o,
      SDA_T    => sda_t,
      SCL_I    => scl_i,
      SCL_O    => scl_o,
      SCL_T    => scl_t);
		--SDA      => sda,
		--SCL      => scl);
   
   process(clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i = '1' then
            state <= stIdle;
         else
            state <= nstate;
            int_start <= start_i;
         end if;
      end if;
   end process;
   
   process(state, nstate, int_start, cnt, fErr)
   begin
      nstate <= state;
      case(state) is
         when stIdle =>
            if int_start = '1' then
               nstate <= stSendData;
            end if;
         when stSendData =>
            if cnt = 128 then
               nstate <= stDone;
            elsif fErr = '1' then --and cnt /= 66 then
               nstate <= stErr;
            end if;
         when stDone =>
               nstate <= stDone;
         when stErr => 
            if int_start = '1' then
               --nstate <= stIdle;
               nstate <= stErr;
            end if;
         when others => nstate <= stIdle;
      end case;
   end process;
   
   process(clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i = '1' or state = stIdle then
            cnt <= 0;
         elsif state = stSendData and fDone = '1' and fErr = '0' then
            cnt <= cnt + 1;
         end if;
      end if;
   end process;
   
   process(clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i = '1' or state = stIdle then
            bSum <= (others => '0');
            chckSum <= (others => '0');
         elsif state = stSendData and fDone = '1' and fErr = '0' then
            if cnt < 128 then
               bSum <= bSum + dRead;
            else
               chckSum <= (not bSum) + x"01";
               if chckSum /= dRead then
                  chckSumErr_o <= '1';
               else
                  chckSumErr_o <= '0';
               end if;
            end if;
         end if;
      end if;
   end process;
   
   TwiErr_o <= '1' when state = stErr else '0';
   TwiRun_o <= '1' when state = stDone else '0';
   int_stb <= '1' when state = stSendData else '0';

end Behavioral;

