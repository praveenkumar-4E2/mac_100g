//==============================================================================
// File       : rtl/control/control_frame_builder.sv
// Module     : control_frame_builder
// Purpose    : Build the 60-octet MAC Control frame as a single 512-bit beat
// IEEE Ref   : IEEE 802.3 Clause 31.4.1.3 and Annex 31A opcode assignments
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to single-beat 512-bit output with keep/eop_pos
//==============================================================================

`default_nettype none

module control_frame_builder #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W  = $clog2(KEEP_WIDTH + 1)
) (
  input  logic                        clk,
  input  logic                        rst,
  input  logic                        control_req_valid,
  output logic                        control_req_ready,
  input  logic [47:0]                 dest_addr,
  input  logic [47:0]                 src_addr,
  input  logic [15:0]                 opcode,
  input  logic                        param_valid,
  output logic                        param_ready,
  input  logic [7:0]                  param_data,
  input  logic                        param_last,
  output logic                        out_valid,
  input  logic                        out_ready,
  output logic [DATA_WIDTH-1:0]       out_data,
  output logic [KEEP_WIDTH-1:0]       out_keep,
  output logic                        out_sop,
  output logic                        out_eop,
  output logic [EOP_POS_W-1:0]        out_eop_pos,
  output logic [47:0]                 out_dest_addr,
  output logic [47:0]                 out_src_addr,
  output logic [15:0]                 out_length_type
);

  //============================================================================
  // Module     : control_frame_builder
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  //   EOP_POS_W  = $clog2(KEEP_WIDTH + 1) — EOP position bit-width
  // Inputs     :
  //   clk                — Clock
  //   rst                — Reset (synchronous, active high)
  //   control_req_valid  — Control frame request valid
  //   dest_addr          — Destination MAC address
  //   src_addr           — Source MAC address
  //   opcode             — Control opcode
  //   param_valid        — Parameter byte valid
  //   param_data         — Parameter byte
  //   param_last         — Last parameter byte
  //   out_ready          — Output ready
  // Outputs    :
  //   control_req_ready  — Request ready
  //   param_ready        — Parameter ready
  //   out_valid          — Output valid (single-beat frame)
  //   out_data           — Output beat
  //   out_keep           — Output beat byte enables
  //   out_sop            — Start of packet (single-beat frame)
  //   out_eop            — End of packet (single-beat frame)
  //   out_eop_pos        — EOP valid-byte count (60)
  //   out_dest_addr      — Destination MAC
  //   out_src_addr       — Source MAC
  //   out_length_type    — Length/Type (MAC Control)
  // Dependencies: mac_pkg
  // Timing    : 1 cycle request; N cycles parameter collect; 1-beat emit
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 31.4.1.3, Annex 31A
  //
  // FSM States:
  //   IDLE    -> COLLECT on control_req_valid
  //   COLLECT -> EMIT on param_last or parameter field full
  //   EMIT    -> IDLE on out_valid && out_ready
  //============================================================================

  import eth_pkg::*;
  import mac_pkg::*;

  localparam int unsigned PARAM_OCTETS = CONTROL_FRAME_OCTETS - 16;

  typedef enum logic [1:0] {
    IDLE    = 2'd0,
    COLLECT = 2'd1,
    EMIT    = 2'd2
  } state_e;

  state_e state;

  logic [5:0]         param_index;
  logic [7:0]         param_buf [PARAM_OCTETS];
  logic [47:0]        dest_addr_r;
  logic [47:0]        src_addr_r;
  logic [15:0]        opcode_r;

  // Build a byte-enable mask for the low n lanes.
  function automatic logic [KEEP_WIDTH-1:0] keep_mask(input integer n);
    keep_mask = '0;
    for (integer j = 0; j < KEEP_WIDTH; j++)
      if (j < n)
        keep_mask[j] = 1'b1;
  endfunction

  assign control_req_ready = (state == IDLE);
  assign param_ready       = (state == COLLECT) && (param_index < PARAM_OCTETS);
  assign out_valid         = (state == EMIT);
  assign out_sop           = (state == EMIT);
  assign out_eop           = (state == EMIT);
  assign out_eop_pos       = EOP_POS_W'(CONTROL_FRAME_OCTETS);
  assign out_keep          = keep_mask(CONTROL_FRAME_OCTETS);
  assign out_dest_addr     = dest_addr_r;
  assign out_src_addr      = src_addr_r;
  assign out_length_type   = ETHERTYPE_MAC_CONTROL;

  always_comb begin
    integer b;
    out_data = '0;
    for (b = 0; b < KEEP_WIDTH; b++) begin
      if (b < 6)
        out_data[8*b +: 8] = dest_addr_r[47 - 8*b -: 8];
      else if (b < 12)
        out_data[8*b +: 8] = src_addr_r[47 - 8*(b - 6) -: 8];
      else if (b < 14)
        out_data[8*b +: 8] = ETHERTYPE_MAC_CONTROL[15 - 8*(b - 12) -: 8];
      else if (b < 16)
        out_data[8*b +: 8] = opcode_r[15 - 8*(b - 14) -: 8];
      else if (b < CONTROL_FRAME_OCTETS)
        out_data[8*b +: 8] = param_buf[b - 16];
      else
        out_data[8*b +: 8] = 8'h00;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state        <= IDLE;
      param_index  <= '0;
      dest_addr_r  <= '0;
      src_addr_r   <= '0;
      opcode_r     <= '0;
    end else begin
      unique case (state)
        IDLE: begin
          if (control_req_valid) begin
            state       <= COLLECT;
            param_index <= '0;
            dest_addr_r <= dest_addr;
            src_addr_r  <= src_addr;
            opcode_r    <= opcode;
          end
        end

        COLLECT: begin
          if (param_valid && param_ready) begin
            param_buf[param_index] <= param_data;
            param_index            <= param_index + 1'b1;
            if (param_last || (param_index == PARAM_OCTETS - 1))
              state <= EMIT;
            // COVER: Control frame parameters collected
          end
        end

        EMIT: begin
          if (out_valid && out_ready) begin
            state <= IDLE;
            // COVER: Control frame built and transmitted
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire
