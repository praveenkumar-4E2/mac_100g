//==============================================================================
// File       : rtl/primitives/crc32_pkg.sv
// Module     : crc32_pkg
// Purpose    : Byte-wise reflected CRC-32 update used by Ethernet MAC FCS logic
// IEEE Ref   : IEEE 802.3 Clause 3.2.9, 3.3
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-1.3: Enhanced function docs with polynomial usage and synthesis notes
//==============================================================================

`default_nettype none

package crc32_pkg;
  /* verilator lint_off UNUSEDPARAM */
  localparam logic [31:0] CRC32_POLY    = 32'hEDB8_8320;
  localparam logic [31:0] CRC32_INIT    = 32'hFFFF_FFFF;
  localparam logic [31:0] CRC32_RESIDUE = 32'hDEBB_20E3;

  //----------------------------------------------------------------------------
  // Function: crc32_init
  // Purpose: Return the initial CRC value for a fresh frame.
  // Polynomial: None (constant return)
  // Synthesis: Elaboration-time constant; synthesizes to wires
  // Returns: CRC32_INIT (0xFFFF_FFFF)
  //----------------------------------------------------------------------------
  function automatic logic [31:0] crc32_init();
    return CRC32_INIT;
  endfunction

  //----------------------------------------------------------------------------
  // Function: crc32_finalize
  // Purpose: Apply final complement to produce transmitted FCS.
  // Polynomial: None (bitwise complement)
  // Synthesis: Single NOT gate per bit; fully synthesizable
  // Returns: Bitwise complement of input CRC
  //----------------------------------------------------------------------------
  function automatic logic [31:0] crc32_finalize(input logic [31:0] crc);
    return ~crc;
  endfunction

  //----------------------------------------------------------------------------
  // Function: update_byte
  // Purpose: Update reflected CRC with a single data byte (LSB-first).
  // Polynomial: Reflected 0xEDB88320 (IEEE 802.3 Clause 3.2.9)
  // Synthesis: Fully synthesizable; infers combinational logic
  // Inputs:  crc      — current CRC state
  //          data_byte — next byte to process (LSB transmitted first)
  // Returns: Updated CRC value
  //----------------------------------------------------------------------------
  function automatic logic [31:0] update_byte(
    input logic [31:0] crc,
    input logic [7:0]  data_byte
  );
    logic [31:0] value;
    logic        feedback;
    int unsigned bit_index;
    begin
      value = crc;
      for (bit_index = 0; bit_index < 8; bit_index++) begin
        feedback = value[0] ^ data_byte[bit_index];
        value    = value >> 1;
        if (feedback) begin
          value = value ^ CRC32_POLY;
        end
      end
      return value;
    end
  endfunction

  //----------------------------------------------------------------------------
  // Function: update_word
  // Purpose: Update CRC with 4 bytes (LSB first order).
  // Polynomial: Reflected 0xEDB88320 via update_byte (IEEE 802.3 Clause 3.2.9)
  // Synthesis: Fully synthesizable; infers 4 cascaded update_byte instances
  // Inputs:  crc       — current CRC state
  //          data_word — 32-bit data (byte 0 LSB first)
  // Returns: Updated CRC value
  //----------------------------------------------------------------------------
  function automatic logic [31:0] update_word(
    input logic [31:0] crc,
    input logic [31:0] data_word
  );
    logic [31:0] value;
    begin
      value = update_byte(crc, data_word[7:0]);
      value = update_byte(value, data_word[15:8]);
      value = update_byte(value, data_word[23:16]);
      value = update_byte(value, data_word[31:24]);
      return value;
    end
  endfunction

  //----------------------------------------------------------------------------
  // Function: update_dword
  // Purpose: Update CRC with 8 bytes (LSB first order).
  // Polynomial: Reflected 0xEDB88320 via update_byte (IEEE 802.3 Clause 3.2.9)
  // Synthesis: Fully synthesizable; infers 8 cascaded update_byte instances
  // Inputs:  crc        — current CRC state
  //          data_dword — 64-bit data (byte 0 LSB first)
  // Returns: Updated CRC value
  //----------------------------------------------------------------------------
  function automatic logic [31:0] update_dword(
    input logic [31:0] crc,
    input logic [63:0] data_dword
  );
    logic [31:0] value;
    int unsigned byte_index;
    begin
      value = crc;
      for (byte_index = 0; byte_index < 8; byte_index++) begin
        value = update_byte(value, data_dword[byte_index*8 +: 8]);
      end
      return value;
    end
  endfunction

  //----------------------------------------------------------------------------
  // Function: update_bytes
  // Purpose:  Update CRC with up to 64 bytes (LSB-first), gated by a per-lane
  //           keep mask so partial final beats advance only the valid lanes.
  // Polynomial: Reflected 0xEDB88320 via update_byte (IEEE 802.3 Clause 3.2.9)
  // Synthesis: Fully synthesizable; infers cascaded update_byte instances
  // Inputs:  crc  — current CRC state
  //          data — 64-byte (512-bit) data, byte 0 LSB first
  //          keep — per-byte enable, keep[n] gates data[n*8 +: 8]
  // Returns: Updated CRC value
  //----------------------------------------------------------------------------
  function automatic logic [31:0] update_bytes(
    input logic [31:0]  crc,
    input logic [511:0] data,
    input logic [63:0]  keep
  );
    logic [31:0] value;
    int unsigned byte_index;
    begin
      value = crc;
      for (byte_index = 0; byte_index < 64; byte_index++) begin
        if (keep[byte_index])
          value = update_byte(value, data[byte_index*8 +: 8]);
      end
      return value;
    end
  endfunction

  /* verilator lint_on UNUSEDPARAM */
endpackage

`default_nettype wire