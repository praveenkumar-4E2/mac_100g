//==============================================================================
// File       : rtl/rx/rx_pipeline.sv
// Module     : rx_pipeline
// Purpose    : Structural connection layer for the 512-bit RX behavioral stages
// IEEE Ref   : IEEE 802.3 Clauses 3.2.1-3.2.9, 4A
// Dependencies: rx_preamble_detect, rx_header_extract, rx_crc_check,
//               rx_length_check, rx_frame_emit
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat contract
//==============================================================================

`default_nettype none

module rx_pipeline #(
  parameter int unsigned DATA_WIDTH       = 512,
  parameter int unsigned KEEP_WIDTH       = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W        = $clog2(KEEP_WIDTH + 1),
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
  input  logic                    in_fcs_present,
  input  logic                    filter_accept,
  input  logic [15:0]             max_frame_size,
  input  logic [15:0]             min_frame_size,
  output logic                    client_valid,
  input  logic                    client_ready,
  output logic [DATA_WIDTH-1:0]   client_data,
  output logic [KEEP_WIDTH-1:0]   client_keep,
  output logic                    client_sop,
  output logic                    client_eop,
  output logic [EOP_POS_W-1:0]    client_eop_pos,
  output logic                    client_error,
  output logic                    client_fcs_present,
  output logic [47:0]             dest_addr,
  output logic [47:0]             src_addr,
  output logic [15:0]             length_type,
  output logic [31:0]             received_fcs,
  output logic [47:0]             filter_dest_addr,
  output logic                    frame_valid,
  output logic                    frame_drop,
  output logic                    crc_error,
  output logic                    length_error,
  output logic                    alignment_error,
  output logic                    filter_hit,
  output logic                    busy
);

  //============================================================================
  // Module     : rx_pipeline
  // Parameters :
  //   DATA_WIDTH      = 512 — Beat data width
  //   KEEP_WIDTH      = 64  — Byte-lane enable width
  //   MAX_BODY_OCTETS = 2048 — Maximum body octets to buffer
  // Inputs     :
  //   clk              — Clock
  //   rst              — Reset (synchronous, active high)
  //   in_valid         — Input beat valid
  //   in_data          — Input beat data
  //   in_keep          — Input beat byte enables
  //   in_sop           — Input beat SOP
  //   in_eop           — Input beat EOP
  //   in_eop_pos       — Input EOP valid-byte count
  //   in_error         — Input frame error
  //   filter_accept    — Address filter accept
  //   max_frame_size   — Max frame size [15:0] (runtime)
  //   min_frame_size   — Min frame size [15:0] (runtime)
  //   client_ready     — Client ready
  // Outputs    :
  //   in_ready         — Input ready
  //   client_valid     — Client beat valid
  //   client_data      — Client beat data
  //   client_keep      — Client beat byte enables
  //   client_sop       — Client beat SOP
  //   client_eop       — Client beat EOP
  //   client_eop_pos   — Client EOP valid-byte count
  //   client_error     — Client beat error
  //   client_fcs_present — Client FCS present
  //   dest_addr        — Destination MAC address
  //   src_addr         — Source MAC address
  //   length_type      — Length/Type field
  //   received_fcs     — Received FCS
  //   filter_dest_addr — Filter destination address
  //   frame_valid      — Frame valid
  //   frame_drop       — Frame dropped
  //   crc_error        — CRC error
  //   length_error     — Length error
  //   alignment_error  — Alignment error
  //   filter_hit       — Filter hit
  //   busy             — Pipeline busy
  // Dependencies: rx_preamble_detect, rx_header_extract, rx_crc_check,
  //               rx_length_check, rx_frame_emit
  // Timing    : Variable (frame length dependent)
  // Reset     : synchronous, active high
  // Clock     : clk
  //============================================================================

  logic                            pre_stage_valid;
  logic                            pre_stage_ready;
  logic [DATA_WIDTH-1:0]           pre_stage_data;
  logic [KEEP_WIDTH-1:0]           pre_stage_keep;
  logic                            pre_stage_sop;
  logic                            pre_stage_eop;
  logic [EOP_POS_W-1:0]            pre_stage_eop_pos;
  logic                            pre_stage_error;
  logic                            pre_stage_fcs_present;
  logic                            header_ready;
  logic                            header_done;
  logic                            header_done_ready;
  logic [47:0]                     header_dest_addr;
  logic [47:0]                     header_src_addr;
  logic [15:0]                     header_length_type;
  logic                            crc_ready;
  logic                            crc_done;
  logic                            crc_done_ready;
  logic                            crc_good;
  logic                            crc_error_int;
  logic [31:0]                     crc_received_fcs;
  logic                            length_ready;
  logic                            length_done;
  logic                            length_done_ready;
  logic                            length_good;
  logic                            length_error_int;
  logic                            length_alignment_error;
  logic                            length_oversize_error;
  logic                            length_undersize_error;
  logic [11:0]                     length_payload_octets;
  logic                            emit_ready;

  // ASSERT: Data stable when in_valid asserted (in_data changes only on handshake)
  rx_preamble_detect #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) preamble_inst (
    .clk          (clk),
    .rst          (rst),
    .in_valid     (in_valid),
    .in_ready     (in_ready),
    .in_data      (in_data),
    .in_keep      (in_keep),
    .in_sop       (in_sop),
    .in_eop       (in_eop),
    .in_eop_pos   (in_eop_pos),
    .in_error     (in_error),
    .in_fcs_present (in_fcs_present),
    .out_valid    (pre_stage_valid),
    .out_ready    (pre_stage_ready),
    .out_data     (pre_stage_data),
    .out_keep     (pre_stage_keep),
    .out_sop      (pre_stage_sop),
    .out_eop      (pre_stage_eop),
    .out_eop_pos  (pre_stage_eop_pos),
    .out_error    (pre_stage_error),
    .out_fcs_present (pre_stage_fcs_present)
  );

  // The four consumers observe the same normalized frame atomically.
  assign pre_stage_ready = header_ready && crc_ready && length_ready && emit_ready;

  // ASSERT: Pipeline stall timeout — if in_valid && in_ready, pipeline must not stall indefinitely
  // COVER: CRC failure triggers frame drop
  // COVER: Length error triggers frame drop

  rx_header_extract #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) header_inst (
    .clk                 (clk),
    .rst                 (rst),
    .in_valid            (pre_stage_valid),
    .in_ready            (header_ready),
    .in_data             (pre_stage_data),
    .in_keep             (pre_stage_keep),
    .in_sop              (pre_stage_sop),
    .in_eop              (pre_stage_eop),
    .in_eop_pos          (pre_stage_eop_pos),
    .in_error            (pre_stage_error),
    .frame_done          (header_done),
    .frame_done_ready    (header_done_ready),
    .dest_addr           (header_dest_addr),
    .src_addr            (header_src_addr),
    .length_type         (header_length_type)
  );

  // Export header-stage DA solely for the top-level address-filter decision.
  assign filter_dest_addr = header_dest_addr;

  rx_crc_check #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) crc_inst (
    .clk                (clk),
    .rst                (rst),
    .in_valid           (pre_stage_valid),
    .in_ready           (crc_ready),
    .in_data            (pre_stage_data),
    .in_keep            (pre_stage_keep),
    .in_sop             (pre_stage_sop),
    .in_eop              (pre_stage_eop),
    .in_eop_pos          (pre_stage_eop_pos),
    .in_error            (pre_stage_error),
    .in_fcs_present      (pre_stage_fcs_present),
    .frame_done          (crc_done),
    .frame_done_ready   (crc_done_ready),
    .crc_good           (crc_good),      // COVER: CRC check passed
    .crc_error          (crc_error_int), // COVER: CRC error detected
    .received_fcs       (crc_received_fcs)
  );

  rx_length_check #(
    .DATA_WIDTH (DATA_WIDTH),
    .KEEP_WIDTH (KEEP_WIDTH),
    .EOP_POS_W  (EOP_POS_W)
  ) length_inst (
    .clk                 (clk),
    .rst                 (rst),
    .in_valid            (pre_stage_valid),
    .in_ready            (length_ready),
    .in_data             (pre_stage_data),
    .in_keep             (pre_stage_keep),
    .in_sop              (pre_stage_sop),
    .in_eop              (pre_stage_eop),
    .in_eop_pos          (pre_stage_eop_pos),
    .in_error            (pre_stage_error),
    .in_fcs_present      (pre_stage_fcs_present),
    .max_frame_size      (max_frame_size),
    .min_frame_size      (min_frame_size),
    .frame_done          (length_done),
    .frame_done_ready    (length_done_ready),
    .length_good         (length_good),
    .length_error        (length_error_int),
    .alignment_error     (length_alignment_error),
    .oversize_error      (length_oversize_error),
    .undersize_error     (length_undersize_error),
    .payload_octets      (length_payload_octets)
  );

  rx_frame_emit #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_WIDTH       (KEEP_WIDTH),
    .EOP_POS_W        (EOP_POS_W),
    .MAX_BODY_OCTETS  (MAX_BODY_OCTETS)
  ) emit_inst (
    .clk                    (clk),
    .rst                    (rst),
    .in_valid               (pre_stage_valid),
    .in_ready               (emit_ready),
    .in_data                (pre_stage_data),
    .in_keep                (pre_stage_keep),
    .in_sop                 (pre_stage_sop),
    .in_eop                 (pre_stage_eop),
    .in_eop_pos             (pre_stage_eop_pos),
    .in_error               (pre_stage_error),
    .header_done            (header_done),
    .header_done_ready      (header_done_ready),
    .header_dest_addr       (header_dest_addr),
    .header_src_addr        (header_src_addr),
    .header_length_type     (header_length_type),
    .crc_done               (crc_done),
    .crc_done_ready         (crc_done_ready),
    .crc_good               (crc_good),
    .crc_error_in           (crc_error_int),
    .received_fcs_in        (crc_received_fcs),
    .length_done            (length_done),
    .length_done_ready      (length_done_ready),
    .length_good            (length_good),
    .length_error_in        (length_error_int),
    .alignment_error_in     (length_alignment_error),
    .payload_octets_in      (length_payload_octets),
    .filter_accept          (filter_accept),
    .max_frame_size         (max_frame_size),
    .client_valid           (client_valid),
    .client_ready           (client_ready),
    .client_data            (client_data),
    .client_keep            (client_keep),
    .client_sop             (client_sop),
    .client_eop             (client_eop),
    .client_eop_pos         (client_eop_pos),
    .client_error           (client_error),
    .client_fcs_present     (client_fcs_present),
    .dest_addr              (dest_addr),
    .src_addr               (src_addr),
    .length_type            (length_type),
    .received_fcs           (received_fcs),
    .frame_valid            (frame_valid), // COVER: Frame accepted for delivery
    .frame_drop             (frame_drop),  // COVER: Frame dropped
    .crc_error              (crc_error),
    .length_error           (length_error),
    .alignment_error        (alignment_error),
    .filter_hit             (filter_hit),
    .busy                   (busy)
  );

endmodule

`default_nettype wire
