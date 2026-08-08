//==============================================================================
// File       : mac_reset_if.sv
// Purpose    : One reset domain controlled and observed by the reusable reset
//              UVM agent.  One interface instance represents one reset signal.
//==============================================================================
`default_nettype none

interface mac_reset_if #(
  parameter bit INITIAL_RESET_VALUE = 1'b1
) (
  input logic clk
);
  logic rst = INITIAL_RESET_VALUE;

  clocking drv_cb @(posedge clk);
    default input #1step output #0;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #0;
    input rst;
  endclocking

  modport driver  (input clk, output rst);
  modport monitor (input clk, rst);
endinterface

`default_nettype wire
