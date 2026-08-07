//==============================================================================
// File       : rtl/tx/tx_axi_admission.sv
// Module     : tx_axi_admission
// Purpose    : TX admission controller — couples AXI first-beat acceptance to
//              frame admission. The AXI first-beat handshake is the only AXI-
//              mode admission point: a first beat is accepted only when TX is
//              enabled, PAUSE permits data admission, the TX pipeline reports
//              request-ready (IPG complete + capture/builder idle), and no AXI
//              frame is in flight. Admission atomically generates one internal
//              start_capture pulse and latches the frame request metadata.
// IEEE Ref   : IEEE 802.3 Clauses 2.3.1, 4, 31; Annex 4A 4A.2.3
// Dependencies: mac_if
// Author     : —
// Revision History:
//   2026-08-07 — W2: Created AXI first-beat admission controller
//==============================================================================

`default_nettype none

module tx_axi_admission #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                          clk,
  input  logic                          rst,

  // Stream from the AXI4-Stream TX adapter (mac_if client side)
  input  logic                          s_valid,
  input  logic [DATA_WIDTH-1:0]         s_data,
  input  logic [KEEP_WIDTH-1:0]         s_keep,
  input  logic                          s_sop,
  input  logic                          s_eop,
  input  logic [EOP_POS_W-1:0]          s_eop_pos,
  input  logic                          s_error,
  input  logic                          s_fcs_present,
  output logic                          s_ready,

  // Capture-facing stream (drives tx_client_capture via mac_if)
  output logic                          c_valid,
  output logic [DATA_WIDTH-1:0]         c_data,
  output logic [KEEP_WIDTH-1:0]         c_keep,
  output logic                          c_sop,
  output logic                          c_eop,
  output logic [EOP_POS_W-1:0]          c_eop_pos,
  output logic                          c_error,
  output logic                          c_fcs_present,
  input  logic                          c_ready,

  // Admission conditions
  input  logic                          tx_enabled,        // cfg_control[CTRL_TX_BIT]
  input  logic                          pause_admit,       // pause_admission_gate.data_admit
  input  logic                          pipeline_req_ready,// mac_tx_path.req_ready
  input  logic [47:0]                   dest_addr,         // request metadata (reserved)
  input  logic [47:0]                   src_addr,
  input  logic [15:0]                   length_type,

  // Status
  output logic                          start_capture,     // admission pulse (scheduler start)
  output logic                          frame_active       // AXI frame in flight
);

  //============================================================================
  // Module     : tx_axi_admission
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   s_valid            — Adapter stream valid
  //   s_data             — Adapter stream beat
  //   s_keep             — Adapter stream byte enables
  //   s_sop              — Adapter stream start-of-packet
  //   s_eop              — Adapter stream end-of-packet
  //   s_eop_pos          — Adapter stream EOP byte count
  //   s_error            — Adapter stream error
  //   s_fcs_present      — Adapter stream FCS-present
  //   c_ready            — Capture client ready (capacity)
  //   tx_enabled         — TX enable admission condition
  //   pause_admit        — PAUSE gate admission condition
  //   pipeline_req_ready — Scheduler request readiness (IPG + resources)
  //   dest/src/length_type — Frame request metadata latched at admission
  // Outputs    :
  //   s_ready            — Adapter stream ready (AXI tready)
  //   c_valid            — Capture stream valid
  //   c_data             — Capture stream beat
  //   c_keep             — Capture stream byte enables
  //   c_sop              — Capture stream start-of-packet
  //   c_eop              — Capture stream end-of-packet
  //   c_eop_pos          — Capture stream EOP byte count
  //   c_error            — Capture stream error
  //   c_fcs_present      — Capture stream FCS-present
  //   start_capture      — Admission pulse, exactly one per admitted frame
  //   frame_active       — Registered AXI frame-in-flight state
  //
  // Admission contract (frozen, docs/interface/axi4-stream_adapter.md):
  //   - first_beat_ready = tx_enabled && pause_admit && pipeline_req_ready.
  //   - A presented first beat (s_valid && !frame_active) with first_beat_ready
  //     asserts start_capture for exactly one cycle and marks the frame active.
  //   - The first data beat is accepted on the following cycle (capture active);
  //     subsequent beats follow capture capacity (c_ready) only.
  //   - frame_active clears only on an accepted final beat or reset.
  // Dependencies: mac_if
  // Timing    : Combinational + 1 register
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : IEEE 802.3 Clauses 2.3.1, 4, 31; Annex 4A 4A.2.3
  //============================================================================

  logic frame_active_q;
  logic [47:0] meta_dest_q;
  logic [47:0] meta_src_q;
  logic [15:0] meta_length_type_q;

  // First-beat readiness: all admission conditions AND no frame in flight.
  wire first_beat_ok = tx_enabled && pause_admit && pipeline_req_ready;
  wire admit         = s_valid && !frame_active_q && first_beat_ok;

  // start_capture is combinational from admit, so it pulses for exactly one
  // cycle: frame_active_q latches the admission at the next edge.
  assign start_capture = admit;

  // First-beat ready is gated by the admission state: the first beat cannot be
  // accepted before admission; all other beats follow capture capacity only.
  assign s_ready = frame_active_q ? c_ready : 1'b0;

  // Stream pass-through (the adapter already owns SOP/EOP/keep derivation).
  // c_valid is gated by s_ready so the capture-side handshake event
  // (c_valid && c_ready) is exactly the AXI accepted-beat event
  // (s_valid && s_ready): the capture can never accept a beat that the AXI
  // source has not yet handed over, nor the same beat twice.
  assign c_valid       = s_valid && s_ready;
  assign c_data        = s_data;
  assign c_keep        = s_keep;
  assign c_sop         = s_sop;
  assign c_eop         = s_eop;
  assign c_eop_pos     = s_eop_pos;
  assign c_error       = s_error;
  assign c_fcs_present = s_fcs_present;

  always_ff @(posedge clk) begin
    if (rst) begin
      frame_active_q    <= 1'b0;
      meta_dest_q       <= '0;
      meta_src_q        <= '0;
      meta_length_type_q <= '0;
    end else begin
      if (frame_active_q && s_valid && s_ready && s_eop) begin
        // Accepted final beat: the frame context closes.
        frame_active_q <= 1'b0;
      end else if (admit) begin
        // First-beat admission: atomically latch request metadata and
        // establish the AXI frame context.
        frame_active_q     <= 1'b1;
        meta_dest_q        <= dest_addr;
        meta_src_q         <= src_addr;
        meta_length_type_q <= length_type;
      end
    end
  end

  assign frame_active = frame_active_q;

  `ifndef SYNTHESIS
    // W2: the capture-side handshake is exactly the AXI accepted-beat event —
    // the capture consumes a beat if and only if the AXI source delivered it
    // (structurally guaranteed by the c_valid gating, guarded here against
    // future edits).
    property capture_handshake_equals_axi;
      @(posedge clk) disable iff (rst)
        (c_valid && c_ready) == (s_valid && s_ready);
    endproperty
    assert property (capture_handshake_equals_axi)
      else $error("tx_axi_admission: capture handshake diverges from AXI handshake");

    // W2: one accepted first beat produces exactly one start_capture pulse.
    property first_acceptance_one_pulse;
      @(posedge clk) disable iff (rst)
        s_valid && s_ready && !$past(frame_active_q) |-> $past(start_capture);
    endproperty
    assert property (first_acceptance_one_pulse)
      else $error("tx_axi_admission: first-beat acceptance without prior admission pulse");

    // W2: start_capture is a single-cycle pulse.
    property start_capture_is_pulse;
      @(posedge clk) disable iff (rst)
        start_capture |=> !start_capture;
    endproperty
    assert property (start_capture_is_pulse)
      else $error("tx_axi_admission: start_capture not a single-cycle pulse");

    // W2: no second admission before EOP/reset/abort.
    property no_second_admission;
      @(posedge clk) disable iff (rst)
        start_capture |=> !start_capture until (s_valid && s_ready && s_eop);
    endproperty
    assert property (no_second_admission)
      else $error("tx_axi_admission: second admission before frame close");

    // W2: first-beat tready stays low while TX is disabled.
    property first_ready_low_when_disabled;
      @(posedge clk) disable iff (rst)
        !tx_enabled && !frame_active_q |-> !s_ready;
    endproperty
    assert property (first_ready_low_when_disabled)
      else $error("tx_axi_admission: first-beat tready high while TX disabled");

    // W2: first-beat tready stays low while PAUSE blocks data admission.
    property first_ready_low_when_paused;
      @(posedge clk) disable iff (rst)
        !pause_admit && !frame_active_q |-> !s_ready;
    endproperty
    assert property (first_ready_low_when_paused)
      else $error("tx_axi_admission: first-beat tready high while PAUSE blocks");

    // W2: first-beat tready stays low while the pipeline is not request-ready.
    property first_ready_low_when_not_ready;
      @(posedge clk) disable iff (rst)
        !pipeline_req_ready && !frame_active_q |-> !s_ready;
    endproperty
    assert property (first_ready_low_when_not_ready)
      else $error("tx_axi_admission: first-beat tready high while pipeline busy");

    // W2: a first beat held valid through unavailability is accepted exactly
    // once — the frame context cannot reopen before the previous close.
    property no_reopen_before_close;
      @(posedge clk) disable iff (rst)
        frame_active_q && !(s_valid && s_ready && s_eop) |=> frame_active_q;
    endproperty
    assert property (no_reopen_before_close)
      else $error("tx_axi_admission: frame context reopened before close");

    // W2: request metadata is latched once at admission and stable while
    // the frame is active.
    property metadata_stable_while_active;
      @(posedge clk) disable iff (rst)
        frame_active_q |=> $stable({ meta_dest_q, meta_src_q, meta_length_type_q });
    endproperty
    assert property (metadata_stable_while_active)
      else $error("tx_axi_admission: request metadata changed while frame active");
  `endif

endmodule

`default_nettype wire
