//==============================================================================
// File       : rtl/interfaces/mac_if.sv
// Module     : mac_if
// Purpose    : 512-bit beat MAC client stream contract. Frames are lane-0
//              aligned: sop asserts on the beat carrying the first byte, keep
//              marks valid byte lanes, and the frame-ending beat carries eop
//              with eop_pos valid bytes (keep = (1<<eop_pos)-1).
// IEEE Ref   : IEEE 802.3 Clause 2 MA_DATA request/indication; Clause 3 frame
//              ordering; 802.3ba Clause 4 64-bit MAC beat alignment
// Dependencies: —
// Author     : —
// Revision History:
//   2026-08-02 — Widened to 512-bit beat contract for 100 Gbps datapath
//==============================================================================

`default_nettype none

interface mac_if #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8
) (
  input logic clk,
  input logic rst
);
  logic                  valid;
  logic                  ready;
  logic [DATA_WIDTH-1:0] data;
  logic [KEEP_WIDTH-1:0] keep;
  logic                  sop;
  logic                  eop;
  logic [$clog2(KEEP_WIDTH + 1)-1:0] eop_pos;
  logic                  error;
  logic                  fcs_present;

  // Clocking blocks for race-free TB access. cb is the client
  // (source) view: drives the stream, samples ready. cb_mac is
  // the MAC (sink) view: samples the stream, drives ready.
  // Default skews: outputs driven in the NBA region of the clock
  // edge, inputs sampled just before the edge (1 step).
  clocking cb @(posedge clk);
    input  ready;
    output valid, data, keep, sop, eop, eop_pos, error, fcs_present;
  endclocking

  clocking cb_mac @(posedge clk);
    input  valid, data, keep, sop, eop, eop_pos, error, fcs_present;
    output ready;
  endclocking

  // RTL access stays raw-signal (synthesis-safe); the clocking
  // blocks are an additive, TB-only view.
  modport client_mp (
    input  clk, rst, ready,
    output valid, data, keep, sop, eop, eop_pos, error, fcs_present,
    clocking cb
  );

  modport mac_mp (
    input  clk, rst, valid, data, keep, sop, eop, eop_pos, error, fcs_present,
    output ready,
    clocking cb_mac
  );

endinterface

`default_nettype wire
