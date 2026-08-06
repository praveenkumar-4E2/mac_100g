//==============================================================================
// File       : rtl/integration/mac_event_collector.sv
// Module     : mac_event_collector
// Purpose    : Map discrete MAC-domain error and status events to the compact
//              statistics event-vector contract
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module mac_event_collector (
  input  logic       rx_invalid_event,
  input  logic       rx_crc_event,
  input  logic       rx_oversize_event,
  input  logic       rx_unsupported_control_event,
  input  logic       pause_expired,
  input  logic       tx_error_event,
  output logic [5:0] event_vector
);

  //============================================================================
  // Module     : mac_event_collector
  // Parameters : (none)
  // Inputs     :
  //   rx_invalid_event             — Invalid frame event
  //   rx_crc_event                 — CRC error event
  //   rx_oversize_event            — Oversize frame event
  //   rx_unsupported_control_event — Unsupported control frame event
  //   pause_expired                — PAUSE timer expired event
  //   tx_error_event               — TX error event
  // Outputs    :
  //   event_vector[5:0]            — Packed event vector
  // Dependencies: —
  // Timing    : Combinational
  // Reset     : N/A
  // Clock     : N/A
  //============================================================================

  assign event_vector = {
    tx_error_event,
    pause_expired,
    rx_unsupported_control_event,
    rx_oversize_event,
    rx_crc_event,
    rx_invalid_event
  };

endmodule

`default_nettype wire