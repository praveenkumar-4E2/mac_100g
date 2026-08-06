//==============================================================================
// File       : rtl/tx/tx_scheduler.sv
// Module     : tx_scheduler
// Purpose    : Own frame admission eligibility; request admitted only when
//              builder/capture resource is available and TX IPG is done
// IEEE Ref   : IEEE 802.3 Annex 4A 4A.2.3.2.1-4A.2.3.2.3; Table 4A-2
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module tx_scheduler (
  input  logic start,
  input  logic request_ready,
  input  logic ipg_done,
  output logic accept_start,
  output logic request_ready_out
);

  //============================================================================
  // Module     : tx_scheduler
  // Parameters : (none)
  // Inputs     :
  //   start            — Frame start pulse
  //   request_ready    — Capture resource ready
  //   ipg_done         — IPG timer done
  // Outputs    :
  //   accept_start     — Frame admitted
  //   request_ready_out — Request ready to client
  // Dependencies: —
  // Timing    : Combinational
  // Reset     : N/A
  // Clock     : N/A
  // IEEE Ref  : Annex 4A 4A.2.3.2.1-.3; Table 4A-2
  // COVER: Frame admitted when start && request_ready && ipg_done
  //============================================================================

  assign accept_start      = start && request_ready && ipg_done;
  assign request_ready_out = request_ready && ipg_done;
  // COVER: Frame admitted when start && request_ready && ipg_done
  // ASSERT: IPG must complete before frame admission

endmodule

`default_nettype wire