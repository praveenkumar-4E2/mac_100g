//==============================================================================
// File       : rtl/tx/tx_axi4_stream_adapter.sv
// Module     : tx_axi4_stream_adapter
// Purpose    : Convert AXI4-Stream slave interface to internal mac_if client modport
// IEEE Ref   : AXI4-Stream Protocol (ARM IHI 0051)
// Dependencies: mac_if, axi4_stream_if
// Author     : —
// Revision History:
//   2026-07-29 — T-5.2: Created TX AXI4-Stream adapter
//   2026-08-02 — Widened to 512-bit beat contract with keep/eop_pos
//   2026-08-07 — W1: mac_sop now derived from pre-handshake frame state;
//                mac_sop_r removed (was one handshake late). SVA added.
//==============================================================================

`default_nettype none

module tx_axi4_stream_adapter #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                          clk,
  input  logic                          rst,

  // AXI4-Stream slave input
  input  logic [DATA_WIDTH-1:0]         s_tdata,
  input  logic [KEEP_WIDTH-1:0]         s_tkeep,
  input  logic                          s_tvalid,
  output logic                          s_tready,
  input  logic                          s_tlast,
  input  logic [7:0]                    s_tuser,

  // mac_if client output
  output logic                          mac_valid,
  input  logic                          mac_ready,
  output logic [DATA_WIDTH-1:0]         mac_data,
  output logic [KEEP_WIDTH-1:0]         mac_keep,
  output logic                          mac_sop,
  output logic                          mac_eop,
  output logic [EOP_POS_W-1:0]          mac_eop_pos,
  output logic                          mac_error,
  output logic                          mac_fcs_present
);

  //============================================================================
  // Module     : tx_axi4_stream_adapter
  // Parameters :
  //   DATA_WIDTH = 512 — Data bus width
  //   KEEP_WIDTH = 64  — Byte enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk          — Clock
  //   rst          — Reset (synchronous, active high)
  //   s_tdata      — AXI4-Stream data
  //   s_tkeep      — AXI4-Stream byte enable
  //   s_tvalid     — AXI4-Stream valid
  //   s_tlast      — AXI4-Stream last (end of frame)
  //   s_tuser      — AXI4-Stream sideband (tuser[0]=error, tuser[1]=fcs_present)
  //   mac_ready    — mac_if ready
  // Outputs    :
  //   s_tready     — AXI4-Stream ready
  //   mac_valid    — mac_if valid
  //   mac_data     — mac_if data
  //   mac_keep     — mac_if byte enables
  //   mac_sop      — mac_if start of packet (same-cycle with first accepted beat)
  //   mac_eop      — mac_if end of packet
  //   mac_eop_pos  — mac_if EOP valid-byte count
  //   mac_error    — mac_if error
  //   mac_fcs_present — mac_if FCS present
  //
  // AXI input contract (frozen, see docs/interface/axi4-stream_adapter.md):
  //   - tvalid && tready is the only accepted-beat event.
  //   - tkeep is a nonzero contiguous low-lane mask, full on interior beats.
  //   - tlast ends the frame; the first accepted beat after idle starts one.
  //   - tuser[0] is the TX input error flag, tuser[1] the FCS-present flag.
  //   - All source-controlled fields stay stable while stalled.
  // Dependencies: mac_if, axi4_stream_if
  // Timing    : Combinational + 1 register (frame_active only)
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : AXI4-Stream (ARM IHI 0051)
  //============================================================================

  logic frame_active;

  // Popcount of the byte-enable mask: EOP position of the final beat.
  function automatic logic [EOP_POS_W-1:0] popcount_keep(input logic [KEEP_WIDTH-1:0] v);
    popcount_keep = '0;
    for (integer j = 0; j < KEEP_WIDTH; j++)
      popcount_keep += v[j];
  endfunction

  // AXI4-Stream to mac_if mapping
  // tlast → eop, tuser[0] → error, tuser[1] → fcs_present
  // mac_sop is derived from the pre-handshake frame state so the first
  // accepted beat carries SOP in the same cycle (W1 fix).
  assign s_tready     = mac_ready;
  assign mac_valid    = s_tvalid;
  assign mac_data     = s_tdata;
  assign mac_keep     = s_tkeep;
  assign mac_sop      = s_tvalid && !frame_active;
  assign mac_eop      = s_tlast;
  assign mac_eop_pos  = popcount_keep(s_tkeep);
  assign mac_error    = s_tuser[0];
  assign mac_fcs_present = s_tuser[1];

  // Frame-active state advances only on a real handshake; the reset value
  // forces the frame context idle so no stale SOP survives reset release.
  always_ff @(posedge clk) begin
    if (rst)
      frame_active <= 1'b0;
    else if (s_tvalid && s_tready)
      frame_active <= !s_tlast;
  end

  `ifndef SYNTHESIS
    // W1: the first accepted beat must carry internal SOP.
    property first_beat_has_sop;
      @(posedge clk) disable iff (rst)
        s_tvalid && s_tready && !frame_active |-> mac_sop;
    endproperty
    assert property (first_beat_has_sop)
      else $error("tx_axi4_stream_adapter: first accepted beat lost SOP");

    // W1: no accepted interior beat may carry SOP.
    property interior_beat_no_sop;
      @(posedge clk) disable iff (rst)
        s_tvalid && s_tready && frame_active |-> !mac_sop;
    endproperty
    assert property (interior_beat_no_sop)
      else $error("tx_axi4_stream_adapter: interior accepted beat asserted SOP");

    // W1: an accepted EOP must clear the frame context on the next cycle.
    property accepted_eop_clears_frame;
      @(posedge clk) disable iff (rst)
        s_tvalid && s_tready && s_tlast |=> !frame_active;
    endproperty
    assert property (accepted_eop_clears_frame)
      else $error("tx_axi4_stream_adapter: frame context not cleared at EOP");

    // W1: all AXI source-controlled fields are stable across consecutive
    // stalled cycles.  A ready transition may complete the transfer on the
    // following edge, after which the source may legally retire the beat.
    property source_stable_while_stalled;
      @(posedge clk) disable iff (rst)
        (s_tvalid && !s_tready) ##1 (s_tvalid && !s_tready) |->
          $stable({ s_tdata, s_tkeep, s_tlast, s_tuser });
    endproperty
    assert property (source_stable_while_stalled)
      else $error("tx_axi4_stream_adapter: AXI source fields changed while stalled");

    // W1: SOP stays asserted while the first beat is stalled (pre-handshake state).
    property first_beat_sop_stable_while_stalled;
      @(posedge clk) disable iff (rst)
        s_tvalid && !s_tready && !frame_active |-> mac_sop;
    endproperty
    assert property (first_beat_sop_stable_while_stalled)
      else $error("tx_axi4_stream_adapter: SOP dropped while first beat stalled");
  `endif

  // COVER: AXI4-Stream frame transferred

endmodule

`default_nettype wire
