//==============================================================================
// File       : rtl/control/mac_control_top.sv
// Module     : mac_control_top
// Purpose    : Consume valid MAC Control payloads, classify their opcode, and
//              pass valid non-control frames to the Clause 2 client boundary
// IEEE Ref   : IEEE 802.3 Clause 2, Clause 31.4.1.3, Annex 31A
// Dependencies: control_classifier
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-2.5: Added IEEE Annex 31B reference and PAUSE TX trigger flow docs
//   2026-07-29 — T-7.4: Added IEEE Clause 31.4.1.3 reference for unsupported opcode detection
//   2026-08-02 — Widened to 512-bit beat payload/client contract
//==============================================================================

`default_nettype none

module mac_control_top #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                        clk,
  input  logic                        rst,
  input  logic                        frame_valid,
  input  logic                        frame_error,
  input  logic [47:0]                 dest_addr,
  input  logic [47:0]                 src_addr,
  input  logic [15:0]                 length_type,
  input  logic [47:0]                 local_addr,
  input  logic                        payload_valid,
  output logic                        payload_ready,
  input  logic [DATA_WIDTH-1:0]       payload_data,
  input  logic [KEEP_WIDTH-1:0]       payload_keep,
  input  logic                        payload_sop,
  input  logic                        payload_eop,
  input  logic [EOP_POS_W-1:0]        payload_eop_pos,
  output logic                        client_valid,
  input  logic                        client_ready,
  output logic [DATA_WIDTH-1:0]       client_data,
  output logic [KEEP_WIDTH-1:0]       client_keep,
  output logic                        client_sop,
  output logic                        client_eop,
  output logic [EOP_POS_W-1:0]        client_eop_pos,
  output logic                        control_event_valid,
  output logic [15:0]                 control_opcode,
  output logic [47:0]                 control_dest_addr,
  output logic [47:0]                 control_src_addr,
  output logic                        control_param_valid,
  output logic [DATA_WIDTH-1:0]       control_param_data,
  output logic                        control_param_eop,
  output logic                        unsupported_control,
  output logic [15:0]                 pause_time
);

  //============================================================================
  // Module     : mac_control_top
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                — Clock
  //   rst                — Reset (synchronous, active high)
  //   frame_valid        — Frame valid
  //   frame_error        — Frame error flag
  //   dest_addr          — Destination MAC address
  //   src_addr           — Source MAC address
  //   length_type        — Length/Type field
  //   local_addr         — Local MAC address
  //   payload_valid      — Payload beat valid
  //   payload_data       — Payload beat
  //   payload_keep       — Payload beat byte enables
  //   payload_sop        — Start of payload
  //   payload_eop        — End of payload
  //   payload_eop_pos    — EOP valid-byte count
  //   client_ready       — Client ready
  // Outputs    :
  //   payload_ready          — Payload ready
  //   client_valid           — Client frame valid
  //   client_data            — Client frame beat
  //   client_keep            — Client frame beat byte enables
  //   client_sop             — Client frame SOP
  //   client_eop             — Client frame EOP
  //   client_eop_pos         — Client EOP valid-byte count
  //   control_event_valid    — Control frame event valid
  //   control_opcode         — Control frame opcode
  //   control_dest_addr      — Control frame dest addr
  //   control_src_addr       — Control frame src addr
  //   control_param_valid    — Control param valid
  //   control_param_data     — Control param beat
  //   control_param_eop      — Control param EOP
  //   unsupported_control    — Unsupported control opcode
  //   pause_time             — PAUSE time value (Annex 31B.1)
  // Dependencies: control_classifier
  // Timing    : 1 cycle per payload beat; 1-cycle decode on SOP beat
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 2, 31.4.1.3, Annex 31A, Annex 31B
  //
  // PAUSE TX Trigger Flow (IEEE 802.3 Annex 31B.2):
  //   - PAUSE TX trigger is generated in mac_top.sv:
  //     pause_tx_req_valid = cfg_pause_tx_soft_req || pause_timer_done
  //   - cfg_pause_tx_enable gates pause_tx pause_req_ready
  //   - pause_tx_pending status feedback: req_valid && !req_ready
  //   - This module handles RX-side PAUSE frame decoding only
  //
  // Beat layout for MAC Control payload (lane 0 = first transmitted byte):
  //   lanes 0-1  : Opcode (opcode_high in lane 0)
  //   lanes 2-3  : PAUSE time (high byte in lane 2)
  //   lanes 4+   : Control parameters / pad
  //============================================================================

  import pause_pkg::*;

  logic       is_control;
  logic       payload_beat;

  control_classifier classifier_inst (
    .length_type (length_type),
    .is_control  (is_control)
  );

  // Valid-byte count of the current beat.
  function automatic logic [EOP_POS_W-1:0] beat_bytes(
    input logic                 eop,
    input logic [EOP_POS_W-1:0] eop_pos
  );
    beat_bytes = eop ? eop_pos : EOP_POS_W'(KEEP_WIDTH);
  endfunction

  assign payload_beat  = payload_valid && payload_ready;
  assign payload_ready = frame_valid && !frame_error && (is_control || client_ready);
  assign client_valid  = payload_valid && frame_valid && !frame_error && !is_control;
  assign client_data   = payload_data;
  assign client_keep   = payload_keep;
  assign client_sop    = client_valid && payload_sop;
  assign client_eop    = client_valid && payload_eop;
  assign client_eop_pos = payload_eop_pos;
  assign control_dest_addr = dest_addr;
  assign control_src_addr  = src_addr;

  // Clause 2 delivery is only for valid non-MAC-Control frames. Clause 31
  // frames are consumed here and decoded into the explicit control event.
  // PAUSE_OPCODE = 0x0001 per Annex 31A.
  always_ff @(posedge clk) begin
    if (rst) begin
      control_event_valid  <= 1'b0;
      control_opcode       <= '0;
      control_param_valid  <= 1'b0;
      control_param_data   <= '0;
      control_param_eop    <= 1'b0;
      unsupported_control  <= 1'b0;
      pause_time           <= '0;
    end else begin
      control_event_valid  <= 1'b0;
      control_param_valid  <= 1'b0;
      control_param_eop    <= 1'b0;
      unsupported_control  <= 1'b0;

      if (payload_beat && is_control) begin
        if (payload_sop) begin
          // Opcode occupies payload lanes 0-1 (opcode_high in lane 0); PAUSE
          // time lanes 2-3.  Fields are big-endian: lane 0 is the MSB.
          control_opcode <= { payload_data[7:0], payload_data[15:8] };
          if (beat_bytes(payload_eop, payload_eop_pos) >= EOP_POS_W'(4)) begin
            pause_time          <= { payload_data[23:16], payload_data[31:24] };
            control_event_valid <= ({ payload_data[7:0], payload_data[15:8] } == PAUSE_OPCODE);
            if ({ payload_data[7:0], payload_data[15:8] } != PAUSE_OPCODE)
              unsupported_control <= 1'b1;
            // COVER: Unsupported control opcode received
            // COVER: PAUSE control frame decoded
          end
          control_param_valid <= 1'b1;
          control_param_data  <= payload_data;
          control_param_eop   <= payload_eop;
        end else begin
          // Multi-beat control frame: subsequent beats carry parameters only.
          control_param_valid <= 1'b1;
          control_param_data  <= payload_data;
          control_param_eop   <= payload_eop;
        end
      end
    end
  end

endmodule

`default_nettype wire
