//==============================================================================
// File       : rtl/interfaces/ctrl_if.sv
// Module     : ctrl_if
// Purpose    : Configuration and control-event boundary between APB and MAC
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

interface ctrl_if #(
  parameter int unsigned GROUP_COUNT = 4
) (
  input logic mac_clk,
  input logic apb_clk
);
  logic [31:0]                  ctrl;
  logic [47:0]                  mac_addr;
  logic [15:0]                  max_client_data;
  logic [GROUP_COUNT-1:0][47:0] group_addr;
  logic [GROUP_COUNT-1:0]       group_valid;
  logic                         update;

  modport mac_mp (
    input  mac_clk, apb_clk,
    output ctrl, mac_addr, max_client_data, group_addr, group_valid, update
  );

  modport apb_mp (
    input  mac_clk, apb_clk,
    input ctrl, mac_addr, max_client_data, group_addr, group_valid, update
  );

endinterface

`default_nettype wire