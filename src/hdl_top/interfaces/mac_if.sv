//==============================================================================
// File       : rtl/interfaces/mac_if.sv
// Interface  : mac_if
// Purpose    : Generic 512-bit streaming interface.
//
// Description:
//   Generic streaming beat interface used by Ethernet MAC datapaths.
//
//      RS  ---> MAC
//      MAC ---> RS
//      AXI ---> MAC
//      MAC ---> AXI
//
//   Lane-0 aligned
//   SOP = first beat
//   EOP = last beat
//   EOP_POS = valid bytes on final beat
//
//==============================================================================

`default_nettype none

interface mac_if #(
    parameter int unsigned DATA_WIDTH = 512,
    parameter int unsigned KEEP_WIDTH = DATA_WIDTH/8,
    parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH+1)
)(
    input logic clk,
    input logic rst
);

    //----------------------------------------------------------------------
    // Stream Signals
    //----------------------------------------------------------------------

    logic                  valid;
    logic                  ready;

    logic [DATA_WIDTH-1:0] data;
    logic [KEEP_WIDTH-1:0] keep;

    logic                  sop;
    logic                  eop;
    logic [EOP_POS_W-1:0]  eop_pos;

    logic                  error;
    logic                  fcs_present;

    //----------------------------------------------------------------------
    // Driver Clocking Block
    //----------------------------------------------------------------------

    clocking initiator_cb @(posedge clk);

        default input #1step output #0;

        output valid;
        output data;
        output keep;
        output sop;
        output eop;
        output eop_pos;
        output error;
        output fcs_present;

        input ready;

    endclocking

    //----------------------------------------------------------------------
    // Receiver Clocking Block
    //----------------------------------------------------------------------

    clocking target_cb @(posedge clk);

        default input #1step output #0;

        input valid;
        input data;
        input keep;
        input sop;
        input eop;
        input eop_pos;
        input error;
        input fcs_present;

        output ready;

    endclocking

    //----------------------------------------------------------------------
    // Passive Monitor Clocking Block
    //----------------------------------------------------------------------

    clocking monitor_cb @(posedge clk);

        default input #1step;

        input valid;
        input ready;

        input data;
        input keep;

        input sop;
        input eop;
        input eop_pos;

        input error;
        input fcs_present;

    endclocking

    //----------------------------------------------------------------------
    // Initiator Modport
    //----------------------------------------------------------------------

    modport initiator_mp (

        clocking initiator_cb,

        input clk,
        input rst

    );

    //----------------------------------------------------------------------
    // Target Modport
    //----------------------------------------------------------------------

    modport target_mp (

        clocking target_cb,

        input clk,
        input rst

    );

    //----------------------------------------------------------------------
    // Passive Monitor Modport
    //----------------------------------------------------------------------

    modport monitor_mp (

        clocking monitor_cb,

        input clk,
        input rst

    );

endinterface

`default_nettype wire