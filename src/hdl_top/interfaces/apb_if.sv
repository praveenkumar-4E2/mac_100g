//==============================================================================
// File       : rtl/interfaces/apb_if.sv
// Module     : apb_if
// Purpose    : APB3 master/slave contract for the MAC register boundary
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

interface apb_if (
  input logic clk,
  input logic rst
);
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [15:0] paddr;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;

  modport master_mp (
    input  clk, rst, prdata, pready, pslverr,
    output psel, penable, pwrite, paddr, pwdata
  );

  modport slave_mp (
    input  clk, rst, psel, penable, pwrite, paddr, pwdata,
    output prdata, pready, pslverr
  );

endinterface

`default_nettype wire