`default_nettype none

//==============================================================================
// File       : rtl/primitives/address_filter.sv
// Module     : address_filter
// Purpose    : Combinational destination-address recognition for the MAC receive path
// IEEE Ref   : Clause 3.2.3.1-3.2.5; Annex 4A 4A.2.4.1.1; Annex 31B 31B.1
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-3.4: Added COVER marker for promiscuous mode acceptance
//==============================================================================
//
// Module     : address_filter
// Parameters :
//   GROUP_TABLE_SIZE = 4 — Number of group address filter entries
// Inputs     :
//   local_addr       — 48-bit individual address assigned to this station
//   dest_addr        — 48-bit destination address from the received frame
//   promiscuous_en   — Accepts every destination when asserted
//   pause_en         — Enables the reserved PAUSE multicast destination
//   group_addrs      — GROUP_TABLE_SIZE configured group-address entries
//   group_valid      — Per-entry active bits; inactive entries are ignored
// Outputs    :
//   accept           — Combinational destination-recognition result
// Dependencies: mac_pkg
// Timing    : Combinational
// Reset     : N/A
// Clock     : N/A
// IEEE Ref  : Clause 3.2.3.1-3.2.5; Annex 4A 4A.2.4.1.1; Annex 31B 31B.1
//
// COVER: Broadcast address match
// COVER: Unicast address match
// COVER: PAUSE multicast address match
// COVER: Group address match
// COVER: Frame accepted in promiscuous mode
//==============================================================================
module address_filter #(
  parameter int unsigned GROUP_TABLE_SIZE = 4
) (
  input  logic [47:0] local_addr,
  input  logic [47:0] dest_addr,
  input  logic        promiscuous_en,
  input  logic        pause_en,
  input  logic [47:0] group_addrs [GROUP_TABLE_SIZE],
  input  logic        group_valid [GROUP_TABLE_SIZE],
  output logic        accept
);
  import mac_pkg::*;

  integer index;
  always_comb begin
    accept = promiscuous_en || (dest_addr == BROADCAST_ADDR) ||
             (dest_addr == local_addr) ||
             (pause_en && (dest_addr == PAUSE_MULTICAST_DA));

    for (index = 0; index < GROUP_TABLE_SIZE; index = index + 1) begin
      if (group_valid[index] && (dest_addr == group_addrs[index])) begin
        accept = 1'b1;
      end
    end
  end
endmodule

`default_nettype wire
