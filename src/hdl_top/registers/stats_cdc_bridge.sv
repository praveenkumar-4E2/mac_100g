//==============================================================================
// File       : rtl/registers/stats_cdc_bridge.sv
// Module     : stats_cdc_bridge
// Purpose    : Request-toggle APB status snapshot via CDC handshake
// IEEE Ref   : —
// Dependencies: cdc_2ff, cdc_handshake
// Author     : —
// Revision History:
//   2026-07-28 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module stats_cdc_bridge #(
  parameter int unsigned WIDTH = 384
) (
  input  logic        apb_clk,
  input  logic        apb_rst,
  input  logic        mac_clk,
  input  logic        mac_rst,
  input  logic        request_apb,
  input  logic [WIDTH-1:0] snapshot_mac,
  output logic        ack_apb,
  output logic [WIDTH-1:0] snapshot_apb
);

  //============================================================================
  // Module     : stats_cdc_bridge
  // Parameters :
  //   WIDTH = 384 — Snapshot data width (3 * 128-bit counters)
  // Inputs    :
  //   apb_clk      — APB clock domain
  //   apb_rst      — APB reset (synchronous, active high)
  //   mac_clk      — MAC clock domain
  //   mac_rst      — MAC reset (synchronous, active high)
  //   request_apb  — APB domain request toggle
  //   snapshot_mac — MAC domain snapshot data
  // Outputs   :
  //   ack_apb       — APB domain ack (mirrors requested epoch)
  //   snapshot_apb  — APB domain snapshot data
  // Dependencies: cdc_2ff, cdc_handshake
  // Timing    : 1-cycle sync, 1-cycle CDC, 1-cycle APB domain
  // Reset     : synchronous, active high
  // Clock     : apb_clk / mac_clk — asynchronous domains
  //============================================================================

  logic req_mac;
  logic req_seen;
  logic pending;
  logic send;
  logic ready;
  logic valid;
  logic [WIDTH:0] source_bundle;
  logic [WIDTH:0] dest_bundle;

  cdc_2ff req_sync_inst (
    .clk_dst   (mac_clk),
    .rst_dst   (mac_rst),
    .signal_src (request_apb),
    .signal_dst (req_mac)
  );

  always_ff @(posedge mac_clk) begin
    if (mac_rst) begin
      req_seen <= 1'b0;
      pending  <= 1'b0;
      send     <= 1'b0;
    end else begin
      send <= 1'b0;
      if (req_mac != req_seen) begin
        req_seen <= req_mac;
        pending  <= 1'b1;
      end
      if (pending && ready) begin
        send    <= 1'b1;
        pending <= 1'b0;
      end
    end
  end

  assign source_bundle = { req_seen, snapshot_mac };

  cdc_handshake #(
    .WIDTH (WIDTH + 1)
  ) snapshot_cdc_inst (
    .clk_src   (mac_clk),
    .rst_src   (mac_rst),
    .req_src   (send),
    .data_src  (source_bundle),
    .ready_src (ready),
    .clk_dst   (apb_clk),
    .rst_dst   (apb_rst),
    .valid_dst (valid),
    .data_dst  (dest_bundle),
    .ack_dst   (valid)
  );

  always_ff @(posedge apb_clk) begin
    if (apb_rst) begin
      ack_apb      <= 1'b0;
      snapshot_apb <= '0;
    end else if (valid) begin
      { ack_apb, snapshot_apb } <= dest_bundle;
    end
  end

endmodule

`default_nettype wire