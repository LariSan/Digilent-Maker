----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:39:50 09/28/2013 
-- Design Name: 
-- Module Name:    vdma_to_vga - Behavioral 
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
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vdma_to_vga is
    Port ( PXL_CLK_I : in  STD_LOGIC;
           LOCKED_I : in  STD_LOGIC;
           ENABLE_I : in  STD_LOGIC;
           RUNNING_O : out  STD_LOGIC;

           TDATA_I : in  STD_LOGIC_VECTOR (31 downto 0);
           TVALID_I : in  STD_LOGIC;
           TREADY_O : out  STD_LOGIC;
           FSYNC_O : out  STD_LOGIC;

           HSYNC_O : out  STD_LOGIC;
           VSYNC_O : out  STD_LOGIC;
           RED_O : out  STD_LOGIC_VECTOR (4 downto 0);
           GREEN_O : out  STD_LOGIC_VECTOR (5 downto 0);
           BLUE_O : out  STD_LOGIC_VECTOR (4 downto 0);

           USR_WIDTH_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HEIGHT_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HPS_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HPE_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_HPOL_I : in  STD_LOGIC;
           USR_HMAX_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_VPS_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_VPE_I : in  STD_LOGIC_VECTOR (11 downto 0);
           USR_VPOL_I : in  STD_LOGIC;
           USR_VMAX_I : in  STD_LOGIC_VECTOR (11 downto 0));
end vdma_to_vga;

architecture Behavioral of vdma_to_vga is


  type VGA_STATE_TYPE is (VGA_RESET, VGA_WAIT_EN, VGA_LATCH, VGA_INIT, VGA_RUN);

  signal pxl_clk                   : std_logic;
  signal locked                    : std_logic;
  signal vga_running               : std_logic;
  signal frame_edge                : std_logic;
  
  signal running_reg                : std_logic := '0';
  signal vga_en                    : std_logic := '0';

  signal frm_width : std_logic_vector(11 downto 0) := (others =>'0');
  signal frm_height : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_ps : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_pe : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_max : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_ps : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_pe : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_max : std_logic_vector(11 downto 0) := (others =>'0');
  signal h_pol                   : std_logic := '0';
  signal v_pol                   : std_logic := '0';


  signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

  signal h_sync_reg : std_logic := '0';
  signal v_sync_reg : std_logic := '0';
  signal h_sync_dly : std_logic := '0';
  signal v_sync_dly : std_logic := '0';

  signal fsync_reg : std_logic := '0';

  signal video_dv                   : std_logic := '0';

  signal red_reg : std_logic_vector(7 downto 0) := (others =>'0');
  signal green_reg : std_logic_vector(7 downto 0) := (others =>'0');
  signal blue_reg : std_logic_vector(7 downto 0) := (others =>'0');
  
  signal vga_state                 : VGA_STATE_TYPE := VGA_RESET;


begin

locked <= LOCKED_I;
pxl_clk <= PXL_CLK_I;


------------------------------------------------------------------
------                 CONTROL STATE MACHINE               -------
------------------------------------------------------------------
  
--Synchronize ENABLE_I signal from axi_lite domain to pixel clock
--domain
  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      vga_en <= '0';
    elsif (rising_edge(pxl_clk)) then
      vga_en <= ENABLE_I;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      vga_state <= VGA_RESET;
    elsif (rising_edge(pxl_clk)) then
      case vga_state is 
      when VGA_RESET =>
        vga_state <= VGA_WAIT_EN;
      when VGA_WAIT_EN =>
        if (vga_en = '1') then
          vga_state <= VGA_LATCH;
        end if;
      when VGA_LATCH =>
        vga_state <= VGA_INIT;
      when VGA_INIT =>
        vga_state <= VGA_RUN;
      when VGA_RUN =>
        if (vga_en = '0' and frame_edge = '1') then
          vga_state <= VGA_WAIT_EN;
        end if;
      when others => --Never reached
        vga_state <= VGA_RESET;
      end case;
    end if;
  end process;

  --This component treats the first pixel of the first non-visible line as the beginning
  --of the frame.
  frame_edge <= '1' when ((v_cntr_reg = frm_height) and (h_cntr_reg = 0)) else
                '0';

  vga_running <= '1' when vga_state = VGA_RUN else
                 '0'; 

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      running_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      running_reg <= vga_running;
    end if;
  end process;

  RUNNING_O <= running_reg;

------------------------------------------------------------------
------                  USER REGISTER LATCH                -------
------------------------------------------------------------------
--Note that the USR_ inputs are crossing from the axi_lite clock domain
--to the pixel clock domain


  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      frm_width <= (others => '0');
      frm_height <= (others => '0');
      h_ps <= (others => '0');
      h_pe <= (others => '0');
      h_pol <= '0';
      h_max <= (others => '0');
      v_ps <= (others => '0');
      v_pe <= (others => '0');
      v_pol <= '0';
      v_max <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (vga_state = VGA_LATCH) then
        frm_width <= USR_WIDTH_I;
        frm_height <= USR_HEIGHT_I;
        h_ps <= USR_HPS_I;
        h_pe <= USR_HPE_I;
        h_pol <= USR_HPOL_I;
        h_max <= USR_HMAX_I;
        v_ps <= USR_VPS_I;
        v_pe <= USR_VPE_I;
        v_pol <= USR_VPOL_I;
        v_max <= USR_VMAX_I;
      end if;
    end if;
  end process;


------------------------------------------------------------------
------              PIXEL ADDRESS COUNTERS                 -------
------------------------------------------------------------------


  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      h_cntr_reg <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (vga_state = VGA_INIT) then
        h_cntr_reg <= (others =>'0'); --Note that the first frame starts on the first non-visible line
      elsif (vga_running = '1') then
        if (h_cntr_reg = h_max) then
          h_cntr_reg <= (others => '0');
        else
          h_cntr_reg <= h_cntr_reg + 1;
        end if;
      else
        h_cntr_reg <= (others =>'0');
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      v_cntr_reg <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (vga_state = VGA_INIT) then 
        v_cntr_reg <= frm_height; --Note that the first frame starts on the first non-visible line
      elsif (vga_running = '1') then
        if ((h_cntr_reg = h_max) and (v_cntr_reg = v_max))then
          v_cntr_reg <= (others => '0');
        elsif (h_cntr_reg = h_max) then
          v_cntr_reg <= v_cntr_reg + 1;
        else
          v_cntr_reg <= v_cntr_reg;
        end if;
      else
        v_cntr_reg <= (others =>'0');
      end if;
    end if;
  end process;

------------------------------------------------------------------
------               SYNC GENERATION                       -------
------------------------------------------------------------------


  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      h_sync_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if (vga_running = '1') then
        if ((h_cntr_reg >= h_ps) and (h_cntr_reg < h_pe)) then
          h_sync_reg <= h_pol;
        else
          h_sync_reg <= not(h_pol);
        end if;
      else
        h_sync_reg <= '0';
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      v_sync_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if (vga_running = '1') then
        if ((v_cntr_reg >= v_ps) and (v_cntr_reg < v_pe)) then
          v_sync_reg <= v_pol;
        else
          v_sync_reg <= not(v_pol);
        end if;
      else
        v_sync_reg <= '0';
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      v_sync_dly <= '0';
      h_sync_dly <= '0';
    elsif (rising_edge(pxl_clk)) then
      v_sync_dly <= v_sync_reg;
      h_sync_dly <= h_sync_reg;
    end if;
  end process;

  HSYNC_O <= h_sync_dly;
  VSYNC_O <= v_sync_dly;


--Signal a new frame to the VDMA at the end of the first non-visible line. This
--should allow plenty of time for the line buffer to fill before data is required.
  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      fsync_reg <= '0';
    elsif (rising_edge(pxl_clk)) then
      if ((v_cntr_reg = frm_height) and (h_cntr_reg = h_max)) then
        fsync_reg <= '1';
      else
        fsync_reg <= '0';
      end if;
    end if;
  end process;

  FSYNC_O <= fsync_reg; 

------------------------------------------------------------------
------                  DATA CAPTURE                       -------
------------------------------------------------------------------

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      video_dv <= '0';
    elsif (rising_edge(pxl_clk)) then
      if ((vga_running = '1') and (v_cntr_reg < frm_height) and (h_cntr_reg < frm_width)) then
        video_dv <= '1';
      else
        video_dv <= '0';
      end if;
    end if;
  end process;

  process (pxl_clk, locked)
  begin
    if (locked = '0') then
      red_reg <= (others => '0');
      green_reg <= (others => '0');
      blue_reg <= (others => '0');
    elsif (rising_edge(pxl_clk)) then
      if (video_dv = '1') then
        red_reg <= TDATA_I(23 downto 16);
        green_reg <= TDATA_I(15 downto 8);
        blue_reg <= TDATA_I(7 downto 0);
      else
        red_reg <= (others => '0');
        green_reg <= (others => '0');
        blue_reg <= (others => '0');
      end if;
    end if;
  end process;

  TREADY_O <= video_dv;

  RED_O <= red_reg(7 downto 3);
  GREEN_O <= green_reg(7 downto 2);
  BLUE_O <= blue_reg(7 downto 3);

end Behavioral;

