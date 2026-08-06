//==============================================================================
// File       : rtl/tx/mac_tx_top.sv
// Module     : mac_tx_top
// Purpose    : Active structural TX composition boundary
// IEEE Ref   : IEEE 802.3 Clauses 2.3.1-2.3.2, 3.2.1-3.2.9, 4A
// Dependencies: tx_pipeline, mac_if
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-4.3: Added speed input port for runtime speed configuration
//   2026-08-02 — Widened to 512-bit beat output with keep/eop_pos
//==============================================================================

`default_nettype none

module mac_tx_top #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        start,
  output logic        req_ready,
  input  logic [47:0] dest_addr,
  input  logic [47:0] src_addr,
  input  logic [15:0] length_type,
  mac_if.mac_mp       client_if,
  input  logic        carrier_sense,
  input  logic        collision_detect,
  input  logic        tick,
  input  logic [2:0]  speed,  // Speed select (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  output logic        out_valid,
  input  logic        out_ready,
  output logic [DATA_WIDTH-1:0] out_data,
  output logic [KEEP_WIDTH-1:0] out_keep,
  output logic        out_sop,
  output logic        out_eop,
  output logic [EOP_POS_W-1:0]  out_eop_pos,
  output logic        out_error,
  output logic        busy,
  output logic        frame_done
);

  //============================================================================
  // Module     : mac_tx_top
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                — Clock
  //   rst                — Reset (synchronous, active high)
  //   start              — Frame start pulse
  //   dest_addr          — Destination MAC address
  //   src_addr           — Source MAC address
  //   length_type        — Length/Type field
  //   client_if          — Client stream interface (mac_mp modport)
  //   carrier_sense      — Carrier sense
  //   collision_detect   — Collision detect
  //   tick               — Bit-time tick
  //   out_ready          — Output ready
  // Outputs    :
  //   req_ready          — Ready for new frame
  //   out_valid          — Output valid
  //   out_data           — Output beat data
  //   out_keep           — Output beat byte enables
  //   out_sop            — Start of packet
  //   out_eop            — End of packet
  //   out_eop_pos        — EOP valid-byte count
  //   out_error          — Output error
  //   busy               — Pipeline busy
  //   frame_done         — Frame complete pulse
  // Dependencies: tx_pipeline
  // Timing    : Variable (frame length dependent)
  // Reset     : synchronous, active high
  // Clock     : clk
  //============================================================================

  // Clause 2 MA_DATA.request is represented by client_if.  The frame request
  // metadata remains a separate Layer-2 control transaction while the client
  // data, end-of-frame, and optional supplied-FCS indication use the stream.
  tx_pipeline pipeline_inst (
    .clk                    (clk),
    .rst                    (rst),
    .start                  (start),
    .req_ready              (req_ready),
    .dest_addr              (dest_addr),
    .src_addr               (src_addr),
    .length_type            (length_type),
    .client_valid           (client_if.valid),
    .client_ready           (client_if.ready),
    .client_data            (client_if.data),
    .client_keep            (client_if.keep),
    .client_eop             (client_if.eop),
    .client_eop_pos         (client_if.eop_pos),
    .client_fcs_present     (client_if.fcs_present),
    .carrier_sense          (carrier_sense),
    .collision_detect       (collision_detect),
    .tick                   (tick),
    .speed                  (speed),
    .out_valid              (out_valid),
    .out_ready              (out_ready),
    .out_data               (out_data),
    .out_keep               (out_keep),
    .out_sop                (out_sop),
    .out_eop                (out_eop),
    .out_eop_pos            (out_eop_pos),
    .out_error              (out_error),
    .busy                   (busy),
    .frame_done             (frame_done)
  );

  `ifndef SYNTHESIS
    // A stalled client beat is an interface transaction and must not be
    // rewritten until the MAC accepts it.  SOP/EOP/FCS are transaction fields.
    property client_beat_stable_while_stalled;
      @(posedge clk) disable iff (rst)
        client_if.valid && !client_if.ready |=>
        client_if.valid && $stable({ client_if.data, client_if.keep,
                                     client_if.sop, client_if.eop,
                                     client_if.eop_pos, client_if.error,
                                     client_if.fcs_present });
    endproperty
    assert property (client_beat_stable_while_stalled)
      else $error("mac_tx_top client interface changed while stalled");
  `endif

endmodule

`default_nettype wire