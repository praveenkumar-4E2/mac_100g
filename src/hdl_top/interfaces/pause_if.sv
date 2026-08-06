//==============================================================================
// File       : rtl/interfaces/pause_if.sv
// Module     : pause_if
// Purpose    : PAUSE event and TX admission contract
// IEEE Ref   : IEEE 802.3 Annex 31B.3.4 and 802.3ba Annex 31B.3.7
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

interface pause_if (
  input logic mac_clk
);
  logic        pause_event_valid;
  logic [47:0] pause_dest_addr;
  logic [15:0] pause_time;
  logic        transmission_in_progress;
  logic        data_admit;
  logic        control_admit;
  logic        paused;
  logic        timer_done;
  logic        event_accepted;

  modport pause_rx_mp (
    input  mac_clk, pause_event_valid, pause_dest_addr, pause_time,
           transmission_in_progress,
    output data_admit, control_admit, paused, timer_done, event_accepted
  );

  modport pause_status_mp (
    input  mac_clk, data_admit, control_admit, paused, timer_done,
           event_accepted,
    output pause_event_valid, pause_dest_addr, pause_time,
           transmission_in_progress
  );

endinterface

`default_nettype wire