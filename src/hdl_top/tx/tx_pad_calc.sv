//==============================================================================
// File       : rtl/tx/tx_pad_calc.sv
// Module     : tx_pad_calc
// Purpose    : Derive transmitted client-data and generated pad lengths
// IEEE Ref   : Clause 3.2.7–3.2.8, Annex 4A 4A.2.3.2.4
// Dependencies: mac_pkg
// Author     : Ethernet MAC Team
// Revision History:
//   2026-07-29 — Added AGENTS.md-compliant file and module headers
//   2026-08-04 — Client stream carries DA/SA/LT + payload (+FCS when
//                supplied); payload/pad derived from the full client count
//==============================================================================

`default_nettype none

module tx_pad_calc #(
  parameter int unsigned COUNT_WIDTH = 12
) (
  input  logic [COUNT_WIDTH-1:0] client_bytes,
  input  logic                   fcs_present,
  output logic [COUNT_WIDTH-1:0] payload_bytes,
  output logic [COUNT_WIDTH-1:0] pad_bytes
);

  //============================================================================
  // Module     : tx_pad_calc
  // Parameters :
  //   COUNT_WIDTH = 12 — Bit width of byte count ports
  // Inputs     :
  //   client_bytes     — Client stream byte count (header + payload,
  //                      + FCS when the client supplies it)
  //   fcs_present      — Client supplies FCS (1) or MAC appends (0)
  // Outputs    :
  //   payload_bytes    — Payload byte count (excl. header, excl. FCS)
  //   pad_bytes        — Required pad byte count [COUNT_WIDTH-1:0]
  // Dependencies: mac_pkg (MIN_FRAME_OCTETS, FCS_BITS, MAC_ADDRESS_BITS, LENGTH_TYPE_BITS)
  // Timing    : Combinational (purely combinational logic)
  // Reset     : None (combinational module)
  // Clock     : None (combinational module)
  //============================================================================

  import mac_pkg::*;
  localparam int unsigned FCS_OCTETS = FCS_BITS / 8;
  localparam int unsigned HEADER_OCTETS =
      2 * (MAC_ADDRESS_BITS / 8) + (LENGTH_TYPE_BITS / 8);
  localparam int unsigned MIN_CLIENT_AND_PAD_OCTETS =
      MIN_FRAME_OCTETS - HEADER_OCTETS - FCS_OCTETS;

  always_comb begin
    payload_bytes = (client_bytes >= HEADER_OCTETS) ?
                    client_bytes - HEADER_OCTETS : '0;
    if (fcs_present) begin
      // A supplied FCS implies any required pad is client supplied as well.
      if (payload_bytes >= FCS_OCTETS)
        payload_bytes = payload_bytes - FCS_OCTETS;
      pad_bytes = '0;
    end else begin
      pad_bytes = (payload_bytes < MIN_CLIENT_AND_PAD_OCTETS) ?
                  MIN_CLIENT_AND_PAD_OCTETS - payload_bytes : '0;
    end
  end
endmodule

`default_nettype wire
