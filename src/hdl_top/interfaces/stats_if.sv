//==============================================================================
// File       : rtl/interfaces/stats_if.sv
// Module     : stats_if
// Purpose    : MAC-domain event and APB-domain snapshot boundary
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

interface stats_if (
  input logic mac_clk,
  input logic apb_clk
);
  logic        rx_invalid_event;
  logic        rx_crc_event;
  logic        rx_oversize_event;
  logic        rx_unsupported_control_event;
  logic        pause_active;
  logic        pause_expired;
  logic        tx_error_event;
  logic        snapshot_request;
  logic        snapshot_acknowledge;
  logic [31:0] snapshot [12];

  modport mac_mp (
    input  mac_clk, apb_clk, snapshot_request,
    output rx_invalid_event, rx_crc_event, rx_oversize_event,
           rx_unsupported_control_event, pause_active, pause_expired,
           tx_error_event, snapshot_acknowledge, snapshot
  );

  modport apb_mp (
    input  mac_clk, apb_clk, rx_invalid_event, rx_crc_event, rx_oversize_event,
           rx_unsupported_control_event, pause_active, pause_expired,
           tx_error_event, snapshot_acknowledge, snapshot,
    output snapshot_request
  );

endinterface

`default_nettype wire