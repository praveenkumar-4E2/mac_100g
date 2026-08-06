//==============================================================================
// File       : rtl/integration/mac_rx_path.sv
// Module     : mac_rx_path
// Purpose    : Integration adapter for the active RX hierarchy — connects the
//              512-bit receive wire stream to mac_rx_top and derives
//              completed-frame status for Clause 31 control classification
// IEEE Ref   : IEEE 802.3 Clauses 3.2, 31, 4A
// Dependencies: mac_rx_top
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat contract
//==============================================================================

`default_nettype none

module mac_rx_path #(
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
  mac_if                      client_if,
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
  output logic                    busy,
  output logic                    control_frame_valid,
  output logic                    control_frame_error
);

  //============================================================================
  // Module     : mac_rx_path
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
  //   in_error             — Input error
  //   client_if            — Client stream interface (client_mp)
  //   local_addr           — Local MAC address
  //   promiscuous_en       — Promiscuous mode enable
  //   pause_en             — PAUSE enable
  //   max_frame_size       — Max frame size [15:0] (runtime)
  //   min_frame_size       — Min frame size [15:0] (runtime)
  //   group_addrs          — Group address table
  //   group_valid          — Group address valid bits
  // Outputs    :
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
  //   control_frame_valid  — Control frame valid
  //   control_frame_error  — Control frame error
  // Dependencies: mac_rx_top
  // Timing    : Frame length dependent
  // Reset     : synchronous, active high
  // Clock     : clk
  //============================================================================

  mac_rx_top #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_WIDTH       (KEEP_WIDTH),
    .EOP_POS_W        (EOP_POS_W),
    .GROUP_TABLE_SIZE (GROUP_TABLE_SIZE),
    .MAX_BODY_OCTETS  (MAX_BODY_OCTETS)
  ) rx_path_inst (
    .clk                 (clk),
    .rst                 (rst),
    .in_valid            (in_valid),
    .in_ready            (in_ready),
    .in_data             (in_data),
    .in_keep             (in_keep),
    .in_sop              (in_sop),
    .in_eop              (in_eop),
    .in_eop_pos          (in_eop_pos),
    .in_error            (in_error),
    .client              (client_if),
    .local_addr          (local_addr),
    .promiscuous_en      (promiscuous_en),
    .pause_en            (pause_en),
    .max_frame_size      (max_frame_size),
    .min_frame_size      (min_frame_size),
    .group_addrs         (group_addrs),
    .group_valid         (group_valid),
    .dest_addr           (dest_addr),
    .src_addr            (src_addr),
    .length_type         (length_type),
    .received_fcs        (received_fcs),
    .frame_valid         (frame_valid),
    .frame_drop          (frame_drop),
    .crc_error           (crc_error),
    .length_error        (length_error),
    .alignment_error     (alignment_error),
    .filter_hit          (filter_hit),
    .busy                (busy)
  );

  // Clause 31 classification consumes a completed, valid frame.
  // Keeping the state here prevents the structural top from owning
  // receive protocol state.
  always_ff @(posedge clk) begin
    if (rst) begin
      control_frame_valid <= 1'b0;
      control_frame_error <= 1'b0;
    end else begin
      if (frame_valid) begin
        control_frame_valid <= 1'b1;
        control_frame_error <= 1'b0;
      end else if (client_if.valid && client_if.ready && client_if.eop) begin
        control_frame_valid <= 1'b0;
      end
      if (frame_drop)
        control_frame_error <= 1'b1;
    end
  end

endmodule

`default_nettype wire
