// ***************************************************************************
// ***************************************************************************
// Copyright 2011(c) Analog Devices, Inc.
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//    
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************
// Rejeesh.Kutty@Analog.com (c) Analog Devices Inc.
// ***************************************************************************
// ***************************************************************************
// Transmit HDMI, video dma data in

module cf_vdma (

  hdmi_fs_toggle,
  hdmi_raddr_g,

  vdma_clk,
  vdma_fs,
  vdma_fs_ret,
  vdma_valid,
  vdma_be,
  vdma_data,
  vdma_last,
  vdma_ready,
  vdma_wr,
  vdma_waddr,
  vdma_wdata,
  vdma_fs_ret_toggle,
  vdma_fs_waddr,
  vdma_tpm_oos,
  vdma_be_error,
  vdma_ovf,
  vdma_unf,

  debug_data,
  debug_trigger);

  input           hdmi_fs_toggle;
  input   [ 8:0]  hdmi_raddr_g;

  input           vdma_clk;
  output          vdma_fs;
  input           vdma_fs_ret;
  input           vdma_valid;
  input   [ 7:0]  vdma_be;
  input   [63:0]  vdma_data;
  input           vdma_last;
  output          vdma_ready;
  output          vdma_wr;
  output  [ 8:0]  vdma_waddr;
  output  [47:0]  vdma_wdata;
  output          vdma_fs_ret_toggle;
  output  [ 8:0]  vdma_fs_waddr;
  output          vdma_tpm_oos;
  output          vdma_be_error;
  output          vdma_ovf;
  output          vdma_unf;

  output  [63:0]  debug_data;
  output  [ 7:0]  debug_trigger;

  reg             vdma_fs_toggle_m1 = 'd0;
  reg             vdma_fs_toggle_m2 = 'd0;
  reg             vdma_fs_toggle_m3 = 'd0;
  reg             vdma_fs = 'd0;
  reg     [ 8:0]  vdma_fs_waddr = 'd0;
  reg             vdma_fs_ret_toggle = 'd0;
  reg             vdma_wr = 'd0;
  reg     [ 8:0]  vdma_waddr = 'd0;
  reg     [47:0]  vdma_wdata = 'd0;
  reg     [22:0]  vdma_tpm_data = 'd0;
  reg     [ 4:0]  vdma_tpm_mismatch_count = 'd0;
  reg             vdma_tpm_oos = 'd0;
  reg     [ 4:0]  vdma_be_count = 'd0;
  reg             vdma_be_error = 'd0;
  reg     [ 8:0]  vdma_raddr_g_m1 = 'd0;
  reg     [ 8:0]  vdma_raddr_g_m2 = 'd0;
  reg     [ 8:0]  vdma_raddr = 'd0;
  reg     [ 8:0]  vdma_addr_diff = 'd0;
  reg             vdma_ready = 'd0;
  reg             vdma_almost_full = 'd0;
  reg             vdma_almost_empty = 'd0;
  reg     [ 4:0]  vdma_ovf_count = 'd0;
  reg             vdma_ovf = 'd0;
  reg     [ 4:0]  vdma_unf_count = 'd0;
  reg             vdma_unf = 'd0;

  wire    [47:0]  vdma_tpm_data_s;
  wire            vdma_tpm_mismatch_s;
  wire            vdma_be_error_s;
  wire    [ 9:0]  vdma_addr_diff_s;
  wire            vdma_ovf_s;
  wire            vdma_unf_s;

  // grey to binary conversion

  function [8:0] g2b;
    input [8:0] g;
    reg   [8:0] b;
    begin
      b[8] = g[8];
      b[7] = b[8] ^ g[7];
      b[6] = b[7] ^ g[6];
      b[5] = b[6] ^ g[5];
      b[4] = b[5] ^ g[4];
      b[3] = b[4] ^ g[3];
      b[2] = b[3] ^ g[2];
      b[1] = b[2] ^ g[1];
      b[0] = b[1] ^ g[0];
      g2b = b;
    end
  endfunction

  // debug ports

  assign debug_data[63:61] = 'd0;
  assign debug_data[60:60] = vdma_tpm_oos;
  assign debug_data[59:59] = vdma_tpm_mismatch_s;
  assign debug_data[58:58] = vdma_wr;
  assign debug_data[57:57] = vdma_ovf_s;
  assign debug_data[56:56] = vdma_unf_s;
  assign debug_data[55:55] = vdma_almost_full;
  assign debug_data[54:54] = vdma_almost_empty;
  assign debug_data[53:53] = vdma_fs;
  assign debug_data[52:52] = vdma_fs_ret;
  assign debug_data[51:51] = vdma_valid;
  assign debug_data[50:50] = vdma_ready;
  assign debug_data[49:49] = vdma_last;
  assign debug_data[48:48] = vdma_be_error_s;
  assign debug_data[47: 0] = {vdma_data[55:32], vdma_data[23:0]};

  assign debug_trigger[7] = vdma_tpm_mismatch_s;
  assign debug_trigger[6] = vdma_be_error_s;
  assign debug_trigger[5] = vdma_ovf_s;
  assign debug_trigger[4] = vdma_unf_s;
  assign debug_trigger[3] = vdma_fs;
  assign debug_trigger[2] = vdma_fs_ret;
  assign debug_trigger[1] = vdma_be_error;
  assign debug_trigger[0] = vdma_ready;

  // get fs from hdmi side, return fs and sof write address back

  always @(posedge vdma_clk) begin
    vdma_fs_toggle_m1 <= hdmi_fs_toggle;
    vdma_fs_toggle_m2 <= vdma_fs_toggle_m1;
    vdma_fs_toggle_m3 <= vdma_fs_toggle_m2;
    vdma_fs <= vdma_fs_toggle_m2 ^ vdma_fs_toggle_m3;
    if (vdma_fs_ret == 1'b1) begin
      vdma_fs_waddr <= vdma_waddr;
      vdma_fs_ret_toggle <= ~vdma_fs_ret_toggle;
    end
  end

  // vdma write

  always @(posedge vdma_clk) begin
    vdma_wr <= vdma_valid & vdma_ready;
    if (vdma_wr == 1'b1) begin
      vdma_waddr <= vdma_waddr + 1'b1;
    end
    vdma_wdata <= {vdma_data[55:32], vdma_data[23:0]};
  end

  // test error conditions

  assign vdma_tpm_data_s = {vdma_tpm_data, 1'b1, vdma_tpm_data, 1'b0};
  assign vdma_tpm_mismatch_s = (vdma_wdata == vdma_tpm_data_s) ? 1'b0 : vdma_wr;
  assign vdma_be_error_s = (vdma_be == 8'hff) ? 1'b0 : (vdma_valid & vdma_ready);

  always @(posedge vdma_clk) begin
    if (vdma_fs_ret == 1'b1) begin
      vdma_tpm_data <= 23'd0;
    end else if (vdma_wr == 1'b1) begin
      vdma_tpm_data <= vdma_tpm_data + 1'b1;
    end
    if (vdma_tpm_mismatch_s == 1'b1) begin
      vdma_tpm_mismatch_count <= 5'h10;
    end else if (vdma_tpm_mismatch_count[4] == 1'b1) begin
      vdma_tpm_mismatch_count <= vdma_tpm_mismatch_count + 1'b1;
    end
    vdma_tpm_oos <= vdma_tpm_mismatch_count[4];
    if (vdma_be_error_s == 1'b1) begin
      vdma_be_count <= 5'h10;
    end else if (vdma_be_count[4] == 1'b1) begin
      vdma_be_count <= vdma_be_count + 1'b1;
    end
    vdma_be_error <= vdma_be_count[4];
  end

  // overflow or underflow status

  assign vdma_addr_diff_s = {1'b1, vdma_waddr} - vdma_raddr;
  assign vdma_ovf_s = (vdma_addr_diff < 3) ? vdma_almost_full : 1'b0;
  assign vdma_unf_s = (vdma_addr_diff > 509) ? vdma_almost_empty : 1'b0;

  always @(posedge vdma_clk) begin
    vdma_raddr_g_m1 <= hdmi_raddr_g;
    vdma_raddr_g_m2 <= vdma_raddr_g_m1;
    vdma_raddr <= g2b(vdma_raddr_g_m2);
    vdma_addr_diff <= vdma_addr_diff_s[8:0];
    if (vdma_addr_diff >= 500) begin
      vdma_ready <= 1'b0;
    end else if (vdma_addr_diff <= 450) begin
      vdma_ready <= 1'b1;
    end
    vdma_almost_full = (vdma_addr_diff > 509) ? 1'b1 : 1'b0;
    vdma_almost_empty = (vdma_addr_diff < 3) ? 1'b1 : 1'b0;
    if (vdma_ovf_s == 1'b1) begin
      vdma_ovf_count <= 5'h10;
    end else if (vdma_ovf_count[4] == 1'b1) begin
      vdma_ovf_count <= vdma_ovf_count + 1'b1;
    end
    vdma_ovf <= vdma_ovf_count[4];
    if (vdma_unf_s == 1'b1) begin
      vdma_unf_count <= 5'h10;
    end else if (vdma_unf_count[4] == 1'b1) begin
      vdma_unf_count <= vdma_unf_count + 1'b1;
    end
    vdma_unf <= vdma_unf_count[4];
  end

endmodule

// ***************************************************************************
// ***************************************************************************
