//==============================================================================
// File       : rtl/pause/pause_admission_gate.sv
// Module     : pause_admission_gate
// Purpose    : Gate new data-frame admission while PAUSE is active; MAC
//              Control admission remains independent
// IEEE Ref   : IEEE 802.3 Annex 31B and IEEE 802.3ba Clause 4 timing bound
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module pause_admission_gate #(
  parameter int unsigned MAX_START_DELAY_QUANTA = 394
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        paused,
  input  logic        pause_event_accepted,
  input  logic [15:0] pause_time,
  input  logic        data_req_valid,
  output logic        data_req_ready,
  input  logic        data_frame_active,
  input  logic        data_frame_done,
  input  logic        control_req_valid,
  output logic        control_req_ready,
  output logic        data_admit,
  output logic        control_admit,
  input  logic        timing_quantum_tick,
  input  logic        new_data_frame_start,
  input  logic [2:0]  speed,  // Effective MAC speed (000=10G..100=100G)
  output logic        timing_check_active,
  output logic        timing_check_pass,
  output logic        timing_check_violation,
  output logic [9:0]  timing_elapsed_quanta
);

  //============================================================================
  // Module     : pause_admission_gate
  // Parameters :
  //   MAX_START_DELAY_QUANTA = 394 — Max quanta before first frame start
  // Inputs     :
  //   clk                    — Clock
  //   rst                    — Reset (synchronous, active high)
  //   paused                 — PAUSE timer active
  //   pause_event_accepted   — New PAUSE frame accepted
  //   pause_time             — PAUSE time value
  //   data_req_valid         — Data frame request valid
  //   data_frame_active      — Data frame in progress
  //   data_frame_done        — Data frame completed
  //   control_req_valid      — Control frame request valid
  //   timing_quantum_tick    — Timing quantum tick
  //   new_data_frame_start   — New data frame started
  // Outputs    :
  //   data_req_ready         — Data request ready
  //   control_req_ready      — Control request ready
  //   data_admit             — Data frame admission gate
  //   control_admit          — Control frame admission gate
  //   timing_check_active    — Timing check in progress
  //   timing_check_pass      — Timing check passed
  //   timing_check_violation — Timing check violated
  //   timing_elapsed_quanta  — Elapsed quanta count
  // Dependencies: —
  // Timing    : Combinational + 1-cycle sequential
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Annex 31B, 802.3ba Clause 4
  // MAX_START_DELAY_QUANTA = 394 (100G per 802.3ba Table 4-2): max quanta before first frame start
  //============================================================================

  // MAX_START_DELAY = pause_delay_for_speed(effective_speed) — the maximum
  // time (bit-times) allowed before the first data frame starts after a PAUSE
  // frame (802.3ba Clause 4 Table 4-2: 394 @10G/25G, 118 @40G/50G, 60 @100G).
  import mac_speed_params_pkg::*;
  logic [9:0] max_start_delay;
  assign max_start_delay = 10'(pause_delay_for_speed(int'(speed)));

  always_comb begin
    data_admit       = !paused;
    control_admit    = 1'b1;
    data_req_ready   = !paused && !data_frame_active;
    control_req_ready = 1'b1;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      timing_check_active    <= 1'b0;
      timing_check_pass      <= 1'b0;
      timing_check_violation <= 1'b0;
      timing_elapsed_quanta  <= '0;
    end else begin
      timing_check_pass      <= 1'b0;
      timing_check_violation <= 1'b0;

      if (pause_event_accepted && (pause_time != 16'd0)) begin
        timing_check_active   <= 1'b1;
        timing_elapsed_quanta <= '0;
        // COVER: PAUSE timing check started
      end else if (timing_check_active) begin
        if (new_data_frame_start) begin
          timing_check_active <= 1'b0;
          if (timing_elapsed_quanta <= max_start_delay) begin
            timing_check_pass <= 1'b1;
            // COVER: PAUSE timing check passed
          end else begin
            timing_check_violation <= 1'b1;
            // COVER: PAUSE timing check violated
            // ASSERT: First data frame must start within max_start_delay
          end
        end else if (timing_quantum_tick &&
                     (timing_elapsed_quanta < 10'(max_start_delay + 1'b1))) begin
          timing_elapsed_quanta <= timing_elapsed_quanta + 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire