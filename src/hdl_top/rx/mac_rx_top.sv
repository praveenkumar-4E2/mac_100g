//==============================================================================
// File       : rtl/rx/mac_rx_top.sv
// Module     : mac_rx_top
// Purpose    : Active RX composition boundary — accepts the 512-bit wire beat
//              stream, applies destination filtering, and presents accepted
//              client data through mac_if after RX pipeline validates the frame
// IEEE Ref   : IEEE 802.3 Clauses 3.2.1-3.2.9, 4A
// Dependencies: address_filter, rx_pipeline
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat contract
//==============================================================================

`default_nettype none

module mac_rx_top #(
  parameter int unsigned DATA_WIDTH       = 512,
  parameter int unsigned KEEP_WIDTH       = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W        = $clog2(KEEP_WIDTH + 1),
  parameter int unsigned GROUP_TABLE_SIZE = 4,
  parameter int unsigned MAX_BODY_OCTETS  = 2048
) (
  input  logic                    clk,
  input  logic                    rst,
  input  logic                    in_valid,
  output logic                    in_ready,
  input  logic [DATA_WIDTH-1:0]   in_data,
  input  logic [KEEP_WIDTH-1:0]   in_keep,
  input  logic                    in_sop,
  input  logic                    in_eop,
  input  logic [EOP_POS_W-1:0]    in_eop_pos,
  input  logic                    in_error,
  mac_if.client_mp                client,
  input  logic [47:0]             local_addr,
  input  logic                    promiscuous_en,
  input  logic                    pause_en,
  input  logic [15:0]             max_frame_size,
  input  logic [15:0]             min_frame_size,
  input  logic [47:0]             group_addrs [GROUP_TABLE_SIZE],
  input  logic                    group_valid [GROUP_TABLE_SIZE],
  output logic [47:0]             dest_addr,
  output logic [47:0]             src_addr,
  output logic [15:0]             length_type,
  output logic [31:0]             received_fcs,
  output logic                    frame_valid,
  output logic                    frame_drop,
  output logic                    crc_error,
  output logic                    length_error,
  output logic                    alignment_error,
  output logic                    filter_hit,
  output logic                    busy
);

  //============================================================================
  // Module     : mac_rx_top
  // Parameters :
  //   DATA_WIDTH      = 512 — Beat data width
  //   KEEP_WIDTH      = 64  — Byte-lane enable width
  //   GROUP_TABLE_SIZE = 4  — Number of group address filter entries
  // Inputs     :
  //   clk                  — Clock
  //   rst                  — Reset (synchronous, active high)
  //   in_valid             — Input beat valid
  //   in_data              — Input beat data
  //   in_keep              — Input beat byte enables
  //   in_sop               — Input beat SOP
  //   in_eop               — Input beat EOP
  //   in_eop_pos           — Input EOP valid-byte count
  //   in_error             — Input error flag
  //   local_addr           — Local MAC address
  //   promiscuous_en       — Promiscuous mode enable
  //   pause_en             — PAUSE enable
  //   max_frame_size       — Max frame size [15:0] (runtime)
  //   min_frame_size       — Min frame size [15:0] (runtime)
  //   group_addrs          — Group address table
  //   group_valid          — Group address valid bits
  //   client.ready         — Client ready
  // Outputs    :
  //   in_ready             — Input ready
  //   client.valid         — Client beat valid
  //   client.data          — Client beat data
  //   client.keep          — Client beat byte enables
  //   client.sop           — Client beat SOP
  //   client.eop           — Client beat EOP
  //   client.eop_pos       — Client EOP valid-byte count
  //   client.error         — Client beat error
  //   client.fcs_present   — Client FCS present
  //   dest_addr            — Destination MAC address
  //   src_addr             — Source MAC address
  //   length_type          — Length/Type field
  //   received_fcs         — Received FCS
  //   frame_valid          — Frame valid
  //   frame_drop           — Frame dropped
  //   crc_error            — CRC error
  //   length_error         — Length error
  //   alignment_error      — Alignment error
  //   filter_hit           — Address filter hit
  //   busy                 — Pipeline busy
  // Dependencies: address_filter, rx_pipeline
  // Timing    : Frame length dependent
  // Reset     : synchronous, active high
  // Clock     : clk
  //============================================================================

  logic                     filter_accept;
  logic [47:0]              filter_dest_addr;
  logic                     client_valid;
  logic [DATA_WIDTH-1:0]    client_data;
  logic [KEEP_WIDTH-1:0]    client_keep;
  logic                     client_sop;
  logic                     client_eop;
  logic [EOP_POS_W-1:0]     client_eop_pos;
  logic                     client_error;
  logic                     client_fcs_present;

  // This is the active Clause 2 client-indication boundary.  RX removes the
  // wire FCS before delivery, and only emits accepted frames, so neither
  // optional client-side indication is asserted in the current beat contract.
  assign client.valid       = client_valid;
  assign client.data        = client_data;
  assign client.keep        = client_keep;
  assign client.sop         = client_sop;
  assign client.eop         = client_eop;
  assign client.eop_pos     = client_eop_pos;
  assign client.error       = client_error;
  assign client.fcs_present = client_fcs_present;

  address_filter #(
    .GROUP_TABLE_SIZE (GROUP_TABLE_SIZE)
  ) destination_filter (
    .local_addr   (local_addr),
    .dest_addr    (filter_dest_addr),
    .promiscuous_en (promiscuous_en),
    .pause_en       (pause_en),
    .group_addrs    (group_addrs),
    .group_valid    (group_valid),
    .accept         (filter_accept)
  );

  rx_pipeline #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_WIDTH       (KEEP_WIDTH),
    .EOP_POS_W        (EOP_POS_W),
    .MAX_BODY_OCTETS  (MAX_BODY_OCTETS)
  ) pipeline_inst (
    .clk                  (clk),
    .rst                  (rst),
    .in_valid             (in_valid),
    .in_ready             (in_ready),
    .in_data              (in_data),
    .in_keep              (in_keep),
    .in_sop               (in_sop),
    .in_eop               (in_eop),
    .in_eop_pos           (in_eop_pos),
    .in_error             (in_error),
    .filter_accept        (filter_accept),
    .max_frame_size       (max_frame_size),
    .min_frame_size       (min_frame_size),
    .client_valid         (client_valid),
    .client_ready         (client.ready),
    .client_data          (client_data),
    .client_keep          (client_keep),
    .client_sop           (client_sop),
    .client_eop           (client_eop),
    .client_eop_pos       (client_eop_pos),
    .client_error         (client_error),
    .client_fcs_present   (client_fcs_present),
    .dest_addr            (dest_addr),
    .src_addr             (src_addr),
    .length_type          (length_type),
    .received_fcs         (received_fcs),
    .frame_valid          (frame_valid),
    .filter_dest_addr     (filter_dest_addr),
    .frame_drop           (frame_drop),
    .crc_error            (crc_error),
    .length_error         (length_error),
    .alignment_error      (alignment_error),
    .filter_hit           (filter_hit),
    .busy                 (busy)
  );

endmodule

`default_nettype wire
