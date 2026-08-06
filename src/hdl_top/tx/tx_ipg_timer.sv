//==============================================================================
// File       : rtl/tx/tx_ipg_timer.sv
// Module     : tx_ipg_timer_stage
// Purpose    : Active TX-path owner of the 96 bit-time interpacket-gap state
// IEEE Ref   : IEEE 802.3ba Clause 4 Table 4-2; Annex 4A Table 4A-2
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-4.3: Added speed input port for runtime speed configuration
//==============================================================================

`default_nettype none

module tx_ipg_timer_stage #(
  parameter int unsigned IPG_VALUE = 96
) (
  input  logic       clk,
  input  logic       rst,
  input  logic       start,
  input  logic       enable,
  input  logic       tick,
  input  logic [2:0] speed,  // Speed select (0=10G, 1=25G, 2=40G, 3=50G, 4=100G)
  output logic       done,
  output logic [6:0] remaining
);

  //============================================================================
  // Module     : tx_ipg_timer_stage
  // Parameters :
  //   IPG_VALUE = 96 — Inter-packet gap in bit-times
  // Inputs     :
  //   clk       — Clock
  //   rst       — Reset (synchronous, active high)
  //   start     — Start IPG timer
  //   enable    — Enable counting
  //   tick      — Bit-time tick
  //   speed     — Speed select (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  // Outputs    :
  //   done       — IPG timer done
  //   remaining  — Remaining bit-times
  // Dependencies: mac_pkg
  // Timing    : 96 cycles at bit-time tick
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 4, Table 4-2; Annex 4A Table 4A-2
  //============================================================================

  import mac_pkg::*;
  logic active;

  always_ff @(posedge clk) begin
    if (rst) begin
      remaining <= '0;
      active    <= 1'b0;
    end else if (start) begin
      // ASSERT: IPG after frame end must be >= 96 bit-times (Clause 4)
      remaining <= IPG_VALUE;  // IPG_VALUE = 96 (Clause 4, Table 4-2)
      active    <= 1'b1;
    end else if (active && enable && tick) begin
      if (remaining == 1) begin
        remaining <= '0;
        active    <= 1'b0;
        // COVER: IPG timer expired
      end else
        remaining <= remaining - 1'b1;
    end
  end
  assign done = !active;

endmodule

`default_nettype wire