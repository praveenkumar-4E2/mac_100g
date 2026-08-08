//==============================================================================
// File       : rtl/interfaces/apb_if.sv
// Module     : apb_if
// Purpose    : APB3 master/slave contract for the MAC register boundary
// IEEE Ref   : —
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-08 — Added TB-side clocking blocks for the APB UVM agent
//==============================================================================

`default_nettype none

interface apb_if (
  input logic clk,
  input logic rst
);
  // Master controls have one runtime owner: either the UVM APB master at the
  // external boundary or the continuous pin adapter inside mac_top.  Do not
  // initialize these variables here: an initializer is a procedural driver
  // and conflicts with mac_top's pin adapter in Questa.
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [15:0] paddr;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;

  // Driver clocking block (see mac_if.sv / axi4_stream_if.sv for the skew
  // rationale): inputs only — clocking-block outputs are implicit drivers in
  // QuestaSim and would conflict with RTL-connected instances. The APB driver
  // writes master signals with raw nonblocking assignments and samples the
  // slave handshake (prdata/pready/pslverr) and reset through drv_cb with the
  // #1step pre-edge skew, so driver and DUT always agree on completion.
  clocking drv_cb @(posedge clk);
    default input #1step output #0;
    input rst;
    input prdata, pready, pslverr;
  endclocking

  // Monitor clocking block: pre-edge (#1step) sampling only. The monitor
  // reconstructs transfers exclusively from mon_cb samples, so it observes
  // the exact pre-edge values the DUT's always_ff capture uses and can never
  // race a mid-cycle master drive or slave change.
  clocking mon_cb @(posedge clk);
    default input #1step output #0;
    input rst;
    input psel, penable, pwrite, paddr, pwdata, prdata, pready, pslverr;
  endclocking

  modport master_mp (
    input  clk, rst, prdata, pready, pslverr,
    output psel, penable, pwrite, paddr, pwdata
  );

  modport slave_mp (
    input  clk, rst, psel, penable, pwrite, paddr, pwdata,
    output prdata, pready, pslverr
  );

  `ifndef SYNTHESIS
    // Simulation-only APB protocol assertions at the interface boundary.
    // SVA samples pre-edge values, matching the drv_cb/mon_cb #1step skew.
    // A-10: an access phase can only begin from a preceding selected setup.
    // Only the first access edge is checked: a transfer held in wait states
    // legitimately has access-after-access edges.
    property access_requires_preceding_setup;
      @(posedge clk) disable iff (rst)
        (psel && penable && !$past(psel && penable)) |-> $past(psel && !penable);
    endproperty
    assert property (access_requires_preceding_setup)
      else $error("apb_if: access (PSEL&PENABLE) began without a preceding selected setup");

    // A-11: a selected setup retains PSEL when it progresses to access.
    property setup_retains_psel_into_access;
      @(posedge clk) disable iff (rst)
        (psel && !penable) |=> (psel && penable);
    endproperty
    assert property (setup_retains_psel_into_access)
      else $error("apb_if: selected setup did not retain PSEL into the access phase");

    // A-12: request controls stay stable for as long as the master keeps the
    // access waiting. A master that aborts (timeout/error idle drive, so the
    // access no longer holds at the next edge) is exempt.
    property access_controls_stable_while_waiting;
      @(posedge clk) disable iff (rst)
        (psel && penable && !pready) |=> (psel && penable) |-> $stable({psel, penable, pwrite, paddr, pwdata});
    endproperty
    assert property (access_controls_stable_while_waiting)
      else $error("apb_if: request controls changed during an access wait state");

    // A-13: while reset is asserted the master controls are quiescent (idle).
    // The $past(rst) term gives the master one clock to react to an injected
    // reset-during-transfer: the plan requires the bus to reach idle at the
    // next safe clock boundary, not in the very cycle reset first asserts.
    property reset_master_quiescent;
      @(posedge clk)
        (rst && $past(rst)) |-> (!psel && !penable);
    endproperty
    assert property (reset_master_quiescent)
      else $error("apb_if: master controls not idle while reset is asserted");
  `endif

endinterface

`default_nettype wire
