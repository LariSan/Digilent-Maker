------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.            **
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
-- Date:              Wed May 18 09:46:22 2011 (by Create and Import Peripheral Wizard)
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
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
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
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 19
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
	 PIX_CLK_I		: in std_logic;
	 PLL_LOCKED_I  : in std_logic;
	 HSYNC_I			: in std_logic;
	 VSYNC_I			: in std_logic;
	 DE_I				: in std_logic;
	 DATA_I		   : in std_logic_vector (23 downto 0);
	 HSYNC_O			: out std_logic;
	 VSYNC_O			: out std_logic;
	 DE_O				: out std_logic;
	 DATA_O		   : out std_logic_vector (23 downto 0);
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Resetn                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Resetn  : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  --USER signal declarations added here, as needed for user logic
  COMPONENT fifo
    PORT(
         clk : IN  std_logic;
         srst : IN  std_logic;
         din : IN  std_logic_vector(23 downto 0);
         wr_en : IN  std_logic;
         rd_en : IN  std_logic;
         dout : OUT  std_logic_vector(23 downto 0);
         full : OUT  std_logic;
         empty : OUT  std_logic;
         data_count : OUT  std_logic_vector(10 downto 0)
        );
   END COMPONENT;
   
   component mult
		port (
		clk: in std_logic;
		a: in std_logic_vector(7 downto 0);
		b: in std_logic_vector(7 downto 0);
		p: out std_logic_vector(15 downto 0));
   end component;

--   signal de_i : std_logic := '0'; -- internal de signal
--	signal hsync_i : std_logic := '0'; -- Internal vsync,so we can check its state
--	signal vsync_i : std_logic := '0'; -- Internal hsync," " "
--	signal data_i:std_logic_vector(23 downto 0) := (others => '0');	
	
	signal srst : std_logic := '0';
	
	--fifo1
   signal din1 : std_logic_vector(23 downto 0) := (others => '0');
   signal wr_en1 : std_logic := '0';
   signal rd_en1 : std_logic := '0';
	signal dout1 : std_logic_vector(23 downto 0);
   signal full1 : std_logic;
   signal empty1 : std_logic;
   signal data_count1 : std_logic_vector(10 downto 0);
	
	--fifo2
	signal din2 : std_logic_vector(23 downto 0) := (others => '0');
   signal wr_en2 : std_logic := '0';
   signal rd_en2 : std_logic := '0';
   signal dout2 : std_logic_vector(23 downto 0);
   signal full2 : std_logic;
   signal empty2 : std_logic;
   signal data_count2 : std_logic_vector(10 downto 0);
	
	--fifo3(no instance)
	signal din3 : std_logic_vector(23 downto 0) := (others => '0');
  	
	--sync
	signal line_count:std_logic_vector(12 downto 0) := (others => '0');
	signal pix_count:std_logic_vector(12 downto 0) := (others => '0');
	signal vsync_reg: std_logic_vector(1 downto 0);
	
	--internal signals for fifos
	signal wr_en1_t : std_logic := '0';
	signal rd_en1_t : std_logic := '0';
	signal wr_en2_t : std_logic := '0';
	signal rd_en2_t : std_logic := '0';
	signal din1_t : std_logic_vector(23 downto 0) := (others => '0');
	signal din2_t : std_logic_vector(23 downto 0) := (others => '0');
	signal din3_t : std_logic_vector(23 downto 0) := (others => '0');
	
	--internal signals for output sync
	signal hsync_t: std_logic;
	signal vsync_t: std_logic;
	signal de_t: std_logic;
	
	signal sync_en: std_logic:='0';
	
	--signal for matrix
	signal a11:std_logic_vector(23 downto 0);
	signal a12:std_logic_vector(23 downto 0);
	signal a13:std_logic_vector(23 downto 0);
	signal a21:std_logic_vector(23 downto 0);
	signal a22:std_logic_vector(23 downto 0);
	signal a23:std_logic_vector(23 downto 0);
	signal a31:std_logic_vector(23 downto 0);
	signal a32:std_logic_vector(23 downto 0);
	signal a33:std_logic_vector(23 downto 0);
	
	--signal for mult output
   signal red11:std_logic_vector(15 downto 0);
	signal red12:std_logic_vector(15 downto 0);
	signal red13:std_logic_vector(15 downto 0);
	signal red21:std_logic_vector(15 downto 0);
	signal red22:std_logic_vector(15 downto 0);
	signal red23:std_logic_vector(15 downto 0);
	signal red31:std_logic_vector(15 downto 0);
	signal red32:std_logic_vector(15 downto 0);
	signal red33:std_logic_vector(15 downto 0);
	
	signal green11:std_logic_vector(15 downto 0);
	signal green12:std_logic_vector(15 downto 0);
	signal green13:std_logic_vector(15 downto 0);
	signal green21:std_logic_vector(15 downto 0);
	signal green22:std_logic_vector(15 downto 0);
	signal green23:std_logic_vector(15 downto 0);
	signal green31:std_logic_vector(15 downto 0);
	signal green32:std_logic_vector(15 downto 0);
	signal green33:std_logic_vector(15 downto 0);
	
	signal blue11:std_logic_vector(15 downto 0);
	signal blue12:std_logic_vector(15 downto 0);
	signal blue13:std_logic_vector(15 downto 0);
	signal blue21:std_logic_vector(15 downto 0);
	signal blue22:std_logic_vector(15 downto 0);
	signal blue23:std_logic_vector(15 downto 0);
	signal blue31:std_logic_vector(15 downto 0);
	signal blue32:std_logic_vector(15 downto 0);
	signal blue33:std_logic_vector(15 downto 0);

	signal red_i: std_logic_vector(15 downto 0);
	signal red_t: std_logic_vector(7 downto 0);
	signal red_t_div2: std_logic_vector(7 downto 0);
	signal red_t_div4: std_logic_vector(7 downto 0);
	signal red_t_div8: std_logic_vector(7 downto 0);
	signal red_t_div16: std_logic_vector(7 downto 0);
	
	signal green_i: std_logic_vector(15 downto 0);
	signal green_t: std_logic_vector(7 downto 0);
	signal green_t_div2: std_logic_vector(7 downto 0);
	signal green_t_div4: std_logic_vector(7 downto 0);
	signal green_t_div8: std_logic_vector(7 downto 0);
	signal green_t_div16: std_logic_vector(7 downto 0);
	
	signal blue_i: std_logic_vector(15 downto 0);
	signal blue_t: std_logic_vector(7 downto 0);
	signal blue_t_div2: std_logic_vector(7 downto 0);
	signal blue_t_div4: std_logic_vector(7 downto 0);
	signal blue_t_div8: std_logic_vector(7 downto 0);
	signal blue_t_div16: std_logic_vector(7 downto 0);
	
	signal data_t: std_logic_vector(23 downto 0);
--	signal data_t_div8: std_logic_vector(23 downto 0);
--	signal data_t_div16: std_logic_vector(23 downto 0);
	
	--parameter for sync gen
	signal hsync_duration_check: std_logic_vector(12 downto 0);
	signal hsync_backporch_check: std_logic_vector(12 downto 0);
	signal hsync_frontporch_check: std_logic_vector(12 downto 0);
	signal hsync_end_check:std_logic_vector(12 downto 0);
	
	signal vsync_duration_check: std_logic_vector(12 downto 0);
	signal vsync_backporch_check: std_logic_vector(12 downto 0);
	signal vsync_frontporch_check: std_logic_vector(12 downto 0);
	signal vsync_end_check:std_logic_vector(12 downto 0);
  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal slv_reg0                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg1                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg2                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg3                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg4                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg5                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg6                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg7                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg8                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg9                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg10                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg11                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg12                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg13                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg14                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg15                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg16                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg17                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg18                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg_write_sel              : std_logic_vector(0 to 18);
  signal slv_reg_read_sel               : std_logic_vector(0 to 18);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

  signal Bus2IP_Reset : std_logic;
  
begin

Bus2IP_Reset <= not (Bus2IP_Resetn);

  --USER logic implementation added here
  uut1: fifo PORT MAP (
          clk => PIX_CLK_I,
          srst => srst,
          din => din1,
          wr_en => wr_en1,
          rd_en => rd_en1,
          dout => dout1,
          full => full1,
          empty => empty1,
          data_count => data_count1
        );
	uut2: fifo PORT MAP (
          clk => PIX_CLK_I,
          srst => srst,
          din => din2,
          wr_en => wr_en2,
          rd_en => rd_en2,
          dout => dout2,
          full => full2,
          empty => empty2,
          data_count => data_count2
        );
   
	--red mult
	r11 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg1(24 to 31),
			b => a11(23 downto 16),
			p => red11);
	r12 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg2(24 to 31),
			b => a12(23 downto 16),
			p => red12);
	r13 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg3(24 to 31),
			b => a13(23 downto 16),
			p => red13);
	r21 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg4(24 to 31),
			b => a21(23 downto 16),
			p => red21);
	r22 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg5(24 to 31),
			b => a22(23 downto 16),
			p => red22);
	r23 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg6(24 to 31),
			b => a23(23 downto 16),
			p => red23);
	r31 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg7(24 to 31),
			b => a31(23 downto 16),
			p => red31);
	r32 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg8(24 to 31),
			b => a32(23 downto 16),
			p => red32);
	r33 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg9(24 to 31),
			b => a33(23 downto 16),
			p => red33);
	
	--green mult
	g11 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg1(24 to 31),
			b => a11(15 downto 8),
			p => green11);
	g12 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg2(24 to 31),
			b => a12(15 downto 8),
			p => green12);
	g13 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg3(24 to 31),
			b => a13(15 downto 8),
			p => green13);
	g21 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg4(24 to 31),
			b => a21(15 downto 8),
			p => green21);
	g22 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg5(24 to 31),
			b => a22(15 downto 8),
			p => green22);
	g23 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg6(24 to 31),
			b => a23(15 downto 8),
			p => green23);
	g31 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg7(24 to 31),
			b => a31(15 downto 8),
			p => green31);
	g32 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg8(24 to 31),
			b => a32(15 downto 8),
			p => green32);
	g33 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg9(24 to 31),
			b => a33(15 downto 8),
			p => green33);
			
	--blue mult
	b11 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg1(24 to 31),
			b => a11(7 downto 0),
			p => blue11);
	b12 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg2(24 to 31),
			b => a12(7 downto 0),
			p => blue12);
	b13 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg3(24 to 31),
			b => a13(7 downto 0),
			p => blue13);
	b21 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg4(24 to 31),
			b => a21(7 downto 0),
			p => blue21);
	b22 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg5(24 to 31),
			b => a22(7 downto 0),
			p => blue22);
	b23 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg6(24 to 31),
			b => a23(7 downto 0),
			p => blue23);
	b31 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg7(24 to 31),
			b => a31(7 downto 0),
			p => blue31);
	b32 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg8(24 to 31),
			b => a32(7 downto 0),
			p => blue32);
	b33 : mult
		port map (
			clk => PIX_CLK_I,
			a => slv_reg9(24 to 31),
			b => a33(7 downto 0),
			p => blue33);
		  
   srst <= '1' when (line_count = "0000000000010" and pix_count >= hsync_backporch_check and pix_count < hsync_frontporch_check) 
	        or Bus2IP_Reset = '1' or slv_reg0(31) = '0' or PLL_LOCKED_I = '0'
	   else '0';
	
	wr_en1_t <= '1' when DE_I = '1' or (DE_I = '0' and line_count = vsync_frontporch_check and pix_count >= hsync_backporch_check and pix_count < hsync_frontporch_check)
			 else '0';
	rd_en1_t <= '1' when ((pix_count >= hsync_backporch_check - "0000000000010") and (pix_count < hsync_frontporch_check - "0000000000010")
					and (line_count >= vsync_backporch_check + "0000000000001") and (line_count < vsync_frontporch_check + "0000000000001"))
			 else '0';
	din1_t <= DATA_I when DE_I = '1' else
				 (others => '0');
	
	f1:process(PIX_CLK_I)
	begin
	   if srst = '1' then
		   wr_en1 <= '0';
			rd_en1 <= '0';
		   din1 <= (others => '0');
	   elsif PIX_CLK_I'event and PIX_CLK_I = '1' then
		   wr_en1 <= wr_en1_t;
			rd_en1 <= rd_en1_t;
		   din1 <= din1_t;
		end if;
	end process f1;
	
	wr_en2_t <= '1' when ((pix_count >= hsync_backporch_check) and (pix_count < hsync_frontporch_check)
					and (line_count >= vsync_backporch_check + "0000000000001") and (line_count < vsync_frontporch_check + "0000000000001"))
	       else '0';
	rd_en2_t <= '1' when ((pix_count >= hsync_backporch_check - "0000000000010") and (pix_count < hsync_frontporch_check - "0000000000010")
					and (line_count >= vsync_backporch_check + "0000000000010") and (line_count < vsync_frontporch_check + "0000000000001"))
				else '0';
	din2_t <= dout1 when wr_en2_t = '1' else
	        (others => '0');
	
	f2:process(PIX_CLK_I)
	begin
	   if srst = '1' then
		   wr_en2 <= '0';
			rd_en2 <= '0';
		   din2 <= (others => '0');
	   elsif PIX_CLK_I'event and PIX_CLK_I = '1' then
		   wr_en2 <= wr_en2_t;
			rd_en2 <= rd_en2_t;
		   din2 <= din2_t;
		end if;
	end process f2;
	
	din3_t <= dout2 when ((pix_count >= hsync_backporch_check) and (pix_count < hsync_frontporch_check)
				and (line_count >= vsync_backporch_check + "0000000000010") and (line_count < vsync_frontporch_check + "0000000000001")) else
				(others => '0');
	
	f3:process(PIX_CLK_I)
	begin
	   if srst = '1' then
		   din3 <= (others => '0');
	   elsif PIX_CLK_I'event and PIX_CLK_I = '1' then
		   din3 <= din3_t;
		end if;
	end process f3;
	
	vsync_reg(0) <= VSYNC_I;
	sreg:process(PIX_CLK_I)
	begin
		if PIX_CLK_I'event and PIX_CLK_I = '1' then
			vsync_reg(1) <= vsync_reg(0);
		end if;
	end process sreg;
	
	sync_en <= '1' when vsync_reg = "01" else
	           '0';
		
   hsync_duration_check <= slv_reg11(19 to 31);
	hsync_backporch_check <= slv_reg12(19 to 31);
	hsync_frontporch_check <= slv_reg13(19 to 31);
	hsync_end_check <= slv_reg14(19 to 31);
	
	vsync_duration_check <= slv_reg15(19 to 31);
	vsync_backporch_check <= slv_reg16(19 to 31);
	vsync_frontporch_check <= slv_reg17(19 to 31);
	vsync_end_check <= slv_reg18(19 to 31);
	
--	sync:process(PIX_CLK_I)
--	begin
--		if PIX_CLK_I'event and PIX_CLK_I = '1' then
--		   if Bus2IP_Reset = '1' or PLL_LOCKED_I = '0' then
--			   pix_count <= (others => '0');
--				line_count <= (others => '0');
--			else
--				if sync_en = '1' then
--					pix_count <= "0000000000001";
--					line_count <= "0000000000101";
--				else
--					if(pix_count = hsync_end_check - "0000000000001") then
--						pix_count <= (others => '0');
--						if (line_count = vsync_end_check - "0000000000001") then
--							line_count <= (others => '0');
--						else
--							line_count <= line_count + "0000000000001";
--						end if;
--					else
--						pix_count <= pix_count + "0000000000001";
--					end if;
--				end if;
--			end if;
--		end if;
--	end process sync;
	process(PIX_CLK_I)
	begin
	   if PIX_CLK_I'event and PIX_CLK_I = '1' then
			if Bus2IP_Reset = '1' or PLL_LOCKED_I = '0' then
				pix_count <= (others => '0');
				line_count <= (others => '0');
			else
			   if sync_en = '1' then
				   pix_count <= "0000000000001";
				   line_count <= (others => '0');
				else
					if pix_count < hsync_end_check then
						pix_count <= pix_count + 1;
					else
						pix_count <= (others => '0');
						if line_count < vsync_end_check then
							line_count <= line_count + 1;
						else
							line_count <= (others => '0');
						end if;
					end if;
				end if;
			end if;
	   end if;
	end process;
	
	matr:process(PIX_CLK_I)
	begin
	   if Bus2IP_Reset = '1' or slv_reg0(31) = '0' or PLL_LOCKED_I = '0' then
		   a11 <= (others => '0');
			a12 <= (others => '0');
			a13 <= (others => '0');
			a21 <= (others => '0');
			a22 <= (others => '0');
			a23 <= (others => '0');
			a31 <= (others => '0');
			a32 <= (others => '0');
			a33 <= (others => '0');
		else
		   if PIX_CLK_I'event and PIX_CLK_I = '1' then
			   if ((pix_count >= hsync_backporch_check - "0000000000010") and (pix_count < hsync_frontporch_check + "0000000000010")
					and (line_count >= vsync_backporch_check + "0000000000001") and (line_count < vsync_frontporch_check + "0000000000001")) then
					a11 <= a12;
					a21 <= a22;
					a31 <= a32;
					a12 <= a13;
					a22 <= a23;
					a32 <= a33;
					a13 <= din3;
					a23 <= din2;
					a33 <= din1;
				end if;
			end if;
		end if;
	end process matr;
	
	hsync_t <= '1' when (pix_count >= "0000000000101") and (pix_count < hsync_duration_check + "0000000000101") else
				  '0';
	vsync_t <= '1' when (line_count >= "0000000000001") and (line_count < vsync_duration_check + "0000000000001") else
	           '0';
	de_t <= '1' when (pix_count >= hsync_backporch_check + "0000000000101") and (pix_count < hsync_frontporch_check + "0000000000101")
					and (line_count >= vsync_backporch_check + "0000000000001") and (line_count < vsync_frontporch_check + "0000000000001") else
			  '0';
   
	red_i <= red11 + red12 +red13 + red21 + red22 + red23 + red31 + red32 + red33;
--	red_t <= (red_i(10 downto 3) + "01111111") when ((pix_count >= 265) and (pix_count < 1545)
--					and (line_count >= 26) and (line_count < 746)) else
--	         (others => '0');
   red_t <= red_i(7 downto 0) when red_i(15) = '0' and de_t = '1' else
	          (not red_i(7) & not red_i(6) & not red_i(5) & not red_i(4) & not red_i(3) & not red_i(2) & not red_i(1) & not red_i(0))
				 when red_i(15) = '1' and de_t = '1' else
				 (others => '0');
   red_t_div2 <= red_i(8 downto 1) when red_i(15) = '0' and de_t = '1' else
	          (not red_i(8) & not red_i(7) & not red_i(6) & not red_i(5) & not red_i(4) & not red_i(3) & not red_i(2) & not red_i(1))
				 when red_i(15) = '1' and de_t = '1' else
				 (others => '0');
	red_t_div4 <= red_i(9 downto 2) when red_i(15) = '0' and de_t = '1' else
	          (not red_i(9) & not red_i(8) & not red_i(7) & not red_i(6) & not red_i(5) & not red_i(4) & not red_i(3) & not red_i(2))				
             when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
	red_t_div8 <= red_i(10 downto 3) when red_i(15) = '0' and de_t = '1' else
	          (not red_i(10) & not red_i(9) & not red_i(8) & not red_i(7) & not red_i(6) & not red_i(5) & not red_i(4) & not red_i(3))				
             when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
	red_t_div16 <= red_i(11 downto 4) when red_i(15) = '0' and de_t = '1' else
	          (not red_i(11) & not red_i(10) & not red_i(9) & not red_i(8) & not red_i(7) & not red_i(6) & not red_i(5) & not red_i(4))				
             when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
				 
	green_i <= green11 + green12 +green13 + green21 + green22 + green23 + green31 + green32 + green33;
--	green_t <= (green_i(10 downto 3) + "01111111") when ((pix_count >= 265) and (pix_count < 1545)
--					and (line_count >= 26) and (line_count < 746)) else
--	         (others => '0');
   green_t <= green_i(7 downto 0) when green_i(15) = '0' and de_t = '1' else
	          (not green_i(7) & not green_i(6) & not green_i(5) & not green_i(4) & not green_i(3) & not green_i(2) & not green_i(1) & not green_i(0))
				 when green_i(15) = '1' and de_t = '1' else
				 (others => '0');
   green_t_div2 <= green_i(8 downto 1) when green_i(15) = '0' and de_t = '1' else
	          (not green_i(8) & not green_i(7) & not green_i(6) & not green_i(5) & not green_i(4) & not green_i(3) & not green_i(2) & not green_i(1))
				 when green_i(15) = '1' and de_t = '1' else
				 (others => '0');
	green_t_div4 <= green_i(9 downto 2) when green_i(15) = '0' and de_t = '1' else
	          (not green_i(9) & not green_i(8) & not green_i(7) & not green_i(6) & not green_i(5) & not green_i(4) & not green_i(3) & not green_i(2))
	          when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
	green_t_div8 <= green_i(10 downto 3) when green_i(15) = '0' and de_t = '1' else
	          (not green_i(10) & not green_i(9) & not green_i(8) & not green_i(7) & not green_i(6) & not green_i(5) & not green_i(4) & not green_i(3))
	          when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
	green_t_div16 <= green_i(11 downto 4) when green_i(15) = '0' and de_t = '1' else
	          (not green_i(11) & not green_i(10) & not green_i(9) & not green_i(8) & not green_i(7) & not green_i(6) & not green_i(5) & not green_i(4))
	          when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
				 
	blue_i <= blue11 + blue12 +blue13 + blue21 + blue22 + blue23 + blue31 + blue32 + blue33;
--	blue_t <= (blue_i(10 downto 3) + "01111111") when ((pix_count >= 265) and (pix_count < 1545)
--					and (line_count >= 26) and (line_count < 746)) else
--	         (others => '0');
   blue_t <= blue_i(7 downto 0) when blue_i(15) = '0' and de_t = '1' else
	          (not blue_i(7) & not blue_i(6) & not blue_i(5) & not blue_i(4) & not blue_i(3) & not blue_i(2) & not blue_i(1) & not blue_i(0))
				 when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
   blue_t_div2 <= blue_i(8 downto 1) when blue_i(15) = '0' and de_t = '1' else
	          (not blue_i(8) & not blue_i(7) & not blue_i(6) & not blue_i(5) & not blue_i(4) & not blue_i(3) & not blue_i(2) & not blue_i(1))
				 when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
	blue_t_div4 <= blue_i(9 downto 2) when blue_i(15) = '0' and de_t = '1' else
	          (not blue_i(9) & not blue_i(8) & not blue_i(7) & not blue_i(6) & not blue_i(5) & not blue_i(4) & not blue_i(3) & not blue_i(2))
				 when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
   blue_t_div8 <= blue_i(10 downto 3) when blue_i(15) = '0' and de_t = '1' else
	          (not blue_i(10) & not blue_i(9) & not blue_i(8) & not blue_i(7) & not blue_i(6) & not blue_i(5) & not blue_i(4) & not blue_i(3))
				 when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
	blue_t_div16 <= blue_i(11 downto 4) when blue_i(15) = '0' and de_t = '1' else
	          (not blue_i(11) & not blue_i(10) & not blue_i(9) & not blue_i(8) & not blue_i(7) & not blue_i(6) & not blue_i(5) & not blue_i(4))
				 when blue_i(15) = '1' and de_t = '1' else
				 (others => '0');
				 
	data_t <= red_t & green_t & blue_t when slv_reg10(27 to 31) = "00001" else
	          red_t_div2 & green_t_div2 & blue_t_div2 when slv_reg10(27 to 31) = "00010" else
	          red_t_div4 & green_t_div4 & blue_t_div4 when slv_reg10(27 to 31) = "00100" else
	          red_t_div8 & green_t_div8 & blue_t_div8 when slv_reg10(27 to 31) = "01000" else
				 red_t_div16 & green_t_div16 & blue_t_div16 when slv_reg10(27 to 31) = "10000" else
				 (others => '0');
	
	process(PIX_CLK_I)
	begin
	   if Bus2IP_Reset = '1' or PLL_LOCKED_I = '0'then
		   HSYNC_O <= '0';
			VSYNC_O <= '0';
			DE_O <= '0';
			DATA_O <= (others => '0');
		else			
		   if PIX_CLK_I'event and PIX_CLK_I = '1' then
			   if slv_reg0(31) = '0' then
					HSYNC_O <= HSYNC_I;
					VSYNC_O <= VSYNC_I;
					DE_O <= DE_I;
					DATA_O <= DATA_I;
				else
					HSYNC_O <= hsync_t;
					VSYNC_O <= vsync_t;
					DE_O <= de_t;
					DATA_O <= data_t;
				end if;
			end if;
		end if;
	end process;
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
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 18);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 18);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4) or Bus2IP_WrCE(5) or Bus2IP_WrCE(6) or Bus2IP_WrCE(7) or Bus2IP_WrCE(8) or Bus2IP_WrCE(9) or Bus2IP_WrCE(10) or Bus2IP_WrCE(11) or Bus2IP_WrCE(12) or Bus2IP_WrCE(13) or Bus2IP_WrCE(14) or Bus2IP_WrCE(15) or Bus2IP_WrCE(16) or Bus2IP_WrCE(17) or Bus2IP_WrCE(18);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4) or Bus2IP_RdCE(5) or Bus2IP_RdCE(6) or Bus2IP_RdCE(7) or Bus2IP_RdCE(8) or Bus2IP_RdCE(9) or Bus2IP_RdCE(10) or Bus2IP_RdCE(11) or Bus2IP_RdCE(12) or Bus2IP_RdCE(13) or Bus2IP_RdCE(14) or Bus2IP_RdCE(15) or Bus2IP_RdCE(16) or Bus2IP_RdCE(17) or Bus2IP_RdCE(18);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        slv_reg0 <= (others => '0');
        slv_reg1 <= (others => '0');
        slv_reg2 <= (others => '0');
        slv_reg3 <= (others => '0');
        slv_reg4 <= (others => '0');
        slv_reg5 <= (others => '0');
        slv_reg6 <= (others => '0');
        slv_reg7 <= (others => '0');
        slv_reg8 <= (others => '0');
        slv_reg9 <= (others => '0');
        slv_reg10 <= (others => '0');
        slv_reg11 <= (others => '0');
        slv_reg12 <= (others => '0');
        slv_reg13 <= (others => '0');
        slv_reg14 <= (others => '0');
        slv_reg15 <= (others => '0');
        slv_reg16 <= (others => '0');
        slv_reg17 <= (others => '0');
        slv_reg18 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "1000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg0(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0100000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg1(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0010000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg2(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0001000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg3(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000100000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg4(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000010000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg5(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000001000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg6(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000100000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg7(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000010000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg8(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000001000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg9(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000100000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg10(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000010000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg11(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000001000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg12(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000100000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg13(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000010000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg14(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000001000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg15(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000000100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg16(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000000010" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg17(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000000001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg18(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when others => null;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, slv_reg18 ) is
  begin

    case slv_reg_read_sel is
      when "1000000000000000000" => slv_ip2bus_data <= slv_reg0;
      when "0100000000000000000" => slv_ip2bus_data <= slv_reg1;
      when "0010000000000000000" => slv_ip2bus_data <= slv_reg2;
      when "0001000000000000000" => slv_ip2bus_data <= slv_reg3;
      when "0000100000000000000" => slv_ip2bus_data <= slv_reg4;
      when "0000010000000000000" => slv_ip2bus_data <= slv_reg5;
      when "0000001000000000000" => slv_ip2bus_data <= slv_reg6;
      when "0000000100000000000" => slv_ip2bus_data <= slv_reg7;
      when "0000000010000000000" => slv_ip2bus_data <= slv_reg8;
      when "0000000001000000000" => slv_ip2bus_data <= slv_reg9;
      when "0000000000100000000" => slv_ip2bus_data <= slv_reg10;
      when "0000000000010000000" => slv_ip2bus_data <= slv_reg11;
      when "0000000000001000000" => slv_ip2bus_data <= slv_reg12;
      when "0000000000000100000" => slv_ip2bus_data <= slv_reg13;
      when "0000000000000010000" => slv_ip2bus_data <= slv_reg14;
      when "0000000000000001000" => slv_ip2bus_data <= slv_reg15;
      when "0000000000000000100" => slv_ip2bus_data <= slv_reg16;
      when "0000000000000000010" => slv_ip2bus_data <= slv_reg17;
      when "0000000000000000001" => slv_ip2bus_data <= slv_reg18;
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
