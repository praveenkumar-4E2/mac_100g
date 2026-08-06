//==============================================================================
// File       : rtl/tx/frame_formatter.sv
// Module     : frame_formatter
// Purpose    : TX frame formatting — capture client payload, insert preamble/SFD,
//              DA/SA/LT, optional padding/FCS, and emit on valid/ready
// IEEE Ref   : IEEE 802.3 Clauses 3.2.1-3.2.9, 3.3; Annex 4A Figure 4A-2a
// Dependencies: mac_pkg, crc32_tx
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module frame_formatter #(
  parameter int unsigned BUFFER_BYTES = 2048
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        start,
  output logic        req_ready,
  input  logic        ready,
  input  logic [47:0] dest_addr,
  input  logic [47:0] src_addr,
  input  logic [15:0] length_type,
  input  logic        client_valid,
  output logic        client_ready,
  input  logic [7:0]  client_data,
  input  logic        client_last,
  input  logic        client_fcs_present,
  output logic        out_valid,
  output logic [7:0]  out_data,
  output logic        out_sop,
  output logic        out_eop,
  output logic        out_error,
  output logic        busy,
  output logic        frame_done
);

  //============================================================================
  // Module     : frame_formatter
  // Parameters :
  //   BUFFER_BYTES = 2048 — Client payload buffer size
  // Inputs     :
  //   clk                  — Clock
  //   rst                  — Reset (synchronous, active high)
  //   start                — Frame start pulse
  //   ready                — Output ready
  //   dest_addr            — Destination MAC address
  //   src_addr             — Source MAC address
  //   length_type          — Length/Type field
  //   client_valid         — Client payload valid
  //   client_data          — Client payload byte
  //   client_last          — Client payload last byte
  //   client_fcs_present   — Client supplies FCS
  // Outputs    :
  //   req_ready         — Ready for new frame start
  //   client_ready      — Ready for client data
  //   out_valid         — Output byte valid
  //   out_data          — Output byte
  //   out_sop           — Start of packet
  //   out_eop           — End of packet
  //   out_error         — Output error
  //   busy              — Formatter busy
  //   frame_done        — Frame complete pulse
  // Dependencies: mac_pkg, crc32_tx
  // Timing    : Pipeline depth varies by frame length
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clauses 3.2.1-3.2.9, 3.3; Annex 4A Figure 4A-2a
  // FSM States:
  //   IDLE     -> CAPTURE  on start
  //   CAPTURE  -> PREAMBLE on client_last
  //   PREAMBLE -> SFD      on out_index == 6 (7 octets)
  //   SFD      -> DA       on transfer
  //   DA       -> SA       on out_index == 5 (6 octets)
  //   SA       -> LT       on out_index == 5 (6 octets)
  //   LT       -> DATA     on out_index == 1 && payload_len > 0
  //   LT       -> FCS      on out_index == 1 && payload_len == 0 && pad_count == 0
  //   LT       -> PAD      on out_index == 1 && payload_len == 0 && pad_count > 0
  //   DATA     -> PAD      on out_index == payload_len-1 && pad_count > 0
  //   DATA     -> FCS      on out_index == payload_len-1 && pad_count == 0
  //   PAD      -> FCS      on out_index == pad_count-1
  //   FCS      -> IDLE     on out_index == 3 (4 FCS octets)
  //   default  -> IDLE
  //============================================================================

  import mac_pkg::*;

  typedef enum logic [3:0] {
    IDLE    = 4'd0,
    CAPTURE = 4'd1,
    PREAMBLE = 4'd2,
    SFD      = 4'd3,
    DA       = 4'd4,
    SA       = 4'd5,
    LT       = 4'd6,
    DATA     = 4'd7,
    PAD      = 4'd8,
    FCS      = 4'd9
  } state_t;

  state_t state;

  logic [7:0] frame_buffer [0:BUFFER_BYTES-1];
  logic [47:0] da_reg;
  logic [47:0] sa_reg;
  logic [15:0] lt_reg;
  logic        fcs_present_reg;
  logic [15:0] client_count;
  logic [15:0] payload_len;
  logic [15:0] out_index;
  logic [15:0] pad_count;
  logic [31:0] crc_value;
  logic        crc_init;
  logic        crc_valid;
  logic [7:0]  crc_data;
  logic [31:0] generated_fcs;
  logic        transfer;
  logic [15:0] fcs_mem_index;

  assign req_ready      = (state == IDLE);
  assign busy           = (state != IDLE);
  assign client_ready   = (state == CAPTURE) && (client_count < BUFFER_BYTES);
  assign transfer       = out_valid && ready;
  assign crc_data       = out_data;
  assign crc_init       = (state == LT) && transfer && (out_index == 1);
  assign crc_valid      = transfer &&
                          ((state == DA) || (state == SA) ||
                           (state == LT) || (state == DATA) || (state == PAD)) &&
                          !crc_init;
  assign generated_fcs  = crc_value;
  assign fcs_mem_index  = payload_len + out_index;

  crc32_tx crc32_tx_inst (
    .clk         (clk),
    .rst         (rst),
    .init        (crc_init),
    .data_valid  (crc_valid),
    .data        (crc_data),
    .crc_out     (crc_value)
  );

  always_comb begin
    out_valid = 1'b0;
    out_data  = 8'h00;
    out_sop   = 1'b0;
    out_eop   = 1'b0;
    out_error = 1'b0;

    unique case (state)
      PREAMBLE: begin
        // PREAMBLE_BYTE = 8'hAA (10101010), 7 octets per Clause 3.2.1
        out_valid = 1'b1;
        out_data  = 8'hAA;
        out_sop   = (out_index == 0);
      end
      SFD: begin
        // SFD_BYTE = 8'hD5 (10101011) per Clause 3.2.1
        out_valid = 1'b1;
        out_data  = SFD_BYTE;
      end
      DA: begin
        out_valid = 1'b1;
        out_data  = da_reg[47 - 8*out_index -: 8];
      end
      SA: begin
        out_valid = 1'b1;
        out_data  = sa_reg[47 - 8*out_index -: 8];
      end
      LT: begin
        out_valid = 1'b1;
        out_data  = lt_reg[15 - 8*out_index -: 8];
      end
      DATA: begin
        out_valid = 1'b1;
        out_data  = frame_buffer[out_index[10:0]];
      end
      PAD: begin
        // PAD_BYTE = 8'h00 per Clause 3.2.8
        out_valid = 1'b1;
        out_data  = 8'h00;
      end
      FCS: begin
        out_valid = 1'b1;
        if (fcs_present_reg) begin
          out_data = frame_buffer[fcs_mem_index[10:0]];
        end else begin
          out_data = generated_fcs[31 - 8*out_index -: 8];
        end
        // FCS_OCTETS = 4
        out_eop = (out_index == 3);
      end
      default: begin end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state             <= IDLE;
      da_reg            <= '0;
      sa_reg            <= '0;
      lt_reg            <= '0;
      fcs_present_reg   <= 1'b0;
      client_count      <= '0;
      payload_len       <= '0;
      out_index         <= '0;
      pad_count         <= '0;
      frame_done        <= 1'b0;
    end else begin
      frame_done <= 1'b0;
      unique case (state)
        IDLE: begin
          if (start) begin
            da_reg           <= dest_addr;
            sa_reg           <= src_addr;
            lt_reg           <= length_type;
            fcs_present_reg  <= client_fcs_present;
            client_count     <= '0;
            state            <= CAPTURE;
          end
        end
        CAPTURE: begin
          if (client_valid && client_ready) begin
            frame_buffer[client_count[10:0]] <= client_data;
            if (client_last) begin
              if (fcs_present_reg) begin
                payload_len <= (client_count + 1 >= 4) ? client_count + 1 - 4 : '0;
                pad_count   <= '0;
              end else begin
                payload_len <= client_count + 1;
                // MIN_CLIENT_AND_PAD_OCTETS = 46 (Clause 3.2.7). PAD added if payload+DA+SA+LT < 64
                pad_count   <= (client_count + 1 < MIN_CLIENT_AND_PAD_OCTETS) ?
                               (MIN_CLIENT_AND_PAD_OCTETS - (client_count + 1)) : 12'd0;
              end
              out_index <= '0;
              state     <= PREAMBLE;
            end else begin
              client_count <= client_count + 1'b1;
            end
          end
        end
        PREAMBLE: if (transfer) begin
          // PREAMBLE_OCTETS = 7
          if (out_index == 6) begin
            out_index <= '0;
            state     <= SFD;
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        SFD: if (transfer) begin
          out_index <= '0;
          state     <= DA;
        end
        DA: if (transfer) begin
          // ADDRESS_OCTETS = 6
          if (out_index == 5) begin
            out_index <= '0;
            state     <= SA;
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        SA: if (transfer) begin
          if (out_index == 5) begin
            out_index <= '0;
            state     <= LT;
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        LT: if (transfer) begin
          // LENGTH_TYPE_OCTETS = 2
          if (out_index == 1) begin
            out_index <= '0;
            state     <= (payload_len == 0) ? FCS : DATA;
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        DATA: if (transfer) begin
          if (out_index == payload_len - 1) begin
            out_index <= '0;
            state     <= (pad_count != 0) ? PAD : FCS;
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        PAD: if (transfer) begin
          if (out_index == pad_count - 1) begin
            out_index <= '0;
            state     <= FCS;
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        FCS: if (transfer) begin
          // FCS_OCTETS = 4
          if (out_index == 3) begin
            state      <= IDLE;
            out_index  <= '0;
            frame_done <= 1'b1;
            // COVER: Frame transmission complete
          end else begin
            out_index <= out_index + 1'b1;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule

`default_nettype wire