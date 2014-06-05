------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Sat Sep 28 10:06:38 2013 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_NUM_REG                    -- Number of software accessible registers
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Resetn                -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_NUM_REG                      : integer              := 13;
    C_SLV_DWIDTH                   : integer              := 32
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
      REF_CLK_I                     : in  std_logic;
      PXL_CLK_O                     : out  std_logic;
    
		TDATA_I : IN std_logic_vector(31 downto 0);
		TVALID_I : IN std_logic;
    	TREADY_O : OUT std_logic;
		FSYNC_O : OUT std_logic;
      
		HSYNC_O : OUT std_logic;
		VSYNC_O : OUT std_logic;
		RED_O : OUT std_logic_vector(4 downto 0);
		GREEN_O : OUT std_logic_vector(5 downto 0);
		BLUE_O : OUT std_logic_vector(4 downto 0);
		
		LED_O : OUT std_logic_vector(3 downto 0); 
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Resetn                  : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    Bus2IP_BE                      : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
    Bus2IP_RdCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
    Bus2IP_WrCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
    IP2Bus_Data                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Resetn : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

	COMPONENT mmcme2_drp
	PORT(
		SEN : IN std_logic;
		SCLK : IN std_logic;
		RST : IN std_logic;
		S1_CLKOUT0 : IN std_logic_vector(35 downto 0);
		S1_CLKFBOUT : IN std_logic_vector(35 downto 0);
		S1_DIVCLK : IN std_logic_vector(13 downto 0);
		S1_LOCK : IN std_logic_vector(39 downto 0);
		S1_DIGITAL_FILT : IN std_logic_vector(9 downto 0);
		REF_CLK : IN std_logic;          
		SRDY : OUT std_logic;
		PXL_CLK : OUT std_logic;
		LOCKED_O : OUT std_logic
		);
	END COMPONENT;
   
   COMPONENT vdma_to_vga
	PORT(
		PXL_CLK_I : IN std_logic;
		LOCKED_I : IN std_logic;
		ENABLE_I : IN std_logic;
		TDATA_I : IN std_logic_vector(31 downto 0);
		TVALID_I : IN std_logic;
		USR_WIDTH_I : IN std_logic_vector(11 downto 0);
		USR_HEIGHT_I : IN std_logic_vector(11 downto 0);
		USR_HPS_I : IN std_logic_vector(11 downto 0);
		USR_HPE_I : IN std_logic_vector(11 downto 0);
		USR_HPOL_I : IN std_logic;
		USR_HMAX_I : IN std_logic_vector(11 downto 0);
		USR_VPS_I : IN std_logic_vector(11 downto 0);
		USR_VPE_I : IN std_logic_vector(11 downto 0);
		USR_VPOL_I : IN std_logic;
		USR_VMAX_I : IN std_logic_vector(11 downto 0);          
		RUNNING_O : OUT std_logic;
		TREADY_O : OUT std_logic;
		FSYNC_O : OUT std_logic;
		HSYNC_O : OUT std_logic;
		VSYNC_O : OUT std_logic;
		RED_O : OUT std_logic_vector(4 downto 0);
		GREEN_O : OUT std_logic_vector(5 downto 0);
		BLUE_O : OUT std_logic_vector(4 downto 0)
		);
	END COMPONENT;

   
  type CLK_STATE_TYPE is (RESET, WAIT_LOCKED, WAIT_EN, WAIT_SRDY, WAIT_RUN, ENABLED, WAIT_FRAME_DONE);

  signal pxl_clk                   : std_logic;
  signal locked                    : std_logic;
  signal srdy                      : std_logic;
  
  signal enable_reg                    : std_logic := '0';
  signal sen_reg                    : std_logic := '0';
  
  signal vga_running                      : std_logic;
  
  
  signal clk_state                 : CLK_STATE_TYPE := RESET;
  
  signal clk_debug_cntr               : std_logic_vector(27 downto 0) := (others =>'0');
  signal clk_debug_reg				  : std_logic := '0';
  constant CLK_DEBUG_CNTR_MAX     : std_logic_vector(27 downto 0) := x"5F5E100"; --100,000,000
  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal CTRL_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal STAT_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal FRAME_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal HPARAM1_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal HPARAM2_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal VPARAM1_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal VPARAM2_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal CLK_O_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal CLK_FB_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal CLK_FRAC_REG                       : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal CLK_DIV_REG                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal CLK_LOCK_REG                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal CLK_FLTR_REG                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0) := (others => '0');
  signal slv_reg_write_sel              : std_logic_vector(12 downto 0);
  signal slv_reg_read_sel               : std_logic_vector(12 downto 0);
  signal slv_ip2bus_data                : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

begin


	Inst_mmcme2_drp: mmcme2_drp PORT MAP(
		SEN => sen_reg,
		SCLK => Bus2IP_Clk,
		RST => not(Bus2IP_Resetn),
		SRDY => srdy,
		S1_CLKOUT0 => CLK_FRAC_REG(3 downto 0) & CLK_O_REG,
		S1_CLKFBOUT => CLK_FRAC_REG(19 downto 16) & CLK_FB_REG,
		S1_DIVCLK => CLK_DIV_REG(13 downto 0),
		S1_LOCK => CLK_FLTR_REG(7 downto 0) & CLK_LOCK_REG,
		S1_DIGITAL_FILT => CLK_FLTR_REG(25 downto 16),
		REF_CLK => REF_CLK_I,
		PXL_CLK => pxl_clk,
		LOCKED_O => locked
	);
	
	PXL_CLK_O <= pxl_clk;
   
	process (Bus2IP_Clk)
	begin
      if (rising_edge(Bus2IP_Clk)) then
         if (Bus2IP_Resetn = '0') then
            clk_state <= RESET;
         else	
            case clk_state is 
            when RESET =>
               clk_state <= WAIT_LOCKED;
            when WAIT_LOCKED =>  --This state ensures that the initial SRDY pulse doesnt interfere with the WAIT_SRDY state
               if (locked = '1') then
                  clk_state <= WAIT_EN;
               end if;
            when WAIT_EN =>
               if (CTRL_REG(0) = '1') then
                  clk_state <= WAIT_SRDY;
               end if;
            when WAIT_SRDY =>
               if (srdy = '1') then 
                  clk_state <= WAIT_RUN;
               end if;
            when WAIT_RUN =>
               if (STAT_REG(0) = '1') then
                  clk_state <= ENABLED;
               end if;
            when ENABLED =>
               if (CTRL_REG(0) = '0') then
                  clk_state <= WAIT_FRAME_DONE;
               end if;
            when WAIT_FRAME_DONE =>
               if (STAT_REG(0) = '0') then
                  clk_state <= WAIT_EN;
               end if;
            when others => --Never reached
               clk_state <= RESET;
            end case;
         end if;
      end if;
   end process;
   
	process (Bus2IP_Clk)
	begin
      if (rising_edge(Bus2IP_Clk)) then
         if (Bus2IP_Resetn = '0') then
            enable_reg <= '0';
            sen_reg <= '0';
         else
            if (clk_state = WAIT_EN and CTRL_REG(0) = '1') then
               sen_reg <= '1';
            else
               sen_reg <= '0';
            end if;
            if (clk_state = WAIT_RUN or clk_state = ENABLED) then
               enable_reg <= '1';
            else
               enable_reg <= '0';
            end if;
         end if;
      end if;
   end process;
   
   
	Inst_vdma_to_vga: vdma_to_vga PORT MAP(
		PXL_CLK_I => pxl_clk,
		LOCKED_I => locked,
		ENABLE_I => enable_reg,
		RUNNING_O => vga_running,
		TDATA_I => TDATA_I,
		TVALID_I => TVALID_I,
		TREADY_O => TREADY_O,
		FSYNC_O => FSYNC_O,
		HSYNC_O => HSYNC_O,
		VSYNC_O => VSYNC_O,
		RED_O => RED_O,
		GREEN_O => GREEN_O,
		BLUE_O => BLUE_O,
		USR_WIDTH_I => FRAME_REG(27 downto 16),
		USR_HEIGHT_I => FRAME_REG(11 downto 0),
		USR_HPS_I => HPARAM1_REG(27 downto 16),
		USR_HPE_I => HPARAM1_REG(11 downto 0),
		USR_HPOL_I => HPARAM2_REG(16),
		USR_HMAX_I => HPARAM2_REG(11 downto 0),
		USR_VPS_I => VPARAM1_REG(27 downto 16),
		USR_VPE_I => VPARAM1_REG(11 downto 0),
		USR_VPOL_I => VPARAM2_REG(16),
		USR_VMAX_I => VPARAM2_REG(11 downto 0)
	);
       
	process (Bus2IP_Clk)
	begin
      if (rising_edge(Bus2IP_Clk)) then
         if (Bus2IP_Resetn = '0') then
            STAT_REG(0) <= '0';
         else
            STAT_REG(0) <= vga_running;
         end if;
      end if;
   end process;

   --LED DEBUG
      
  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      clk_debug_cntr <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (clk_debug_cntr = CLK_DEBUG_CNTR_MAX) then
        clk_debug_cntr <= (others =>'0'); 
      else
        clk_debug_cntr <= clk_debug_cntr + 1;
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      clk_debug_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if (clk_debug_cntr = CLK_DEBUG_CNTR_MAX) then
        clk_debug_reg <= not(clk_debug_reg); 
      end if;
    end if;
  end process;
  
  LED_O <= vga_running & enable_reg & CTRL_REG(0) & clk_debug_reg;

  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(12 downto 0);
  slv_reg_read_sel  <= Bus2IP_RdCE(12 downto 0);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4) or Bus2IP_WrCE(5) or Bus2IP_WrCE(6) or Bus2IP_WrCE(7) or Bus2IP_WrCE(8) or Bus2IP_WrCE(9) or Bus2IP_WrCE(10) or Bus2IP_WrCE(11) or Bus2IP_WrCE(12);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4) or Bus2IP_RdCE(5) or Bus2IP_RdCE(6) or Bus2IP_RdCE(7) or Bus2IP_RdCE(8) or Bus2IP_RdCE(9) or Bus2IP_RdCE(10) or Bus2IP_RdCE(11) or Bus2IP_RdCE(12);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Resetn = '0' then
        CTRL_REG <= (others => '0');
        --STAT_REG <= (others => '0');
        FRAME_REG <= (others => '0');
        HPARAM1_REG <= (others => '0');
        HPARAM2_REG <= (others => '0');
        VPARAM1_REG <= (others => '0');
        VPARAM2_REG <= (others => '0');
        CLK_O_REG <= (others => '0');
        CLK_FB_REG <= (others => '0');
        CLK_FRAC_REG <= (others => '0');
        CLK_DIV_REG <= (others => '0');
        CLK_LOCK_REG <= (others => '0');
        CLK_FLTR_REG <= (others => '0');
      else
        case slv_reg_write_sel is
          when "1000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CTRL_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
--***Status register is read only***  
--          when "0100000000000" =>
--            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
--              if ( Bus2IP_BE(byte_index) = '1' ) then
--                STAT_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
--              end if;
--            end loop;
          when "0010000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                FRAME_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0001000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                HPARAM1_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000100000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                HPARAM2_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000010000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                VPARAM1_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000001000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                VPARAM2_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000000100000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CLK_O_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000000010000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CLK_FB_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000000001000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CLK_FRAC_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000000000100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CLK_DIV_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000000000010" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CLK_LOCK_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "0000000000001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CLK_FLTR_REG(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when others => null;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, CTRL_REG, STAT_REG, FRAME_REG, HPARAM1_REG, HPARAM2_REG, VPARAM1_REG, VPARAM2_REG, CLK_O_REG, CLK_FB_REG, CLK_FRAC_REG, CLK_DIV_REG, CLK_LOCK_REG, CLK_FLTR_REG ) is
  begin

    case slv_reg_read_sel is
      when "1000000000000" => slv_ip2bus_data <= CTRL_REG;
      when "0100000000000" => slv_ip2bus_data <= STAT_REG;
      when "0010000000000" => slv_ip2bus_data <= FRAME_REG;
      when "0001000000000" => slv_ip2bus_data <= HPARAM1_REG;
      when "0000100000000" => slv_ip2bus_data <= HPARAM2_REG;
      when "0000010000000" => slv_ip2bus_data <= VPARAM1_REG;
      when "0000001000000" => slv_ip2bus_data <= VPARAM2_REG;
      when "0000000100000" => slv_ip2bus_data <= CLK_O_REG;
      when "0000000010000" => slv_ip2bus_data <= CLK_FB_REG;
      when "0000000001000" => slv_ip2bus_data <= CLK_FRAC_REG;
      when "0000000000100" => slv_ip2bus_data <= CLK_DIV_REG;
      when "0000000000010" => slv_ip2bus_data <= CLK_LOCK_REG;
      when "0000000000001" => slv_ip2bus_data <= CLK_FLTR_REG;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';
  
  

end IMP;
