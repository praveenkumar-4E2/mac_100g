//==============================================================================
// File       : rtl/control/control_classifier.sv
// Module     : control_classifier
// Purpose    : Identify MAC Control frames from the Length/Type field
// IEEE Ref   : IEEE 802.3 Clause 31.4.1.3, MAC Control EtherType 0x8808
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module control_classifier (
  input  logic [15:0] length_type,
  output logic        is_control
);

  //============================================================================
  // Module     : control_classifier
  // Parameters : (none)
  // Inputs     :
  //   length_type — Length/Type field from Ethernet frame
  // Outputs    :
  //   is_control — Asserted when frame is MAC Control (Type = 0x8808)
  // Dependencies: —
  // Timing    : Combinational
  // Reset     : N/A
  // Clock     : N/A
  // IEEE Ref  : Clause 31.4.1.3
  //============================================================================

  import eth_pkg::*;

  assign is_control = (length_type == ETHERTYPE_MAC_CONTROL);
  // COVER: MAC Control frame detected (EtherType 0x8808)

endmodule

`default_nettype wire