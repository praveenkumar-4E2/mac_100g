//==============================================================================
// File       : rtl/tx/tx_arbiter.sv
// Module     : tx_arbiter
// Purpose    : TX path arbiter for data frames and PAUSE frames (512-bit beats)
// IEEE Ref   : Annex 31B.2.2, 4A.2.3.2
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — T-2.3: Initial implementation of TX path arbitration
//   2026-08-02 — Widened to 512-bit beat contract with keep/eop_pos
//==============================================================================

`default_nettype none

module tx_arbiter #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                          clk,
  input  logic                          rst,
  // Data frame input (from tx_pipeline)
  input  logic                          data_valid,
  output logic                          data_ready,
  input  logic [DATA_WIDTH-1:0]         data_data,
  input  logic [KEEP_WIDTH-1:0]         data_keep,
  input  logic                          data_sop,
  input  logic                          data_eop,
  input  logic [EOP_POS_W-1:0]          data_eop_pos,
  input  logic                          data_error,
  // PAUSE frame input (from pause_tx)
  input  logic                          pause_valid,
  output logic                          pause_ready,
  input  logic [DATA_WIDTH-1:0]         pause_data,
  input  logic [KEEP_WIDTH-1:0]         pause_keep,
  input  logic                          pause_sop,
  input  logic                          pause_eop,
  input  logic [EOP_POS_W-1:0]          pause_eop_pos,
  // Output to MAC TX
  output logic                          out_valid,
  input  logic                          out_ready,
  output logic [DATA_WIDTH-1:0]         out_data,
  output logic [KEEP_WIDTH-1:0]         out_keep,
  output logic                          out_sop,
  output logic                          out_eop,
  output logic [EOP_POS_W-1:0]          out_eop_pos,
  output logic                          out_error,
  // Status
  output logic                          busy,
  output logic                          frame_done
);

  //============================================================================
  // Module     : tx_arbiter
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk          — Clock
  //   rst          — Reset (synchronous, active high)
  //   data_valid   — Data frame valid
  //   data_data    — Data beat
  //   data_keep    — Data beat byte enables
  //   data_sop     — Data start of packet
  //   data_eop     — Data end of packet
  //   data_eop_pos — Data EOP valid-byte count
  //   data_error   — Data error flag
  //   pause_valid  — PAUSE frame valid
  //   pause_data   — PAUSE beat
  //   pause_keep   — PAUSE beat byte enables
  //   pause_sop    — PAUSE start of packet
  //   pause_eop    — PAUSE end of packet
  //   pause_eop_pos— PAUSE EOP valid-byte count
  //   out_ready    — Output ready (backpressure)
  // Outputs    :
  //   data_ready   — Data frame ready
  //   pause_ready  — PAUSE frame ready
  //   out_valid    — Output valid
  //   out_data     — Output beat
  //   out_keep     — Output beat byte enables
  //   out_sop      — Output start of packet
  //   out_eop      — Output end of packet
  //   out_eop_pos  — Output EOP valid-byte count
  //   out_error    — Output error
  //   busy         — Arbiter busy
  //   frame_done   — Frame complete pulse
  // Dependencies: mac_pkg
  // Timing    : Combinational + 1 register
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Annex 31B.2.2, 4A.2.3.2
  //
  // Arbitration Policy:
  //   - Data frames have priority over PAUSE frames
  //   - PAUSE frames are injected only during idle periods (after data frame
  //     completes and before next data frame)
  //   - Single-trigger: one PAUSE frame per trigger event
  //   - Backpressure propagated from output to selected input
  //============================================================================

  import mac_pkg::*;

  // FSM states
  typedef enum logic [1:0] {
    IDLE,
    DATA,
    PAUSE,
    WAIT_IPG
  } state_e;

  state_e state, state_next;

  // Output mux select
  logic select_pause;
  logic frame_active;

  // Frame tracking
  logic last_eop;
  logic output_transfer;

  assign output_transfer = out_valid && out_ready;
  assign busy = (state != IDLE);
  assign frame_done = last_eop && output_transfer;

  // Arbitration logic: data has priority, PAUSE only when idle
  always_comb begin
    select_pause = 1'b0;
    data_ready   = 1'b0;
    pause_ready  = 1'b0;
    state_next   = state;

    unique case (state)
      IDLE: begin
        // Data frames have priority
        if (data_valid) begin
          state_next = DATA;
        end else if (pause_valid) begin
          select_pause = 1'b1;
          state_next   = PAUSE;
        end
      end

      DATA: begin
        data_ready = out_ready;
        if (data_eop && output_transfer) begin
          state_next = WAIT_IPG;
        end
      end

      PAUSE: begin
        select_pause = 1'b1;
        pause_ready  = out_ready;
        if (pause_eop && output_transfer) begin
          state_next = IDLE;
        end
      end

      WAIT_IPG: begin
        // Wait for IPG to complete, then return to IDLE
        // IPG timing handled externally by tx_ipg_timer_stage
        state_next = IDLE;
      end

      default: state_next = IDLE;
    endcase
  end

  // State register
  always_ff @(posedge clk) begin
    if (rst) begin
      state    <= IDLE;
      last_eop <= 1'b0;
    end else begin
      state <= state_next;
      last_eop <= (state == DATA) && data_eop && output_transfer;
    end
  end

  // Output mux
  always_comb begin
    out_valid   = 1'b0;
    out_data    = '0;
    out_keep    = '0;
    out_sop     = 1'b0;
    out_eop     = 1'b0;
    out_eop_pos = '0;
    out_error   = 1'b0;

    if (select_pause) begin
      out_valid   = pause_valid;
      out_data    = pause_data;
      out_keep    = pause_keep;
      out_sop     = pause_sop;
      out_eop     = pause_eop;
      out_eop_pos = pause_eop_pos;
      out_error   = 1'b0;
    end else if (state == DATA) begin
      out_valid   = data_valid;
      out_data    = data_data;
      out_keep    = data_keep;
      out_sop     = data_sop;
      out_eop     = data_eop;
      out_eop_pos = data_eop_pos;
      out_error   = data_error;
    end
  end

  `ifndef SYNTHESIS
    // ASSERT: Data frames have priority over PAUSE frames
    property data_priority;
      @(posedge clk) disable iff (rst)
        data_valid && pause_valid |-> !select_pause;
    endproperty
    assert property (data_priority)
      else $error("tx_arbiter: PAUSE granted while data valid");

    // ASSERT: PAUSE only injected when idle
    property pause_only_idle;
      @(posedge clk) disable iff (rst)
        select_pause |-> (state == IDLE || state == PAUSE);
    endproperty
    assert property (pause_only_idle)
      else $error("tx_arbiter: PAUSE granted in non-idle state");

    // COVER: PAUSE frame transmitted
    property pause_frame_complete;
      @(posedge clk) disable iff (rst)
        (state == PAUSE) && pause_eop && output_transfer;
    endproperty
    cover property (pause_frame_complete);
  `endif

endmodule

`default_nettype wire
