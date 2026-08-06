//==============================================================================
// File       : rtl/rx/rx_header_extract.sv
// Module     : rx_header_extract
// Purpose    : Extracts DA, SA and Length/Type from the normalized 512-bit
//              beat stream. The 14-byte header always occupies lanes 0-13 of
//              the SOP beat, so extraction is combinational; frame_done is
//              pulsed on the EOP beat.
// IEEE Ref   : IEEE 802.3 Clause 3.2.3-3.2.6
// Dependencies: mac_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-08-02 — Widened to 512-bit beat contract
//==============================================================================

`default_nettype none

module rx_header_extract #(
  parameter int unsigned DATA_WIDTH = 512,
  parameter int unsigned KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int unsigned EOP_POS_W   = $clog2(KEEP_WIDTH + 1)
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
  output logic                    frame_done,
  input  logic                    frame_done_ready,
  output logic [47:0]             dest_addr,
  output logic [47:0]             src_addr,
  output logic [15:0]             length_type
);

  //============================================================================
  // Module     : rx_header_extract
  // Parameters :
  //   DATA_WIDTH = 512 — Beat data width
  //   KEEP_WIDTH = 64  — Byte-lane enable width
  // Inputs     :
  //   clk               — Clock
  //   rst               — Reset (synchronous, active high)
  //   in_valid          — Input beat valid
  //   in_data           — Input beat data
  //   in_keep           — Input beat byte enables
  //   in_sop            — Input beat SOP
  //   in_eop            — Input beat EOP
  //   in_eop_pos        — Input EOP valid-byte count
  //   in_error          — Input frame error
  //   frame_done_ready  — Frame done handshake
  // Outputs    :
  //   in_ready          — Input ready
  //   frame_done        — Frame done pulse
  //   dest_addr         — Destination MAC address
  //   src_addr          — Source MAC address
  //   length_type       — Length/Type field
  // Dependencies: mac_pkg
  // Timing    : Combinational header capture on SOP beat
  // Reset     : synchronous, active high
  // Clock     : clk
  // IEEE Ref  : Clause 3.2.3-3.2.6
  //============================================================================

  import mac_pkg::*;

  assign in_ready = !frame_done || frame_done_ready;

  always_ff @(posedge clk) begin
    if (rst) begin
      frame_done  <= 1'b0;
      dest_addr   <= '0;
      src_addr    <= '0;
      length_type <= '0;
    end else begin
      if (frame_done && frame_done_ready)
        frame_done <= 1'b0;

      if (in_valid && in_ready) begin
        if (in_sop) begin
          // IEEE 802.3 Clause 3.2.3-3.2.6: DA=6 octets, SA=6 octets,
          // Length/Type=2 octets at lanes 0-13 of the SOP beat. Header fields
          // are big-endian: the first wire octet (lowest lane) is the most
          // significant byte.
          dest_addr   <= { in_data[ 0*8 +: 8], in_data[ 1*8 +: 8], in_data[ 2*8 +: 8],
                           in_data[ 3*8 +: 8], in_data[ 4*8 +: 8], in_data[ 5*8 +: 8] };
          src_addr    <= { in_data[ 6*8 +: 8], in_data[ 7*8 +: 8], in_data[ 8*8 +: 8],
                           in_data[ 9*8 +: 8], in_data[10*8 +: 8], in_data[11*8 +: 8] };
          length_type <= { in_data[12*8 +: 8], in_data[13*8 +: 8] };
          // COVER: Header extracted from SOP beat
        end
        if (in_eop) begin
          frame_done <= 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire
