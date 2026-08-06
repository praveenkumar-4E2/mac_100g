//==============================================================================
// File       : rtl/cdc/cdc_pulse.sv
// Module     : cdc_pulse
// Purpose    : Transfer a source-domain pulse as a one-cycle destination pulse
//              through a toggle synchronizer
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module cdc_pulse (
  input  logic clk_src,
  input  logic rst_src,
  input  logic pulse_src,
  input  logic clk_dst,
  input  logic rst_dst,
  output logic pulse_dst
);

  //============================================================================
  // Module     : cdc_pulse
  // Parameters : (none)
  // Inputs     :
  //   clk_src   — Source clock
  //   rst_src   — Source reset (synchronous, active high)
  //   pulse_src — Source domain pulse
  //   clk_dst   — Destination clock
  //   rst_dst   — Destination reset (synchronous, active high)
  // Outputs    :
  //   pulse_dst — Destination domain pulse (one cycle)
  // Dependencies: —
  // Timing    : 2 cycles
  // Reset     : synchronous, active high
  // Clock     : clk_src / clk_dst — asynchronous domains
  //============================================================================

  logic toggle_src;
  logic sync1;
  logic sync2;
  logic seen;

  always_ff @(posedge clk_src) begin
    if (rst_src) begin
      toggle_src <= 1'b0;
    end else if (pulse_src) begin
      toggle_src <= ~toggle_src;
    end
  end

  always_ff @(posedge clk_dst) begin
    if (rst_dst) begin
      sync1     <= 1'b0;
      sync2     <= 1'b0;
      seen      <= 1'b0;
      pulse_dst <= 1'b0;
    end else begin
      sync1     <= toggle_src;
      sync2     <= sync1;
      pulse_dst <= sync2 ^ seen;
      seen      <= sync2;
    end
  end

endmodule

`default_nettype wire