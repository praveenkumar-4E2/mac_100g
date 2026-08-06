//==============================================================================
// File       : rtl/eth_pkg.sv
// Module     : eth_pkg
// Purpose    : Ethernet Length/Type assignments used by MAC classification
// IEEE Ref   : IEEE 802.3 Clause 3.2.6
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

// Package: eth_pkg
// Purpose  : Ethernet Length/Type assignments used by MAC classification
// IEEE Ref : IEEE 802.3 Clause 3.2.6
package eth_pkg;

  /* verilator lint_off UNUSEDPARAM */

  localparam logic [15:0] ETHERTYPE_IPV4         = 16'h0800;
  localparam logic [15:0] ETHERTYPE_ARP          = 16'h0806;
  localparam logic [15:0] ETHERTYPE_VLAN         = 16'h8100;
  localparam logic [15:0] ETHERTYPE_IPV6         = 16'h86DD;
  localparam logic [15:0] ETHERTYPE_MAC_CONTROL  = 16'h8808;
  localparam logic [15:0] ETHERTYPE_QINQ         = 16'h88A8;
  localparam logic [15:0] ETH_LENGTH_MAX         = 16'd1500;
  localparam logic [15:0] ETH_TYPE_MIN           = 16'd1536;

  /* verilator lint_on UNUSEDPARAM */

endpackage

`default_nettype wire