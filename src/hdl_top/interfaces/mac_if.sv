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

  // TB-side clocking blocks, inputs only: default input skew #1step
  // samples the pre-edge value — the exact view the DUT's always_ff
  // capture has — so driver handshakes and RTL captures can never
  // disagree (a post-edge ready read can advance the driver a cycle
  // before the DUT sees the beat). Clocking-block outputs are NOT
  // declared: QuestaSim treats them as implicit drivers on the
  // underlying signals, which conflicts with RTL-connected instances
  // of this interface (mac_if.client_mp ports) and with continuous
  // assignments in the TB. Drivers therefore write the raw signals
  // with nonblocking assignments and sample ready via drv_cb.
  clocking drv_cb @(posedge clk);
    default input #1step output #0;
    input ready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #0;
    input valid, ready, data, keep, sop, eop, eop_pos, error, fcs_present;
  endclocking

  modport client_mp (
    input  clk, rst, ready,
    output valid, data, keep, sop, eop, eop_pos, error, fcs_present
  );

  modport mac_mp (
    input  clk, rst, valid, data, keep, sop, eop, eop_pos, error, fcs_present,
    output ready
  );

endinterface

`default_nettype wire
