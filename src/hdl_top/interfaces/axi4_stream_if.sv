//==============================================================================
// File       : rtl/interfaces/axi4_stream_if.sv
// Module     : axi4_stream_if
// Purpose    : AXI4-Stream interface for MAC data path boundaries
// IEEE Ref   : AXI4-Stream Protocol (ARM IHI 0051)
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — T-5.1: Created AXI4-Stream interface definition
//==============================================================================

`default_nettype none

interface axi4_stream_if #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8
) (
  input logic clk,
  input logic rst
);
  logic [DATA_WIDTH-1:0] tdata;
  logic [KEEP_WIDTH-1:0] tkeep;
  logic                  tvalid;
  logic                  tready;
  logic                  tlast;
  logic [7:0]            tuser;

  // TB-side clocking blocks (see mac_if.sv for the skew rationale):
  // inputs only — clocking-block outputs are implicit drivers in
  // QuestaSim and would conflict with RTL-connected instances.
  clocking drv_cb @(posedge clk);
    default input #1step output #0;
    input tready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #0;
    input tdata, tkeep, tvalid, tready, tlast, tuser;
  endclocking

  modport master_mp (
    input  clk, rst, tready,
    output tdata, tkeep, tvalid, tlast, tuser
  );

  modport slave_mp (
    input  clk, rst, tdata, tkeep, tvalid, tlast, tuser,
    output tready
  );

endinterface

`default_nettype wire
