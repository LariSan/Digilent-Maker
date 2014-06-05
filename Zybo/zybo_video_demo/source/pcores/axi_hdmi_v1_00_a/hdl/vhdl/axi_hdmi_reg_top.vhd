----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:45:30 11/22/2011 
-- Design Name: 
-- Module Name:    axi_hdmi_reg_top - Behavioral 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library axi_lite_ipif_v1_01_a;
use axi_lite_ipif_v1_01_a.axi_lite_ipif;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity axi_hdmi_reg_top is
    generic
    (
        C_S_AXI_DATA_WIDTH             : integer              := 32;
        C_S_AXI_ADDR_WIDTH             : integer              := 32;
        C_S_AXI_MIN_SIZE               : std_logic_vector     := X"000001FF";
        C_USE_WSTRB                    : integer              := 0;
        C_DPHASE_TIMEOUT               : integer              := 8;
        C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
        C_HIGHADDR                     : std_logic_vector     := X"00000000";
        C_FAMILY                       : string               := "virtex6";
        C_NUM_REG                      : integer              := 1;
        C_NUM_MEM                      : integer              := 1;
        C_SLV_AWIDTH                   : integer              := 32;
        C_SLV_DWIDTH                   : integer              := 32
    );
    port
    (
        DispResolution                 : out std_logic_vector(31 downto 0);
        S_AXI_ACLK                     : in  std_logic;
        S_AXI_ARESETN                  : in  std_logic;
        S_AXI_AWADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID                  : in  std_logic;
        S_AXI_WDATA                    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB                    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID                   : in  std_logic;
        S_AXI_BREADY                   : in  std_logic;
        S_AXI_ARADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID                  : in  std_logic;
        S_AXI_RREADY                   : in  std_logic;
        S_AXI_ARREADY                  : out std_logic;
        S_AXI_RDATA                    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP                    : out std_logic_vector(1 downto 0);
        S_AXI_RVALID                   : out std_logic;
        S_AXI_WREADY                   : out std_logic;
        S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
        S_AXI_BVALID                   : out std_logic;
        S_AXI_AWREADY                  : out std_logic
    );
    attribute MAX_FANOUT                  : string;
    attribute SIGIS                       : string;
    attribute MAX_FANOUT of S_AXI_ACLK    : signal is "10000";
    attribute MAX_FANOUT of S_AXI_ARESETN : signal is "10000";
    attribute SIGIS of S_AXI_ACLK         : signal is "Clk";
    attribute SIGIS of S_AXI_ARESETN      : signal is "Rst";
end axi_hdmi_reg_top;

architecture Behavioral of axi_hdmi_reg_top is

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------

constant USER_SLV_DWIDTH                : integer              := C_S_AXI_DATA_WIDTH;
constant IPIF_SLV_DWIDTH                : integer              := C_S_AXI_DATA_WIDTH;
constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');
constant USER_SLV_BASEADDR              : std_logic_vector     := C_BASEADDR;
constant USER_SLV_HIGHADDR              : std_logic_vector     := C_HIGHADDR;
constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
  (
    ZERO_ADDR_PAD & USER_SLV_BASEADDR,  -- user logic slave space base address
    ZERO_ADDR_PAD & USER_SLV_HIGHADDR   -- user logic slave space high address
  );
constant USER_SLV_NUM_REG               : integer              := 2;
constant USER_NUM_REG                   : integer              := USER_SLV_NUM_REG;
constant TOTAL_IPIF_CE                  : integer              := USER_NUM_REG;
constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
  (
    0  => (USER_SLV_NUM_REG)            -- number of ce for user logic slave space
  );
constant USER_SLV_CS_INDEX              : integer              := 0;
constant USER_SLV_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_SLV_CS_INDEX);
constant USER_CE_INDEX                  : integer              := USER_SLV_CE_INDEX;

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal ipif_Bus2IP_Clk                : std_logic;
signal ipif_Bus2IP_Resetn             : std_logic;
signal ipif_Bus2IP_Addr               : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
signal ipif_Bus2IP_RNW                : std_logic;
signal ipif_Bus2IP_BE                 : std_logic_vector(IPIF_SLV_DWIDTH/8-1 downto 0);
signal ipif_Bus2IP_CS                 : std_logic_vector((IPIF_ARD_ADDR_RANGE_ARRAY'LENGTH)/2-1 downto 0);
signal ipif_Bus2IP_RdCE               : std_logic_vector(calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1 downto 0);
signal ipif_Bus2IP_WrCE               : std_logic_vector(calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1 downto 0);
signal ipif_Bus2IP_Data               : std_logic_vector(IPIF_SLV_DWIDTH-1 downto 0);
signal ipif_IP2Bus_WrAck              : std_logic;
signal ipif_IP2Bus_RdAck              : std_logic;
signal ipif_IP2Bus_Error              : std_logic;
signal ipif_IP2Bus_Data               : std_logic_vector(IPIF_SLV_DWIDTH-1 downto 0);
signal user_Bus2IP_RdCE               : std_logic_vector(USER_NUM_REG-1 downto 0);
signal user_Bus2IP_WrCE               : std_logic_vector(USER_NUM_REG-1 downto 0);
signal user_IP2Bus_Data               : std_logic_vector(USER_SLV_DWIDTH-1 downto 0);
signal user_IP2Bus_RdAck              : std_logic;
signal user_IP2Bus_WrAck              : std_logic;
signal user_IP2Bus_Error              : std_logic;

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

component axi_hdmi_reg
    generic(
        C_SLV_DWIDTH            : integer   := 32);
    port(
        DispResolution          : out std_logic_vector(31 downto 0);
        Bus2IP_Clk              : in  std_logic;
        Bus2IP_Resetn           : in  std_logic;
        Bus2IP_Data             : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        Bus2IP_BE               : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
        Bus2IP_RdCE             : in  std_logic_vector(1 downto 0);
        Bus2IP_WrCE             : in  std_logic_vector(1 downto 0);
        IP2Bus_Data             : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        IP2Bus_RdAck            : out std_logic;
        IP2Bus_WrAck            : out std_logic;
        IP2Bus_Error            : out std_logic);
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Instantiate axi_lite_ipif
------------------------------------------------------------------------
    AXI_LITE_IPIF_I : entity axi_lite_ipif_v1_01_a.axi_lite_ipif
    generic map
    (
        C_S_AXI_DATA_WIDTH             => IPIF_SLV_DWIDTH,
        C_S_AXI_ADDR_WIDTH             => C_S_AXI_ADDR_WIDTH,
        C_S_AXI_MIN_SIZE               => C_S_AXI_MIN_SIZE,
        C_USE_WSTRB                    => C_USE_WSTRB,
        C_DPHASE_TIMEOUT               => C_DPHASE_TIMEOUT,
        C_ARD_ADDR_RANGE_ARRAY         => IPIF_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY             => IPIF_ARD_NUM_CE_ARRAY,
        C_FAMILY                       => C_FAMILY
    )
    port map
    (
        S_AXI_ACLK                     => S_AXI_ACLK,
        S_AXI_ARESETN                  => S_AXI_ARESETN,
        S_AXI_AWADDR                   => S_AXI_AWADDR,
        S_AXI_AWVALID                  => S_AXI_AWVALID,
        S_AXI_WDATA                    => S_AXI_WDATA,
        S_AXI_WSTRB                    => S_AXI_WSTRB,
        S_AXI_WVALID                   => S_AXI_WVALID,
        S_AXI_BREADY                   => S_AXI_BREADY,
        S_AXI_ARADDR                   => S_AXI_ARADDR,
        S_AXI_ARVALID                  => S_AXI_ARVALID,
        S_AXI_RREADY                   => S_AXI_RREADY,
        S_AXI_ARREADY                  => S_AXI_ARREADY,
        S_AXI_RDATA                    => S_AXI_RDATA,
        S_AXI_RRESP                    => S_AXI_RRESP,
        S_AXI_RVALID                   => S_AXI_RVALID,
        S_AXI_WREADY                   => S_AXI_WREADY,
        S_AXI_BRESP                    => S_AXI_BRESP,
        S_AXI_BVALID                   => S_AXI_BVALID,
        S_AXI_AWREADY                  => S_AXI_AWREADY,
        Bus2IP_Clk                     => ipif_Bus2IP_Clk,
        Bus2IP_Resetn                  => ipif_Bus2IP_Resetn,
        Bus2IP_Addr                    => ipif_Bus2IP_Addr,
        Bus2IP_RNW                     => ipif_Bus2IP_RNW,
        Bus2IP_BE                      => ipif_Bus2IP_BE,
        Bus2IP_CS                      => ipif_Bus2IP_CS,
        Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
        Bus2IP_WrCE                    => ipif_Bus2IP_WrCE,
        Bus2IP_Data                    => ipif_Bus2IP_Data,
        IP2Bus_WrAck                   => ipif_IP2Bus_WrAck,
        IP2Bus_RdAck                   => ipif_IP2Bus_RdAck,
        IP2Bus_Error                   => ipif_IP2Bus_Error,
        IP2Bus_Data                    => ipif_IP2Bus_Data
    );

------------------------------------------------------------------------
-- Instantiate axi_hdmi_reg
------------------------------------------------------------------------
    Inst_AxiHDMIReg: axi_hdmi_reg
    generic map(
        C_SLV_DWIDTH            => USER_SLV_DWIDTH)
    port map(
        DispResolution          => DispResolution,
        Bus2IP_Clk              => ipif_Bus2IP_Clk,
        Bus2IP_Resetn           => ipif_Bus2IP_Resetn,
        Bus2IP_Data             => ipif_Bus2IP_Data,
        Bus2IP_BE               => ipif_Bus2IP_BE,
        Bus2IP_RdCE             => user_Bus2IP_RdCE,
        Bus2IP_WrCE             => user_Bus2IP_WrCE,
        IP2Bus_Data             => user_IP2Bus_Data,
        IP2Bus_RdAck            => user_IP2Bus_RdAck,
        IP2Bus_WrAck            => user_IP2Bus_WrAck,
        IP2Bus_Error            => user_IP2Bus_Error);
    
    ipif_IP2Bus_Data <= user_IP2Bus_Data;
    ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
    ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
    ipif_IP2Bus_Error <= user_IP2Bus_Error;

    user_Bus2IP_RdCE <= ipif_Bus2IP_RdCE(USER_NUM_REG-1 downto 0);
    user_Bus2IP_WrCE <= ipif_Bus2IP_WrCE(USER_NUM_REG-1 downto 0);

end Behavioral;

