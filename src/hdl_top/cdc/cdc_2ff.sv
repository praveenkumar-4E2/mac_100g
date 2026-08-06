//==============================================================================
// File       : rtl/cdc/cdc_2ff.sv
// Module     : cdc_2ff
// Purpose    : Synchronize a single-bit level into the destination clock
//              domain using two destination-domain flip-flops
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module cdc_2ff (
  input  logic clk_dst,
  input  logic rst_dst,
  input  logic signal_src,
  output logic signal_dst
);

  //============================================================================
  // Module     : cdc_2ff
  // Parameters : (none)
  // Inputs     :
  //   clk_dst     — Destination clock
  //   rst_dst     — Destination reset (synchronous, active high)
  //   signal_src  — Source domain signal to synchronize
  // Outputs    :
  //   signal_dst  — Synchronized signal in destination domain
  // Dependencies: —
  // Timing    : 2 cycles
  // Reset     : synchronous, active high
  // Clock     : clk_dst
  //============================================================================

  logic sync_meta;

  always_ff @(posedge clk_dst) begin
    if (rst_dst) begin
      sync_meta  <= 1'b0;
      signal_dst <= 1'b0;
    end else begin
      sync_meta  <= signal_src;
      signal_dst <= sync_meta;
    end
  end

endmodule

`default_nettype wire