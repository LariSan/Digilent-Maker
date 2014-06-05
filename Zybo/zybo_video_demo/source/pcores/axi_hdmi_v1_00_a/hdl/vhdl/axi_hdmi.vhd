-------------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2011, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME            : axi_dvi_transmitter.vhd
-- MODULE NAME          : AXI DVI Transmitter
-- AUTHOR               : Mihaita Nagy
-- AUTHOR'S EMAIL       : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0 	    2011-10-12   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : DVI, HDMI, DDC, TMDS, AXI4-Stream
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity axi_hdmi is
	generic(
        -- Global parameters
        C_USE_HDMI_RECEIVER     : integer           := 1;
        C_USE_HDMI_TRANSMITTER  : integer           := 1;
        C_USE_HDMI_REGS         : integer           := 1;
        C_USE_HDMI_DDC          : integer           := 1;
        C_USE_MM2S_DATA_ALIGN   : integer           := 0;
        C_USE_S2MM_DATA_ALIGN   : integer           := 0;
        
        -- AXI4-Stream parameter
        C_AXI_STREAM_DATA_WIDTH : integer           := 32;
        
        -- AXI4-Lite Channel parameters
        C_BASEADDR              : std_logic_vector  := X"FFFFFFFF";
        C_HIGHADDR              : std_logic_vector  := X"00000000"
    );
	port(        
        -- Other Signals
        ACLK                    : in    std_logic;
        MM2S_FSYNC_IN           : in    std_logic;
        MM2S_BUFFER_ALMOST_EMPTY: in    std_logic;
        S2MM_FSYNC_IN           : in    std_logic;
        
        -- AXI4-Lite Channel
        S_AXI_ACLK              : in    std_logic;
        S_AXI_ARESETN           : in    std_logic;
        S_AXI_AWADDR            : in    std_logic_vector(31 downto 0);
        S_AXI_AWVALID           : in    std_logic;
        S_AXI_WDATA             : in    std_logic_vector(31 downto 0);
        S_AXI_WSTRB             : in    std_logic_vector(3 downto 0);
        S_AXI_WVALID            : in    std_logic;
        S_AXI_BREADY            : in    std_logic;
        S_AXI_ARADDR            : in    std_logic_vector(31 downto 0);
        S_AXI_ARVALID           : in    std_logic;
        S_AXI_RREADY            : in    std_logic;
        S_AXI_ARREADY           : out   std_logic;
        S_AXI_RDATA             : out   std_logic_vector(31 downto 0);
        S_AXI_RRESP             : out   std_logic_vector(1 downto 0);
        S_AXI_RVALID            : out   std_logic;
        S_AXI_WREADY            : out   std_logic;
        S_AXI_BRESP             : out   std_logic_vector(1 downto 0);
        S_AXI_BVALID            : out   std_logic;
        S_AXI_AWREADY           : out   std_logic;
        
        -- AXI4-Stream Read Channel
        S_AXIS_MM2S_ACLK        : out   std_logic;
		S_AXIS_MM2S_ARESETN     : in    std_logic;
		S_AXIS_MM2S_TREADY      : out   std_logic;
		S_AXIS_MM2S_TDATA       : in    std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        S_AXIS_MM2S_TKEEP       : in    std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		S_AXIS_MM2S_TLAST       : in    std_logic;
		S_AXIS_MM2S_TVALID      : in    std_logic;
        
        -- AXI4-Stream Write Channel
        M_AXIS_S2MM_ACLK        : out   std_logic;
		M_AXIS_S2MM_ARESETN     : in    std_logic;
		M_AXIS_S2MM_TVALID      : out   std_logic;
		M_AXIS_S2MM_TDATA       : out   std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        M_AXIS_S2MM_TKEEP       : out   std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		M_AXIS_S2MM_TLAST       : out   std_logic;
		M_AXIS_S2MM_TREADY      : in    std_logic;
        
        -- DVI IN Signals
        TMDS_RX_CLK_P           : in    std_logic;
        TMDS_RX_CLK_N           : in    std_logic;
        TMDS_RX_2_P             : in    std_logic;
        TMDS_RX_2_N             : in    std_logic;
        TMDS_RX_1_P             : in    std_logic;
        TMDS_RX_1_N             : in    std_logic;
        TMDS_RX_0_P             : in    std_logic;
        TMDS_RX_0_N             : in    std_logic;
        TMDS_RX_SCL             : in    std_logic;
        TMDS_RX_SDA_I           : in    std_logic;
        TMDS_RX_SDA_T           : out   std_logic;
        TMDS_RX_SDA_O           : out   std_logic;
        
        -- DVI OUT Signals
        TMDS_TX_CLK_P           : out   std_logic;
        TMDS_TX_CLK_N           : out   std_logic;
        TMDS_TX_2_P             : out   std_logic;
        TMDS_TX_2_N             : out   std_logic;
        TMDS_TX_1_P             : out   std_logic;
        TMDS_TX_1_N             : out   std_logic;
        TMDS_TX_0_P             : out   std_logic;
        TMDS_TX_0_N             : out   std_logic
    );
end axi_hdmi;

architecture Behavioral of axi_hdmi is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

-- Display resolution
signal DispRes : std_logic_vector(31 downto 0);

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
component axi_hdmi_transmitter
    generic(
        C_USE_MM2S_DATA_ALIGN   : integer := 0;
        C_AXI_STREAM_DATA_WIDTH : integer := 32);
    port(
        MM2S_FSYNC_IN           : in    std_logic;
        MM2S_BUFFER_ALMOST_EMPTY: in    std_logic;
        DISP_RES                : in    std_logic_vector(31 downto 0);
        ACLK                    : in    std_logic;
        ARESETN                 : in    std_logic;
        M_AXIS_MM2S_ACLK        : out   std_logic;
        M_AXIS_MM2S_TREADY      : out   std_logic;
        M_AXIS_MM2S_TDATA       : in    std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        M_AXIS_MM2S_TKEEP       : in    std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
        M_AXIS_MM2S_TLAST       : in    std_logic;
        M_AXIS_MM2S_TVALID      : in    std_logic;
        TMDS_TX_CLK_P           : out   std_logic;
        TMDS_TX_CLK_N           : out   std_logic;
        TMDS_TX_2_P             : out   std_logic;
        TMDS_TX_2_N             : out   std_logic;
        TMDS_TX_1_P             : out   std_logic;
        TMDS_TX_1_N             : out   std_logic;
        TMDS_TX_0_P             : out   std_logic;
        TMDS_TX_0_N             : out   std_logic);
end component;

component axi_hdmi_receiver
    generic(
        C_USE_S2MM_DATA_ALIGN   : integer := 0;
        C_AXI_STREAM_DATA_WIDTH : integer := 32);
    port(
        ACLK_I                  : in    std_logic;
        S2MM_FSYNC_IN           : in    std_logic;
        M_AXIS_S2MM_ACLK        : out   std_logic;
		M_AXIS_S2MM_ARESETN     : in    std_logic;
		M_AXIS_S2MM_TVALID      : out   std_logic;
		M_AXIS_S2MM_TDATA       : out   std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
        M_AXIS_S2MM_TKEEP       : out   std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		M_AXIS_S2MM_TLAST       : out   std_logic;
		M_AXIS_S2MM_TREADY      : in    std_logic;
        TMDS_RX_CLK_P           : in    std_logic;
        TMDS_RX_CLK_N           : in    std_logic;
        TMDS_RX_2_P             : in    std_logic;
        TMDS_RX_2_N             : in    std_logic;
        TMDS_RX_1_P             : in    std_logic;
        TMDS_RX_1_N             : in    std_logic;
        TMDS_RX_0_P             : in    std_logic;
        TMDS_RX_0_N             : in    std_logic);
end component;

component axi_hdmi_reg_top
    generic(
        C_S_AXI_DATA_WIDTH      : integer           := 32;
        C_S_AXI_ADDR_WIDTH      : integer           := 32;
        C_S_AXI_MIN_SIZE        : std_logic_vector  := X"000001FF";
        C_USE_WSTRB             : integer           := 0;
        C_DPHASE_TIMEOUT        : integer           := 8;
        C_BASEADDR              : std_logic_vector  := X"FFFFFFFF";
        C_HIGHADDR              : std_logic_vector  := X"00000000";
        C_FAMILY                : string            := "virtex6";
        C_NUM_REG               : integer           := 1;
        C_NUM_MEM               : integer           := 1;
        C_SLV_AWIDTH            : integer           := 32;
        C_SLV_DWIDTH            : integer           := 32);
    port(
        DispResolution          : out std_logic_vector(31 downto 0);
        S_AXI_ACLK              : in  std_logic;
        S_AXI_ARESETN           : in  std_logic;
        S_AXI_AWADDR            : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID           : in  std_logic;
        S_AXI_WDATA             : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB             : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID            : in  std_logic;
        S_AXI_BREADY            : in  std_logic;
        S_AXI_ARADDR            : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID           : in  std_logic;
        S_AXI_RREADY            : in  std_logic;
        S_AXI_ARREADY           : out std_logic;
        S_AXI_RDATA             : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP             : out std_logic_vector(1 downto 0);
        S_AXI_RVALID            : out std_logic;
        S_AXI_WREADY            : out std_logic;
        S_AXI_BRESP             : out std_logic_vector(1 downto 0);
        S_AXI_BVALID            : out std_logic;
        S_AXI_AWREADY           : out std_logic);
end component;

component hdmi_ddc
    port(
        CLK_I                   : in  std_logic;
        RSTN_I                  : in  std_logic;
        EN_I                    : in  std_logic;
        SCL_I                   : in  std_logic;
        SDA_I                   : in  std_logic;
        SDA_T                   : out std_logic;
        SDA_O                   : out std_logic);
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin
    
------------------------------------------------------------------------
-- Instantiate the AXI DVI Transmitter module
------------------------------------------------------------------------
    USE_HDMI_OUT: if C_USE_HDMI_TRANSMITTER = 1 generate
    Inst_AxiHDMITransmitter: axi_hdmi_transmitter
    generic map(
        C_USE_MM2S_DATA_ALIGN   => C_USE_MM2S_DATA_ALIGN,
        C_AXI_STREAM_DATA_WIDTH => C_AXI_STREAM_DATA_WIDTH)
    port map(
        MM2S_FSYNC_IN           => MM2S_FSYNC_IN,
        MM2S_BUFFER_ALMOST_EMPTY=> MM2S_BUFFER_ALMOST_EMPTY,
        DISP_RES                => DispRes,
        ACLK                    => ACLK,
        ARESETN                 => S_AXIS_MM2S_ARESETN,
        M_AXIS_MM2S_ACLK        => S_AXIS_MM2S_ACLK,
        M_AXIS_MM2S_TREADY      => S_AXIS_MM2S_TREADY,
        M_AXIS_MM2S_TDATA       => S_AXIS_MM2S_TDATA,
        M_AXIS_MM2S_TKEEP       => S_AXIS_MM2S_TKEEP,
        M_AXIS_MM2S_TLAST       => S_AXIS_MM2S_TLAST,
        M_AXIS_MM2S_TVALID      => S_AXIS_MM2S_TVALID,
        TMDS_TX_CLK_P           => TMDS_TX_CLK_P,
        TMDS_TX_CLK_N           => TMDS_TX_CLK_N,
        TMDS_TX_2_P             => TMDS_TX_2_P,
        TMDS_TX_2_N             => TMDS_TX_2_N,
        TMDS_TX_1_P             => TMDS_TX_1_P,
        TMDS_TX_1_N             => TMDS_TX_1_N,
        TMDS_TX_0_P             => TMDS_TX_0_P,
        TMDS_TX_0_N             => TMDS_TX_0_N);
    end generate;
    
------------------------------------------------------------------------
-- Instantiate the AXI DVI Receiver module
------------------------------------------------------------------------
    USE_HDMI_IN: if C_USE_HDMI_RECEIVER = 1 generate
    Inst_AxiHDMIReceiver: axi_hdmi_receiver
    generic map(
        C_USE_S2MM_DATA_ALIGN   => C_USE_S2MM_DATA_ALIGN,
        C_AXI_STREAM_DATA_WIDTH => C_AXI_STREAM_DATA_WIDTH)
    port map(
        ACLK_I                  => ACLK,
        S2MM_FSYNC_IN           => S2MM_FSYNC_IN,
        M_AXIS_S2MM_ACLK        => M_AXIS_S2MM_ACLK,
		M_AXIS_S2MM_ARESETN     => M_AXIS_S2MM_ARESETN,
		M_AXIS_S2MM_TVALID      => M_AXIS_S2MM_TVALID,
		M_AXIS_S2MM_TDATA       => M_AXIS_S2MM_TDATA,
		M_AXIS_S2MM_TLAST       => M_AXIS_S2MM_TLAST,
		M_AXIS_S2MM_TREADY      => M_AXIS_S2MM_TREADY,
        M_AXIS_S2MM_TKEEP       => M_AXIS_S2MM_TKEEP,
        TMDS_RX_CLK_P           => TMDS_RX_CLK_P,
        TMDS_RX_CLK_N           => TMDS_RX_CLK_N,
        TMDS_RX_2_P             => TMDS_RX_2_P,
        TMDS_RX_2_N             => TMDS_RX_2_N,
        TMDS_RX_1_P             => TMDS_RX_1_P,
        TMDS_RX_1_N             => TMDS_RX_1_N,
        TMDS_RX_0_P             => TMDS_RX_0_P,
        TMDS_RX_0_N             => TMDS_RX_0_N);
    end generate;
    
------------------------------------------------------------------------
-- Instantiate the AXI DVI Register module
------------------------------------------------------------------------
    USE_HDMI_REGS: if C_USE_HDMI_REGS = 1 generate
    Inst_AxiHDMISoftReg: axi_hdmi_reg_top
    generic map(
        C_S_AXI_DATA_WIDTH      => 32,
        C_S_AXI_ADDR_WIDTH      => 32,
        C_S_AXI_MIN_SIZE        => x"000001FF",
        C_USE_WSTRB             => 0,
        C_DPHASE_TIMEOUT        => 8,
        C_BASEADDR              => C_BASEADDR,
        C_HIGHADDR              => C_HIGHADDR,
        C_FAMILY                => "virtex6",
        C_NUM_REG               => 1,
        C_NUM_MEM               => 1,
        C_SLV_AWIDTH            => 32,
        C_SLV_DWIDTH            => 32)
    port map(
        DispResolution          => DispRes,
        S_AXI_ACLK              => S_AXI_ACLK,
        S_AXI_ARESETN           => S_AXI_ARESETN,
        S_AXI_AWADDR            => S_AXI_AWADDR,
        S_AXI_AWVALID           => S_AXI_AWVALID,
        S_AXI_WDATA             => S_AXI_WDATA,
        S_AXI_WSTRB             => S_AXI_WSTRB,
        S_AXI_WVALID            => S_AXI_WVALID,
        S_AXI_BREADY            => S_AXI_BREADY,
        S_AXI_ARADDR            => S_AXI_ARADDR,
        S_AXI_ARVALID           => S_AXI_ARVALID,
        S_AXI_RREADY            => S_AXI_RREADY,
        S_AXI_ARREADY           => S_AXI_ARREADY,
        S_AXI_RDATA             => S_AXI_RDATA,
        S_AXI_RRESP             => S_AXI_RRESP,
        S_AXI_RVALID            => S_AXI_RVALID,
        S_AXI_WREADY            => S_AXI_WREADY,
        S_AXI_BRESP             => S_AXI_BRESP,
        S_AXI_BVALID            => S_AXI_BVALID,
        S_AXI_AWREADY           => S_AXI_AWREADY);
    end generate;

------------------------------------------------------------------------
-- Instantiate the DVI DDC2B module
------------------------------------------------------------------------    
    USE_HDMI_DDC: if C_USE_HDMI_DDC = 1 generate
    Inst_AxiHDMIDdc: hdmi_ddc
    port map(
        CLK_I                   => ACLK,
        RSTN_I                  => M_AXIS_S2MM_ARESETN,
        EN_I                    => '1',
        SCL_I                   => TMDS_RX_SCL,
        SDA_I                   => TMDS_RX_SDA_I,
        SDA_T                   => TMDS_RX_SDA_T,
        SDA_O                   => TMDS_RX_SDA_O);
    end generate;
    
end architecture Behavioral;
