//==============================================================================
// File       : rtl/tx/tx_pipeline.sv
// Module     : tx_pipeline
// Purpose    : Structural-only composition of TX admission, capture, framing, FCS,
//              and IPG stages. No frame protocol state is owned here.
// IEEE Ref   : IEEE 802.3 Annex 4A 4A.2.3.2.1-4A.2.3.2.3; Table 4A-2
// Dependencies: tx_ipg_timer_stage, tx_scheduler, tx_client_capture,
//               tx_frame_builder
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-4.3: Added speed input port for runtime speed configuration
//   2026-08-02 — Widened to 512-bit beat contract with keep/eop_pos
//==============================================================================

`default_nettype none

module tx_pipeline #(
  parameter int unsigned BUFFER_BYTES    = 2048,
  parameter int unsigned COUNT_WIDTH     = $clog2(BUFFER_BYTES + 1),
  parameter int unsigned DATA_WIDTH      = 512,
  parameter int unsigned KEEP_WIDTH      = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W       = $clog2(KEEP_WIDTH + 1),
  localparam int unsigned WORD_ADDR_WIDTH = $clog2(BUFFER_BYTES / KEEP_WIDTH)
) (
  input  logic                         clk,
  input  logic                         rst,
  input  logic                         start,
  output logic                         req_ready,
  input  logic [47:0]                  dest_addr,
  input  logic [47:0]                  src_addr,
  input  logic [15:0]                  length_type,
  input  logic                         client_valid,
  output logic                         client_ready,
  input  logic [DATA_WIDTH-1:0]        client_data,
  input  logic [KEEP_WIDTH-1:0]        client_keep,
  input  logic                         client_eop,
  input  logic [EOP_POS_W-1:0]         client_eop_pos,
  input  logic                         client_fcs_present,
  input  logic                         carrier_sense,
  input  logic                         collision_detect,
  input  logic                         tick,
  input  logic [2:0]                   speed,  // Speed select (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  output logic                         out_valid,
  input  logic                         out_ready,
  output logic [DATA_WIDTH-1:0]        out_data,
  output logic [KEEP_WIDTH-1:0]        out_keep,
  output logic                         out_sop,
  output logic                         out_eop,
  output logic [EOP_POS_W-1:0]         out_eop_pos,
  output logic                         out_error,
  output logic                         busy,
  output logic                         frame_done
);

  //============================================================================
  // Module     : tx_pipeline
  // Parameters :
  //   BUFFER_BYTES = 2048 — Client payload buffer size
  //   COUNT_WIDTH  = $clog2(BUFFER_BYTES + 1) — Count bit-width
  //   DATA_WIDTH   = 512 — Beat data width
  //   KEEP_WIDTH   = 64  — Byte-lane enable width
  //   EOP_POS_W    = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                — Clock
  //   rst                — Reset (synchronous, active high)
  //   start              — Frame start pulse
  //   dest_addr          — Destination MAC address
  //   src_addr           — Source MAC address
  //   length_type        — Length/Type field
  //   client_valid       — Client payload valid
  //   client_data        — Client payload beat
  //   client_keep        — Client payload byte enables
  //   client_eop         — Client payload end of frame
  //   client_eop_pos     — Client EOP valid-byte count
  //   client_fcs_present — Client supplies FCS
  //   carrier_sense      — Carrier sense
  //   collision_detect   — Collision detect
  //   tick               — Bit-time tick
  //   out_ready          — Output ready
  // Outputs    :
  //   req_ready          — Ready for new frame
  //   client_ready       — Client ready
  //   out_valid          — Output valid
  //   out_data           — Output beat
  //   out_keep           — Output byte enables
  //   out_sop            — Start of packet
  //   out_eop            — End of packet
  //   out_eop_pos        — EOP valid-byte count
  //   out_error          — Output error
  //   busy               — Pipeline busy
  //   frame_done         — Frame complete
  // Dependencies: tx_ipg_timer_stage, tx_scheduler, tx_client_capture,
  //               tx_frame_builder
  // Timing    : Variable (frame length dependent)
  // Reset     : synchronous, active high
  // Clock     : clk
  //============================================================================

  logic        builder_req_ready;
  logic        scheduled_start;
  logic        ipg_done;
  logic        capture_active;
  logic        capture_done;
  logic [COUNT_WIDTH-1:0] captured_bytes;
  logic [WORD_ADDR_WIDTH-1:0] capture_read_addr;
  logic [WORD_ADDR_WIDTH-1:0] capture_read_addr_1;
  logic [DATA_WIDTH-1:0] capture_read_data;
  logic [DATA_WIDTH-1:0] capture_read_data_1;
  logic [31:0] supplied_fcs;
  logic [6:0]  ipg_remaining;
  logic        end_of_frame;

  tx_ipg_timer_stage ipg_inst (
    .clk      (clk),
    .rst      (rst),
    .start    (end_of_frame),
    .enable   (1'b1),
    .tick     (tick),
    .speed    (speed),
    .done     (ipg_done),
    .remaining(ipg_remaining)
  );

  tx_scheduler scheduler_inst (
    .start              (start),
    .request_ready      (builder_req_ready && !capture_active),
    .ipg_done           (ipg_done),
    .accept_start       (scheduled_start),
    .request_ready_out  (req_ready)
  );

  tx_client_capture #(
    .BUFFER_BYTES (BUFFER_BYTES),
    .COUNT_WIDTH  (COUNT_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH),
    .KEEP_WIDTH   (KEEP_WIDTH),
    .EOP_POS_W    (EOP_POS_W)
  ) capture_inst (
    .clk               (clk),
    .rst               (rst),
    .start_capture     (scheduled_start),
    .client_valid      (client_valid),
    .client_data       (client_data),
    .client_keep       (client_keep),
    .client_eop        (client_eop),
    .client_eop_pos    (client_eop_pos),
    .client_ready      (client_ready),
    .capture_active    (capture_active),
    .capture_done      (capture_done),
    .captured_bytes    (captured_bytes),
    .supplied_fcs      (supplied_fcs),
    .read_addr         (capture_read_addr),
    .read_data         (capture_read_data),
    .read_addr_1       (capture_read_addr_1),
    .read_data_1       (capture_read_data_1)
  );

  tx_frame_builder #(
    .BUFFER_BYTES (BUFFER_BYTES),
    .COUNT_WIDTH  (COUNT_WIDTH),
    .DATA_WIDTH   (DATA_WIDTH),
    .KEEP_WIDTH   (KEEP_WIDTH),
    .EOP_POS_W    (EOP_POS_W)
  ) builder_inst (
    .clk                    (clk),
    .rst                    (rst),
    .start_capture          (scheduled_start),
    .req_ready              (builder_req_ready),
    .capture_done           (capture_done),
    .captured_bytes         (captured_bytes),
    .supplied_fcs           (supplied_fcs),
    .capture_read_addr      (capture_read_addr),
    .capture_read_data      (capture_read_data),
    .capture_read_addr_1    (capture_read_addr_1),
    .capture_read_data_1    (capture_read_data_1),
    .ready                  (out_ready),
    .dest_addr              (dest_addr),
    .src_addr               (src_addr),
    .length_type            (length_type),
    .client_fcs_present     (client_fcs_present),
    .out_valid              (out_valid),
    .out_data               (out_data),
    .out_keep               (out_keep),
    .out_sop                (out_sop),
    .out_eop                (out_eop),
    .out_eop_pos            (out_eop_pos),
    .out_error              (out_error),
    .busy                   (busy),
    .frame_done             (frame_done)
  );

  // Full-duplex legacy behavior ignores collision/carrier inputs. They remain
  // external compatibility ports until the integration PAUSE/deference owner
  // connects its admission policy at the scheduler boundary.
  assign end_of_frame = out_valid && out_ready && out_eop;

endmodule

`default_nettype wire
