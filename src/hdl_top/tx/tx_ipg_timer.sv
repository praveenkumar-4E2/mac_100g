//==============================================================================
// File       : rtl/tx/tx_ipg_timer.sv
// Module     : tx_ipg_timer_stage
// Purpose    : Active TX-path owner of the 96 bit-time interpacket-gap state
// IEEE Ref   : IEEE 802.3ba Clause 4 Table 4-2; Annex 4A Table 4A-2
// Dependencies: mac_pkg, mac_speed_params_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-4.3: Added speed input port for runtime speed configuration
//   2026-08-07 — W4: reload value selected per speed via
//                mac_speed_params_pkg::tx_ipg_for_speed (96 bit-times at every
//                supported speed per Clause 4 Table 4-2)
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
  input  logic [2:0] speed,  // Speed select (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  output logic       done,
  output logic [6:0] remaining
);

  //============================================================================
  // Module     : tx_ipg_timer_stage
  // Parameters :
  //   IPG_VALUE = 96 — Inter-packet gap in bit-times (Clause 4 Table 4-2)
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
  // Dependencies: mac_pkg, mac_speed_params_pkg
  // Timing    : 96 cycles at bit-time tick
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 4, Table 4-2; Annex 4A Table 4A-2
  //============================================================================

  import mac_pkg::*;
  import mac_speed_params_pkg::*;
  logic active;

  // W4: the IPG reload value follows the effective speed policy. Per Clause 4
  // Table 4-2 the IPG is 96 bit-times at every supported speed, so the speed
  // input is consumed (not dead) and remains wired to effective_mac_speed.
  logic [6:0] ipg_reload;
  assign ipg_reload = 7'(tx_ipg_for_speed(int'(speed)));

  always_ff @(posedge clk) begin
    if (rst) begin
      remaining <= '0;
      active    <= 1'b0;
    end else if (start) begin
      remaining <= ipg_reload;  // 96 bit-times (Clause 4, Table 4-2)
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