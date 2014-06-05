----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:48:42 11/22/2011 
-- Design Name: 
-- Module Name:    axi_hdmi_reg - Behavioral 
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

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity axi_hdmi_reg is
    generic(
        C_SLV_DWIDTH        : integer   := 32);
    port(
        DispResolution      : out std_logic_vector(31 downto 0);
        Bus2IP_Clk          : in  std_logic;
        Bus2IP_Resetn       : in  std_logic;
        Bus2IP_Data         : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        Bus2IP_BE           : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
        Bus2IP_RdCE         : in  std_logic_vector(1 downto 0);
        Bus2IP_WrCE         : in  std_logic_vector(1 downto 0);
        IP2Bus_Data         : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        IP2Bus_RdAck        : out std_logic;
        IP2Bus_WrAck        : out std_logic;
        IP2Bus_Error        : out std_logic);
end axi_hdmi_reg;

architecture Behavioral of axi_hdmi_reg is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal DISP_OUT_RESOLUTION  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
signal DISP_IN_RESOLUTION   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
signal slv_reg_write_sel    : std_logic_vector(1 downto 0);
signal slv_reg_read_sel     : std_logic_vector(1 downto 0);
signal slv_ip2bus_data      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
signal slv_read_ack         : std_logic;
signal slv_write_ack        : std_logic;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

    slv_reg_write_sel <= Bus2IP_WrCE(1 downto 0);
    slv_reg_read_sel  <= Bus2IP_RdCE(1 downto 0);
    slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1);
    slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1);
    DispResolution    <= DISP_OUT_RESOLUTION;

------------------------------------------------------------------------
-- Implement slave model software accessible registers
------------------------------------------------------------------------
    SLAVE_REG_WRITE_PROC: process(Bus2IP_Clk) is
    begin
        if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
            if Bus2IP_Resetn = '0' then
                DISP_OUT_RESOLUTION <= (others => '0');
                DISP_IN_RESOLUTION <= (others => '0');
            else
                case slv_reg_write_sel is
                    when "10" =>
                        for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                            if(Bus2IP_BE(byte_index) = '1') then
                                DISP_OUT_RESOLUTION(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
                            end if;
                        end loop;
                    when "01" =>
                        for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                            if(Bus2IP_BE(byte_index) = '1') then
                                DISP_IN_RESOLUTION(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
                            end if;
                        end loop;
                    when others => null;
                end case;
            end if;
        end if;
    end process SLAVE_REG_WRITE_PROC;
    
------------------------------------------------------------------------
-- implement slave model software accessible register read mux
------------------------------------------------------------------------
    SLAVE_REG_READ_PROC: process(slv_reg_read_sel, DISP_OUT_RESOLUTION, DISP_IN_RESOLUTION) is
    begin
        case slv_reg_read_sel is
            when "10" => slv_ip2bus_data <= DISP_OUT_RESOLUTION;
            when "01" => slv_ip2bus_data <= DISP_IN_RESOLUTION;
            when others => slv_ip2bus_data <= (others => '0');
        end case;
    end process SLAVE_REG_READ_PROC;
  
    IP2Bus_Data <= slv_ip2bus_data when slv_read_ack = '1' else (others => '0');
    IP2Bus_WrAck <= slv_write_ack;
    IP2Bus_RdAck <= slv_read_ack;
    IP2Bus_Error <= '0';

end Behavioral;

