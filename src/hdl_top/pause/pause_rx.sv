//==============================================================================
// File       : rtl/pause/pause_rx.sv
// Module     : pause_rx
// Purpose    : Pause frame receiver-side PAUSE frame acceptance and timer load trigger
// IEEE Ref   : Annex 31B.1-31B.3, Figure 31B-1
// Dependencies: pause_pkg, mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-7.5: Added COVER marker for invalid PAUSE frame rejection
//==============================================================================

`default_nettype none

module pause_rx (
  input  logic        clk,
  input  logic        rst,
  input  logic        pause_event_valid,
  input  logic [15:0] pause_opcode,
  input  logic [47:0] pause_dest_addr,
  input  logic [15:0] pause_time,
  input  logic        transmission_in_progress,
  input  logic [47:0] local_addr,
  output logic        timer_load_valid,
  output logic [15:0] timer_load_time,
  output logic        pause_event_accepted,
  output logic        pending_event
);

  //============================================================================
  // Module     : pause_rx
  // Parameters : (none)
  // Inputs     :
  //   clk                    — Clock
  //   rst                    — Reset (synchronous, active high)
  //   pause_event_valid      — Pause frame detection strobe
  //   pause_opcode           — Pause frame opcode field
  //   pause_dest_addr        — Pause frame destination address
  //   pause_time             — Pause quanta from frame
  //   transmission_in_progress — TX path busy indicator
  //   local_addr             — Local MAC address
  // Outputs    :
  //   timer_load_valid       — Assert to load pause_timer_engine
  //   timer_load_time        — Pause quanta value
  //   pause_event_accepted   — Frame accepted for processing
  //   pending_event          — Frame buffered awaiting TX completion
  // Dependencies: pause_pkg, mac_pkg
  // Timing    : 1 cycle (frame accepted), 1 cycle (timer loaded)
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Annex 31B.1-31B.3, Figure 31B-1
  //============================================================================

  import pause_pkg::*;

  logic [15:0] pending_time;
  logic        event_is_pending;

  assign pending_event = event_is_pending;

  always_ff @(posedge clk) begin
    if (rst) begin
      timer_load_valid     <= 1'b0;
      timer_load_time      <= '0;
      pause_event_accepted <= 1'b0;
      pending_time         <= '0;
      event_is_pending     <= 1'b0;
    end else begin
      timer_load_valid     <= 1'b0;
      pause_event_accepted <= 1'b0;

      // PAUSE_OPCODE = 0x0001 per Annex 31B
      // PAUSE_MULTICAST_DA = 01:80:C2:00:00:01 per Annex 31B
      if (pause_event_valid &&
          (pause_opcode == PAUSE_OPCODE) &&
          ((pause_dest_addr == PAUSE_MULTICAST_DA) ||
           (pause_dest_addr == local_addr))) begin
        pending_time     <= pause_time;
        event_is_pending <= 1'b1;
        // COVER: PAUSE frame accepted for processing
      end else if (pause_event_valid) begin
        // COVER: Invalid PAUSE frame rejected (wrong opcode or destination)
      end else if (event_is_pending && !transmission_in_progress) begin
        timer_load_valid     <= 1'b1;
        timer_load_time      <= pending_time;
        pause_event_accepted <= 1'b1;
        event_is_pending     <= 1'b0;
        // COVER: PAUSE timer loaded
      end
    end
  end

  `ifndef SYNTHESIS
    always_ff @(posedge clk) begin
      if (!rst) begin
        assert (!(timer_load_valid && transmission_in_progress))
          else $error("PAUSE timer loaded before transmission completed");
        assert (!(pause_event_accepted && !timer_load_valid))
          else $error("PAUSE acceptance must coincide with timer load");
      end
    end
  `endif

endmodule

`default_nettype wire