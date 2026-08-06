`default_nettype none

//==============================================================================
// File       : rtl/primitives/bit_time_counter.sv
// Module     : bit_time_counter
// Purpose    : Count enabled bit-time opportunities up to a terminal value
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================
//
// Module     : bit_time_counter
// Parameters :
//   WIDTH         = 8 — Counter bit-width
//   TERMINAL_COUNT = {WIDTH{1'b1}} — Terminal count value
// Inputs     :
//   clk        — Clock
//   rst        — Reset (synchronous, active high)
//   clear      — Clear counter
//   enable     — Count enable
//   tick       — Bit-time tick
// Outputs    :
//   count      — Current count
//   terminal   — Terminal count reached
// Dependencies: —
// Timing    : 1 cycle
// Reset     : synchronous, active high
// Clock     : clk
//==============================================================================
module bit_time_counter #(
  parameter int WIDTH = 8,
  parameter logic [WIDTH-1:0] TERMINAL_COUNT = {WIDTH{1'b1}}
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             clear,
  input  logic             enable,
  input  logic             tick,
  output logic [WIDTH-1:0] count,
  output logic             terminal
);
  always_ff @(posedge clk) begin
    if (rst || clear) begin
      count <= '0;
    end else if (enable && tick && (count < TERMINAL_COUNT)) begin
      count <= count + 1'b1;
    end
  end

  always_comb begin
    terminal = (count == TERMINAL_COUNT);
  end
endmodule

`default_nettype wire
