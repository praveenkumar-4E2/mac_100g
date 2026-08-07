/**
 * @brief Utility-test class (mac_test_pkg member).
 *
 * `mac_hvl_utils_test_c` executes the directed vectors for the pure utility
 * methods in `mac_hvl_utils_c`. It is a runnable uvm_test (selected by
 * `+UVM_TESTNAME=mac_hvl_utils_test_c`) that needs no virtual interface, no
 * environment, and no DUT stimulus: every check calls a static utility
 * function with a fixed vector and compares the result to the expected value.
 *
 * The per-method vector groups are added task by task (UTL-027 keep-mask
 * vectors, then valid_bytes_from_keep, keep_from_valid_bytes, eop_pos,
 * ceil_div, IPG cycles, byte-queue, header endianness, and FCS vectors).
 * UTL-047 unifies them into one harness that reports a single pass/fail
 * outcome; until then each group runs and reports its own count.
 *
 * This file is a member of mac_test_pkg (text-included), so it must NOT
 * declare `package`/`endpackage`. It is included with the other test classes.
 */
`ifndef MAC_HVL_UTILS_TEST_SVH
`define MAC_HVL_UTILS_TEST_SVH

  class mac_hvl_utils_test_c extends uvm_test;
    `uvm_component_utils(mac_hvl_utils_test_c)

    typedef struct {
      bit [63:0]   keep;
      int unsigned keep_width;
      bit          expected;
      string       name;
    } keep_mask_vec_t;

    typedef struct {
      bit [63:0]   keep;
      int unsigned keep_width;
      int unsigned expected;
      string       name;
    } valid_bytes_vec_t;

    typedef struct {
      int unsigned valid_bytes;
      int unsigned keep_width;
      bit [63:0]   expected_keep;
      string       name;
    } keep_roundtrip_vec_t;

    typedef struct {
      bit [63:0]   keep;
      int unsigned keep_width;
      int          expected;
      string       name;
    } eop_pos_vec_t;

    typedef struct {
      int unsigned numerator;
      int unsigned denominator;
      int          expected;
      string       name;
    } ceil_div_vec_t;

    typedef struct {
      int unsigned valid_bytes;
      int unsigned keep_width;
      int unsigned data_width;
      int unsigned ipg_bits;
      int          expected;
      string       name;
    } ipg_cycles_vec_t;

    // Directed keep-mask vectors (UTL-027): empty, one-lane, full-width,
    // valid partial, and non-contiguous masks, including masks with a set
    // bit at or above keep_width (malformed for that geometry).
    static const keep_mask_vec_t KEEP_MASK_VECTORS[] = '{
      // Empty: zero valid bytes is contiguous-low.
      '{64'h0000_0000_0000_0000, 64, 1'b1, "empty_w64"},
      '{64'h0000_0000_0000_0000,  8, 1'b1, "empty_w8"},
      // One-lane.
      '{64'h0000_0000_0000_0001, 64, 1'b1, "one_lane_w64"},
      '{64'h0000_0000_0000_0001,  8, 1'b1, "one_lane_w8"},
      // Full-width: all lanes valid.
      '{64'hFFFF_FFFF_FFFF_FFFF, 64, 1'b1, "full_w64"},
      '{64'h0000_0000_0000_00FF,  8, 1'b1, "full_w8"},
      // Valid partial: contiguous low run inside the width.
      '{64'h0000_0000_0000_000F,  8, 1'b1, "partial_4lanes_w8"},
      '{64'h0000_0000_0000_007F, 64, 1'b1, "partial_7lanes_w64"},
      // Non-contiguous: gap before a higher bit.
      '{64'h0000_0000_0000_005F,  8, 1'b0, "gap_w8"},
      // Non-contiguous: only a high bit set, lane 0 clear.
      '{64'h0000_0000_0000_0080,  8, 1'b0, "high_only_w8"},
      // Malformed for width: bit at/above keep_width set.
      '{64'h0000_0000_0000_00FF,  7, 1'b0, "bit_above_width"},
      // Non-contiguous: two separate runs.
      '{64'h0000_0000_0000_0F0F, 64, 1'b0, "two_runs_w64"},
      // Non-contiguous: upper bit set, lane 0 clear.
      '{64'h0000_0000_0000_0010, 64, 1'b0, "upper_only_w64"}
    };

    // Directed valid_bytes_from_keep vectors (UTL-029): full and partial
    // legal contiguous-low masks, plus the width-boundary masking case
    // (set bits above keep_width are ignored, matching the is_contiguous_low_mask
    // malformed-over-width rule).
    static const valid_bytes_vec_t VALID_BYTES_VECTORS[] = '{
      // Full-width legal masks.
      '{64'hFFFF_FFFF_FFFF_FFFF, 64, 64, "full_w64"},
      '{64'h0000_0000_0000_00FF,  8,  8, "full_w8"},
      // Empty mask: zero valid bytes.
      '{64'h0000_0000_0000_0000, 64,  0, "empty_w64"},
      // One-lane mask.
      '{64'h0000_0000_0000_0001,  8,  1, "one_lane_w8"},
      // Partial legal masks (contiguous low runs).
      '{64'h0000_0000_0000_000F,  8,  4, "partial_4lanes_w8"},
      '{64'h0000_0000_0000_007F, 64,  7, "partial_7lanes_w64"},
      '{64'h0000_0000_0000_01FF,  9,  9, "partial_9lanes_w9"},
      '{64'h0000_0000_0000_0007, 64,  3, "partial_3lanes_w64"},
      '{64'h0000_0000_0000_003F,  8,  6, "partial_6lanes_w8"},
      // Width boundary: 0xFF at keep_width 4 counts only lanes [0:3].
      '{64'h0000_0000_0000_00FF,  4,  4, "width_boundary_w4"}
    };

    // Directed keep_from_valid_bytes vectors (UTL-031): every case checks the
    // produced mask exactly, that it is contiguous-low, and that
    // valid_bytes_from_keep round-trips back to the same valid-byte count
    // (inverse consistency for legal sizes 0..keep_width).
    static const keep_roundtrip_vec_t KEEP_ROUNDTRIP_VECTORS[] = '{
      '{ 0, 64, 64'h0000_0000_0000_0000, "empty_w64"},
      '{ 0,  8, 64'h0000_0000_0000_0000, "empty_w8"},
      '{ 1, 64, 64'h0000_0000_0000_0001, "one_lane_w64"},
      '{ 1,  8, 64'h0000_0000_0000_0001, "one_lane_w8"},
      '{ 8,  8, 64'h0000_0000_0000_00FF, "full_beat_w8"},
      '{64, 64, 64'hFFFF_FFFF_FFFF_FFFF, "full_beat_w64"},
      '{ 9,  9, 64'h0000_0000_0000_01FF, "full_beat_w9"},
      '{ 4,  8, 64'h0000_0000_0000_000F, "partial_4lanes_w8"},
      '{ 7, 64, 64'h0000_0000_0000_007F, "partial_7lanes_w64"},
      '{ 3,  8, 64'h0000_0000_0000_0007, "partial_3lanes_w8"},
      '{32, 64, 64'h0000_0000_FFFF_FFFF, "partial_32lanes_w64"},
      '{63, 64, 64'h7FFF_FFFF_FFFF_FFFF, "partial_63lanes_w64"}
    };

    // Directed eop_pos_from_keep vectors (UTL-033): final full beat,
    // final partial beat, empty, and invalid-mask handling (invalid result -1).
    static const eop_pos_vec_t EOP_POS_VECTORS[] = '{
      // Final full beat: eop_pos == keep_width.
      '{64'hFFFF_FFFF_FFFF_FFFF, 64,  64, "full_w64"},
      '{64'h0000_0000_0000_00FF,  8,   8, "full_w8"},
      '{64'h0000_0000_0000_01FF,  9,   9, "full_w9"},
      // Final partial beat: eop_pos == valid byte count.
      '{64'h0000_0000_0000_000F,  8,   4, "partial_4lanes_w8"},
      '{64'h0000_0000_0000_007F, 64,   7, "partial_7lanes_w64"},
      '{64'h0000_0000_0000_0001,  8,   1, "one_lane_w8"},
      '{64'h0000_0000_0000_003F,  8,   6, "partial_6lanes_w8"},
      // Empty mask: zero valid bytes.
      '{64'h0000_0000_0000_0000, 64,   0, "empty_w64"},
      // Invalid masks: defined result -1 (outside [0:keep_width]).
      '{64'h0000_0000_0000_005F,  8,  -1, "gap_w8"},
      '{64'h0000_0000_0000_0080,  8,  -1, "high_only_w8"},
      '{64'h0000_0000_0000_00FF,  7,  -1, "bit_above_width"},
      '{64'h0000_0000_0000_0F0F, 64,  -1, "two_runs_w64"},
      '{64'h0000_0000_0000_0010, 64,  -1, "upper_only_w64"}
    };

    // Directed ceil_div vectors (UTL-035): exact division, remainder
    // division, zero numerator, and the defined invalid (zero) denominator
    // result -1.
    static const ceil_div_vec_t CEIL_DIV_VECTORS[] = '{
      // Exact division.
      '{ 8,  4,  2, "exact_8_over_4"},
      '{64,  8,  8, "exact_64_over_8"},
      '{ 9,  3,  3, "exact_9_over_3"},
      '{ 0,  5,  0, "zero_numerator"},
      // Remainder division rounds up.
      '{ 9,  4,  3, "rem_9_over_4"},
      '{ 5,  2,  3, "rem_5_over_2"},
      '{ 1,  8,  1, "rem_1_over_8"},
      '{ 7,  8,  1, "rem_7_over_8"},
      '{64, 12,  6, "rem_64_over_12"},
      // Exact boundary: numerator multiple of denominator is not rounded up.
      '{12,  4,  3, "exact_12_over_4"},
      // Defined invalid denominator: zero returns -1.
      '{ 9,  0, -1, "zero_denominator"},
      '{ 0,  0, -1, "zero_over_zero"}
    };

    // Directed ipg_cycles_from_valid_bytes vectors (UTL-037): IPG fully
    // consumed by the final beat's unused lanes (0 cycles) and IPG requiring
    // extra whole cycles, plus invalid-geometry results. Baseline geometry
    // matches the DUT: KEEP_WIDTH=64, DATA_WIDTH=512, RS_IPG_BITS_DEFAULT=96.
    static const ipg_cycles_vec_t IPG_CYCLES_VECTORS[] = '{
      // IPG fully consumed by unused final lanes -> 0 whole cycles.
      '{60, 64, 512,  32,  0, "ipg_consumed_32unused"},
      '{63, 64, 512,   8,  0, "ipg_consumed_8unused"},
      '{61, 64, 512,  24,  0, "ipg_consumed_24unused"},
      '{32, 64, 512,  96,  0, "ipg_consumed_32lanes"},
      '{64, 64, 512,   0,  0, "zero_ipg_full_beat"},
      // IPG requiring extra whole cycles.
      '{64, 64, 512,  96,  1, "ipg_extra_full_beat"},
      '{60, 64, 512,  96,  1, "ipg_extra_60bytes"},
      '{63, 64, 512,  96,  1, "ipg_extra_63bytes"},
      '{32, 64, 512, 300,  1, "ipg_extra_32lanes_300"},
      '{64, 64, 512, 600,  2, "ipg_extra_600bits"},
      // Narrower geometry: 8 lanes / 64-bit beats.
      '{ 8,  8,  64,  96,  2, "w8_ipg_96_full"},
      '{ 7,  8,  64,  96,  2, "w8_ipg_96_partial"},
      // Invalid geometry/input -> -1.
      '{65, 64, 512,  96, -1, "valid_bytes_over_width"},
      '{ 0, 64,   0,  96, -1, "zero_data_width"},
      '{ 0,  0,   0,  96, -1, "zero_keep_width"}
    };

    int unsigned num_failed  = 0;
    int unsigned num_checked = 0;

    extern function new(string name = "mac_hvl_utils_test_c", uvm_component parent = null);
    extern task run_phase(uvm_phase phase);
    extern function void report_phase(uvm_phase phase);
    extern function void run_keep_mask_vectors();
    extern function void run_valid_bytes_vectors();
    extern function void run_keep_roundtrip_vectors();
    extern function void run_eop_pos_vectors();
    extern function void run_ceil_div_vectors();
    extern function void run_ipg_cycles_vectors();
    extern function void run_byte_queue_vectors();
    extern function void run_be_vectors();
    extern function void run_fcs_vectors();
    extern function void run_format_vectors();
    extern function void run_frame_c_vectors();
    extern function void run_codec_vectors();
    extern function void run_rs_codec_vectors();
    extern function void run_axi_roundtrip_vectors();
    extern function void run_rs_roundtrip_vectors();
    extern function void run_compare_vectors();
    extern function mac_frame_c mk_cmp_frame(bit [47:0] da = 48'h00_11_22_33_44_55,
                                             bit [47:0] sa = 48'h66_77_88_99_aa_bb,
                                             bit [15:0] et = 16'h0800,
                                             bit [31:0] fcs = 32'hDEAD_BEEF);
    extern function void build_rs_wire(bit [47:0] da, bit [47:0] sa,
                                       bit [15:0] et,
                                       byte unsigned payload[],
                                       bit with_fcs,
                                       bit [31:0] fcs_val,
                                       output byte unsigned wq[$]);
  endclass

  function mac_hvl_utils_test_c::new(string name = "mac_hvl_utils_test_c",
                                     uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void mac_hvl_utils_test_c::run_keep_mask_vectors();
    foreach (KEEP_MASK_VECTORS[i]) begin
      bit got;
      got = mac_hvl_utils_c::is_contiguous_low_mask(KEEP_MASK_VECTORS[i].keep,
                                                    KEEP_MASK_VECTORS[i].keep_width);
      num_checked++;
      if (got !== KEEP_MASK_VECTORS[i].expected) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("is_contiguous_low_mask(%h, %0d) = %0b, expected %0b (%s)",
                             KEEP_MASK_VECTORS[i].keep,
                             KEEP_MASK_VECTORS[i].keep_width,
                             got, KEEP_MASK_VECTORS[i].expected,
                             KEEP_MASK_VECTORS[i].name))
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_valid_bytes_vectors();
    foreach (VALID_BYTES_VECTORS[i]) begin
      int unsigned got;
      got = mac_hvl_utils_c::valid_bytes_from_keep(VALID_BYTES_VECTORS[i].keep,
                                                   VALID_BYTES_VECTORS[i].keep_width);
      num_checked++;
      if (got != VALID_BYTES_VECTORS[i].expected) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("valid_bytes_from_keep(%h, %0d) = %0d, expected %0d (%s)",
                             VALID_BYTES_VECTORS[i].keep,
                             VALID_BYTES_VECTORS[i].keep_width,
                             got, VALID_BYTES_VECTORS[i].expected,
                             VALID_BYTES_VECTORS[i].name))
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_keep_roundtrip_vectors();
    foreach (KEEP_ROUNDTRIP_VECTORS[i]) begin
      bit [63:0]   got_keep;
      int unsigned got_bytes;
      bit          is_contig;
      got_keep  = mac_hvl_utils_c::keep_from_valid_bytes(
                    KEEP_ROUNDTRIP_VECTORS[i].valid_bytes,
                    KEEP_ROUNDTRIP_VECTORS[i].keep_width);
      num_checked++;
      if (got_keep !== KEEP_ROUNDTRIP_VECTORS[i].expected_keep) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("keep_from_valid_bytes(%0d, %0d) = %h, expected %h (%s)",
                             KEEP_ROUNDTRIP_VECTORS[i].valid_bytes,
                             KEEP_ROUNDTRIP_VECTORS[i].keep_width,
                             got_keep, KEEP_ROUNDTRIP_VECTORS[i].expected_keep,
                             KEEP_ROUNDTRIP_VECTORS[i].name))
      end
      is_contig = mac_hvl_utils_c::is_contiguous_low_mask(got_keep,
                                                           KEEP_ROUNDTRIP_VECTORS[i].keep_width);
      num_checked++;
      if (is_contig !== 1'b1) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("keep_from_valid_bytes(%0d, %0d) = %h not contiguous-low (%s)",
                             KEEP_ROUNDTRIP_VECTORS[i].valid_bytes,
                             KEEP_ROUNDTRIP_VECTORS[i].keep_width,
                             got_keep, KEEP_ROUNDTRIP_VECTORS[i].name))
      end
      got_bytes = mac_hvl_utils_c::valid_bytes_from_keep(got_keep,
                                                          KEEP_ROUNDTRIP_VECTORS[i].keep_width);
      num_checked++;
      if (got_bytes != KEEP_ROUNDTRIP_VECTORS[i].valid_bytes) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("roundtrip %0d -> %h -> %0d bytes, expected %0d (%s)",
                             KEEP_ROUNDTRIP_VECTORS[i].valid_bytes,
                             got_keep, got_bytes,
                             KEEP_ROUNDTRIP_VECTORS[i].valid_bytes,
                             KEEP_ROUNDTRIP_VECTORS[i].name))
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_eop_pos_vectors();
    foreach (EOP_POS_VECTORS[i]) begin
      int got;
      got = mac_hvl_utils_c::eop_pos_from_keep(EOP_POS_VECTORS[i].keep,
                                               EOP_POS_VECTORS[i].keep_width);
      num_checked++;
      if (got != EOP_POS_VECTORS[i].expected) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("eop_pos_from_keep(%h, %0d) = %0d, expected %0d (%s)",
                             EOP_POS_VECTORS[i].keep,
                             EOP_POS_VECTORS[i].keep_width,
                             got, EOP_POS_VECTORS[i].expected,
                             EOP_POS_VECTORS[i].name))
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_ceil_div_vectors();
    foreach (CEIL_DIV_VECTORS[i]) begin
      int got;
      got = mac_hvl_utils_c::ceil_div(CEIL_DIV_VECTORS[i].numerator,
                                      CEIL_DIV_VECTORS[i].denominator);
      num_checked++;
      if (got != CEIL_DIV_VECTORS[i].expected) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("ceil_div(%0d, %0d) = %0d, expected %0d (%s)",
                             CEIL_DIV_VECTORS[i].numerator,
                             CEIL_DIV_VECTORS[i].denominator,
                             got, CEIL_DIV_VECTORS[i].expected,
                             CEIL_DIV_VECTORS[i].name))
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_ipg_cycles_vectors();
    foreach (IPG_CYCLES_VECTORS[i]) begin
      int got;
      got = mac_hvl_utils_c::ipg_cycles_from_valid_bytes(
              IPG_CYCLES_VECTORS[i].valid_bytes,
              IPG_CYCLES_VECTORS[i].keep_width,
              IPG_CYCLES_VECTORS[i].data_width,
              IPG_CYCLES_VECTORS[i].ipg_bits);
      num_checked++;
      if (got != IPG_CYCLES_VECTORS[i].expected) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR",
                   $sformatf("ipg_cycles_from_valid_bytes(%0d, %0d, %0d, %0d) = %0d, expected %0d (%s)",
                             IPG_CYCLES_VECTORS[i].valid_bytes,
                             IPG_CYCLES_VECTORS[i].keep_width,
                             IPG_CYCLES_VECTORS[i].data_width,
                             IPG_CYCLES_VECTORS[i].ipg_bits,
                             got, IPG_CYCLES_VECTORS[i].expected,
                             IPG_CYCLES_VECTORS[i].name))
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_byte_queue_vectors();
    // Full beat: lane i = byte i (0..63). append_beat_bytes must map
    // lane 0 -> queue[0] and preserve order for all 64 lanes.
    begin
      bit [511:0] beat;
      byte unsigned q[$];
      bit ok = 1'b1;
      for (int i = 0; i < 64; i++)
        beat[8*i +: 8] = i[7:0];
      num_checked++;
      if (mac_hvl_utils_c::append_beat_bytes(q, beat, 64, 64) != 64) ok = 1'b0;
      if (q.size() != 64) ok = 1'b0;
      foreach (q[i]) if (q[i] != i[7:0]) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "byte_queue: full-beat lane-0 append/order mismatch (full_beat)")
      end
    end

    // Partial beat: only lanes [0:valid_bytes-1] are appended, in order;
    // the garbage bytes in lanes >= valid_bytes must be excluded.
    begin
      bit [511:0] beat;
      byte unsigned q[$];
      bit ok = 1'b1;
      byte unsigned expected[4] = '{8'h0A, 8'h0B, 8'h0C, 8'h0D};
      beat = '1;  // garbage in every lane
      beat[8*0 +: 8] = 8'h0A;
      beat[8*1 +: 8] = 8'h0B;
      beat[8*2 +: 8] = 8'h0C;
      beat[8*3 +: 8] = 8'h0D;
      num_checked++;
      if (mac_hvl_utils_c::append_beat_bytes(q, beat, 4, 64) != 4) ok = 1'b0;
      if (q.size() != 4) ok = 1'b0;
      foreach (q[i]) if (q[i] != expected[i]) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "byte_queue: partial-beat append excluded high lanes (partial_beat)")
      end
    end

    // Extract: queue bytes land in the beat low lanes with lane 0 = bits
    // [7:0]; lanes at/above the extracted count are zeroed.
    begin
      bit [511:0] beat;
      byte unsigned q[$] = '{8'h0A, 8'h0B, 8'h0C, 8'h0D};
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::extract_beat_bytes(q, beat, 4, 64) != 4) ok = 1'b0;
      if (beat[7:0]   !== 8'h0A) ok = 1'b0;
      if (beat[15:8]  !== 8'h0B) ok = 1'b0;
      if (beat[23:16] !== 8'h0C) ok = 1'b0;
      if (beat[31:24] !== 8'h0D) ok = 1'b0;
      if (beat[63:32] !== '0) ok = 1'b0;
      if (beat[511:64] !== '0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "byte_queue: extract lane-0 mapping or zero-fill mismatch (extract)")
      end
    end

    // Round-trip through a partial beat: append 4 bytes, extract 4 bytes,
    // the reconstructed beat must equal the source lanes exactly.
    begin
      bit [511:0] src;
      bit [511:0] got;
      byte unsigned q[$];
      bit ok = 1'b1;
      src = '0;
      src[8*0 +: 8] = 8'h01;
      src[8*1 +: 8] = 8'h23;
      src[8*2 +: 8] = 8'h45;
      src[8*3 +: 8] = 8'h67;
      num_checked++;
      if (mac_hvl_utils_c::append_beat_bytes(q, src, 4, 64) != 4) ok = 1'b0;
      if (mac_hvl_utils_c::extract_beat_bytes(q, got, 4, 64) != 4) ok = 1'b0;
      if (q.size() != 0) ok = 1'b0;
      if (got[31:0] != src[31:0]) ok = 1'b0;
      if (got[511:32] != '0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "byte_queue: partial-beat round-trip mismatch (roundtrip)")
      end
    end

    // Short extraction: extracting more bytes than the queue holds returns
    // the actual count and zero-fills the remaining lanes.
    begin
      bit [511:0] beat;
      byte unsigned q[$] = '{8'hAA};
      int got;
      bit ok = 1'b1;
      num_checked++;
      got = mac_hvl_utils_c::extract_beat_bytes(q, beat, 4, 64);
      if (got != 1) ok = 1'b0;
      if (beat[7:0] !== 8'hAA) ok = 1'b0;
      if (beat[31:8] !== '0) ok = 1'b0;
      if (q.size() != 0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "byte_queue: short-extract count or zero-fill mismatch (short_extract)")
      end
    end

    // Invalid geometry/input returns -1.
    begin
      byte unsigned q[$];
      bit [511:0] beat;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::append_beat_bytes(q, beat, 65, 64) != -1) ok = 1'b0;
      if (mac_hvl_utils_c::append_beat_bytes(q, beat,  5,  4) != -1) ok = 1'b0;
      if (mac_hvl_utils_c::append_beat_bytes(q, beat,  1, 65) != -1) ok = 1'b0;
      if (mac_hvl_utils_c::extract_beat_bytes(q, beat, 65, 64) != -1) ok = 1'b0;
      if (mac_hvl_utils_c::extract_beat_bytes(q, beat,  5,  4) != -1) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "byte_queue: invalid input did not return -1 (invalid)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_be_vectors();
    // Known big-endian encode: 0x010203040506 -> bytes 01 02 03 04 05 06.
    begin
      byte unsigned q[$];
      bit ok = 1'b1;
      byte unsigned expected[6] = '{8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06};
      num_checked++;
      if (mac_hvl_utils_c::encode_be48(q, 48'h010203040506) != 6) ok = 1'b0;
      if (q.size() != 6) ok = 1'b0;
      foreach (q[i]) if (q[i] != expected[i]) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "be: encode_be48 wire order mismatch (enc_be48_known)")
      end
    end

    // Known big-endian EtherType encodes: IPv4 0x0800, IPv6 0x86DD,
    // VLAN 0x8100 -> MSB-first pairs.
    begin
      byte unsigned q[$];
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::encode_be16(q, 16'h0800) != 2) ok = 1'b0;
      if (q.size() != 2 || q[0] != 8'h08 || q[1] != 8'h00) ok = 1'b0;
      q.delete();
      if (mac_hvl_utils_c::encode_be16(q, 16'h86DD) != 2) ok = 1'b0;
      if (q.size() != 2 || q[0] != 8'h86 || q[1] != 8'hDD) ok = 1'b0;
      q.delete();
      if (mac_hvl_utils_c::encode_be16(q, 16'h8100) != 2) ok = 1'b0;
      if (q.size() != 2 || q[0] != 8'h81 || q[1] != 8'h00) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "be: encode_be16 wire order mismatch (enc_be16_known)")
      end
    end

    // 48-bit round-trip: encode then decode must recover the address and
    // leave the queue empty.
    begin
      byte unsigned q[$];
      bit [47:0] got;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::encode_be48(q, 48'hDEAD_BEEF_1234) != 6) ok = 1'b0;
      if (mac_hvl_utils_c::decode_be48(q, got) != 6) ok = 1'b0;
      if (got != 48'hDEAD_BEEF_1234) ok = 1'b0;
      if (q.size() != 0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "be: 48-bit encode/decode round-trip mismatch (rt48)")
      end
    end

    // 16-bit round-trip: encode then decode must recover the value and leave
    // the queue empty.
    begin
      byte unsigned q[$];
      bit [15:0] got;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::encode_be16(q, 16'h0800) != 2) ok = 1'b0;
      if (mac_hvl_utils_c::decode_be16(q, got) != 2) ok = 1'b0;
      if (got != 16'h0800) ok = 1'b0;
      if (q.size() != 0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "be: 16-bit encode/decode round-trip mismatch (rt16)")
      end
    end

    // Byte-order distinguishing vector: the first wire byte is the MSB.
    // A little-endian implementation would put 06 first / decode 0x060504030201.
    begin
      byte unsigned q[$];
      byte unsigned src[$] = '{8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06};
      bit [47:0] got;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::encode_be48(q, 48'h010203040506) != 6) ok = 1'b0;
      if (q.size() != 6 || q[0] != 8'h01 || q[5] != 8'h06) ok = 1'b0;
      if (mac_hvl_utils_c::decode_be48(src, got) != 6) ok = 1'b0;
      if (got != 48'h010203040506) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "be: byte order is not big-endian (byte_order)")
      end
    end

    // Short-queue decode is atomic: returns -1 and leaves the queue intact.
    begin
      byte unsigned q5[$] = '{8'h01, 8'h02, 8'h03, 8'h04, 8'h05};
      byte unsigned q1[$] = '{8'h08};
      bit [47:0] a;
      bit [15:0] v;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::decode_be48(q5, a) != -1) ok = 1'b0;
      if (q5.size() != 5) ok = 1'b0;
      if (mac_hvl_utils_c::decode_be16(q1, v) != -1) ok = 1'b0;
      if (q1.size() != 1) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "be: short-queue decode not atomic (dec_short)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_fcs_vectors();
    // Byte-order distinguishing vector: fcs_to_wire_bytes(0x12345678) must
    // produce wire bytes 78 56 34 12 (LSB-first). A big-endian conversion
    // would produce 12 34 56 78.
    begin
      byte unsigned q[$];
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::fcs_to_wire_bytes(q, 32'h12345678) != 4) ok = 1'b0;
      if (q.size() != 4) ok = 1'b0;
      if (q[0] != 8'h78 || q[1] != 8'h56 || q[2] != 8'h34 || q[3] != 8'h12) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "fcs: wire byte order is not LSB-first (byte_order)")
      end
    end

    // Known FCS vector: 0xC704DD7B -> wire bytes 7B DD 04 C7.
    begin
      byte unsigned q[$];
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::fcs_to_wire_bytes(q, 32'hC704DD7B) != 4) ok = 1'b0;
      if (q.size() != 4) ok = 1'b0;
      if (q[0] != 8'h7B || q[1] != 8'hDD || q[2] != 8'h04 || q[3] != 8'hC7) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "fcs: known FCS wire bytes mismatch (known)")
      end
    end

    // Wire-to-FCS: wire bytes 7B DD 04 C7 -> fcs 0xC704DD7B.
    begin
      byte unsigned q[$] = '{8'h7B, 8'hDD, 8'h04, 8'hC7};
      bit [31:0] got;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::wire_bytes_to_fcs(q, got) != 4) ok = 1'b0;
      if (got != 32'hC704DD7B) ok = 1'b0;
      if (q.size() != 0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "fcs: wire-to-FCS reconstruction mismatch (decode_known)")
      end
    end

    // Round-trip: FCS -> wire bytes -> FCS must recover the value.
    begin
      byte unsigned q[$];
      bit [31:0] got;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::fcs_to_wire_bytes(q, 32'hDEAD_BEEF) != 4) ok = 1'b0;
      if (mac_hvl_utils_c::wire_bytes_to_fcs(q, got) != 4) ok = 1'b0;
      if (got != 32'hDEAD_BEEF) ok = 1'b0;
      if (q.size() != 0) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "fcs: encode/decode round-trip mismatch (roundtrip)")
      end
    end

    // Short-queue decode is atomic: returns -1 and leaves the queue intact.
    begin
      byte unsigned q[$] = '{8'h7B, 8'hDD, 8'h04};
      bit [31:0] got;
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::wire_bytes_to_fcs(q, got) != -1) ok = 1'b0;
      if (q.size() != 3) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "fcs: short-queue decode not atomic (short)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_format_vectors();
    // Empty queue -> empty string (deterministic base case).
    begin
      byte unsigned q[$];
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::format_bytes(q, 8) != "") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "format: empty queue did not yield empty string (empty)")
      end
    end

    // Known rendering: two-digit lowercase hex, space separated.
    begin
      byte unsigned q[$] = '{8'h01, 8'h02, 8'h0a, 8'hff};
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::format_bytes(q, 0) != "01 02 0a ff") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "format: rendering mismatch (render)")
      end
    end

    // Wrapping: newline every bytes_per_line bytes.
    begin
      byte unsigned q[$] = '{8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08};
      bit ok = 1'b1;
      num_checked++;
      if (mac_hvl_utils_c::format_bytes(q, 3) != "01 02 03\n04 05 06\n07 08") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "format: wrap mismatch (wrap)")
      end
    end

    // Determinism: identical input always yields the identical string.
    begin
      byte unsigned q[$] = '{8'hde, 8'had, 8'hbe, 8'hef};
      string s1, s2;
      bit ok = 1'b1;
      num_checked++;
      s1 = mac_hvl_utils_c::format_bytes(q, 2);
      s2 = mac_hvl_utils_c::format_bytes(q, 2);
      if (s1 != s2 || s1 != "de ad\nbe ef") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "format: not deterministic (determinism)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_frame_c_vectors();
    // A canonical frame cloned via clone()/do_copy must compare equal to the
    // original (all fields, byte-by-byte payload).
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned pl[] = '{8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55};
      bit ok = 1'b1;
      a.da = 48'h00_11_22_33_44_55;
      a.sa = 48'h66_77_88_99_aa_bb;
      a.ether_type = 16'h0800;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      a.fcs = 32'hC704DD7B;
      a.fcs_present = 1'b1;
      a.direction = MAC_FRAME_DIR_RS_RX;
      a.result = MAC_FRAME_RESULT_CLEAN;
      a.sop = 1'b1;
      a.eop = 1'b1;
      a.eop_byte_count = 6;
      a.preamble_present = 1'b1;
      a.sfd = 8'hD5;
      num_checked++;
      if (!$cast(b, a.clone())) ok = 1'b0;
      if (b == null || !a.compare(b)) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "frame_c: cloned frame does not compare equal (clone_equal)")
      end
    end

    // The clone's payload array must be independent storage: mutating a
    // clone payload byte must not alter the original's byte.
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned pl[] = '{8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55};
      bit ok = 1'b1;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      num_checked++;
      if (!$cast(b, a.clone())) ok = 1'b0;
      if (ok) begin
        // SV array == is element-wise, not a handle test; non-aliasing is
        // proven by mutation below (in-place write through one handle must
        // not be visible through the other).
        b.payload[0] = 8'hFF;
        if (a.payload[0] !== 8'h00) ok = 1'b0;  // original mutated -> alias
        if (b.payload[1] !== 8'h11) ok = 1'b0;  // deep copy must be intact
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "frame_c: clone payload aliases original storage (clone_no_alias)")
      end
    end

    // After mutating the clone, do_compare must report a mismatch.
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned pl[] = '{8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55};
      bit ok = 1'b1;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      num_checked++;
      if (!$cast(b, a.clone())) ok = 1'b0;
      if (ok) begin
        b.payload[2] = 8'hEE;
        if (a.compare(b)) ok = 1'b0;  // must differ
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "frame_c: do_compare missed a payload mismatch (compare_mismatch)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_codec_vectors();
    // Header-only AXI frame (14 bytes, no FCS, no payload): all header
    // fields decode big-endian; metadata reflects no FCS / clean / no line
    // sideband.
    begin
      byte unsigned q[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(q, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(q, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(q, 16'h0800));
      if (mac_frame_codec_c::axi_to_frame(q, 8'h00, 14,
                                          MAC_FRAME_DIR_AXI_TX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.da != 48'h00_11_22_33_44_55) ok = 1'b0;
        if (f.sa != 48'h66_77_88_99_aa_bb) ok = 1'b0;
        if (f.ether_type != 16'h0800) ok = 1'b0;
        if (f.payload.size() != 0) ok = 1'b0;
        if (f.fcs_present !== 1'b0 || f.fcs !== '0) ok = 1'b0;
        if (f.direction != MAC_FRAME_DIR_AXI_TX) ok = 1'b0;
        if (f.result != MAC_FRAME_RESULT_CLEAN) ok = 1'b0;
        if (f.eop_byte_count != 14) ok = 1'b0;
        if (f.preamble_present !== 1'b0) ok = 1'b0;
        if (f.sop !== 1'b1 || f.eop !== 1'b1) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: header-only AXI frame mismatch (axi_header_only)")
      end
    end

    // Minimum AXI frame (14 + 46 payload, no FCS): payload byte-exact,
    // direction AXI_RX recorded.
    begin
      byte unsigned q[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(q, 48'hAA_BB_CC_DD_EE_FF));
      void'(mac_hvl_utils_c::encode_be48(q, 48'h00_01_02_03_04_05));
      void'(mac_hvl_utils_c::encode_be16(q, 16'h0800));
      for (int i = 0; i < 46; i++)
        q.push_back(i[7:0]);
      if (mac_frame_codec_c::axi_to_frame(q, 8'h00, 60,
                                          MAC_FRAME_DIR_AXI_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.direction != MAC_FRAME_DIR_AXI_RX) ok = 1'b0;
        if (f.payload.size() != 46) ok = 1'b0;
        foreach (f.payload[i]) if (f.payload[i] != i[7:0]) ok = 1'b0;
        if (f.fcs_present !== 1'b0) ok = 1'b0;
        if (f.eop_byte_count != 60) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: minimum AXI frame payload mismatch (axi_minimum)")
      end
    end

    // Multi-beat AXI frame (14 + 100 payload + FCS): spans 3 beats at 64
    // bytes; FCS decodes LSB-first and the final-beat lane count is the
    // supplied sideband value.
    begin
      byte unsigned q[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(q, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(q, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(q, 16'h86DD));
      for (int i = 0; i < 100; i++)
        q.push_back(8'h80 + i);
      void'(mac_hvl_utils_c::fcs_to_wire_bytes(q, 32'hDEAD_BEEF));
      if (mac_frame_codec_c::axi_to_frame(q, 8'h02, 54,
                                          MAC_FRAME_DIR_AXI_TX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.ether_type != 16'h86DD) ok = 1'b0;
        if (f.payload.size() != 100) ok = 1'b0;
        foreach (f.payload[i])
          if (f.payload[i] != 8'h80 + i) ok = 1'b0;
        if (f.fcs_present !== 1'b1) ok = 1'b0;
        if (f.fcs != 32'hDEAD_BEEF) ok = 1'b0;
        if (f.eop_byte_count != 54) ok = 1'b0;  // (14+100+4) mod 64
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: multi-beat AXI frame mismatch (axi_multi_beat)")
      end
    end

    // AXI sideband error maps to CRC error status while fcs_present stays
    // unset (no FCS in the byte stream).
    begin
      byte unsigned q[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(q, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(q, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(q, 16'h0800));
      if (mac_frame_codec_c::axi_to_frame(q, 8'h01, 14,
                                          MAC_FRAME_DIR_AXI_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.result != MAC_FRAME_RESULT_CRC_ERROR) ok = 1'b0;
        if (f.fcs_present !== 1'b0) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: AXI sideband error not mapped to CRC error (axi_sideband_err)")
      end
    end

    // Malformed AXI frames return -1: too short for the header, and an
    // FCS-present frame whose payload would underflow.
    begin
      byte unsigned q_short[$] = '{8'h00, 8'h11, 8'h22};
      byte unsigned q_under[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(q_under, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(q_under, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(q_under, 16'h0800));
      void'(mac_hvl_utils_c::encode_be16(q_under, 16'h1234));  // 16 bytes, fcs_present -> underflow
      if (mac_frame_codec_c::axi_to_frame(q_short, 8'h00, 3,
                                          MAC_FRAME_DIR_AXI_TX, 1500, f) != -1) ok = 1'b0;
      if (mac_frame_codec_c::axi_to_frame(q_under, 8'h02, 16,
                                          MAC_FRAME_DIR_AXI_TX, 1500, f) != -1) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: malformed AXI frame not rejected (axi_malformed)")
      end
    end

    // FCS-absent vs FCS-present distinguishing vector: the SAME 24-byte
    // queue (header + 6 payload + 4 wire-FCS bytes) must parse with all 10
    // trailing bytes as payload (fcs_absent) or with only 6 payload bytes
    // plus the LSB-first-decoded FCS (fcs_present).
    begin
      byte unsigned q[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(q, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(q, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(q, 16'h0800));
      for (int i = 1; i <= 6; i++)
        q.push_back(i[7:0]);
      void'(mac_hvl_utils_c::fcs_to_wire_bytes(q, 32'hCAFE_BABE));
      if (mac_frame_codec_c::axi_to_frame(q, 8'h00, 24,
                                          MAC_FRAME_DIR_AXI_TX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.payload.size() != 10) ok = 1'b0;  // all 10 trailing bytes
        if (f.payload[6] != 8'hbe || f.payload[9] != 8'hca) ok = 1'b0;
        if (f.fcs_present !== 1'b0 || f.fcs !== '0) ok = 1'b0;
      end
      q.delete();
      void'(mac_hvl_utils_c::encode_be48(q, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(q, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(q, 16'h0800));
      for (int i = 1; i <= 6; i++)
        q.push_back(i[7:0]);
      void'(mac_hvl_utils_c::fcs_to_wire_bytes(q, 32'hCAFE_BABE));
      if (mac_frame_codec_c::axi_to_frame(q, 8'h02, 24,
                                          MAC_FRAME_DIR_AXI_TX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.payload.size() != 6) ok = 1'b0;  // FCS excluded from payload
        if (f.payload[5] != 8'h06) ok = 1'b0;
        if (f.fcs_present !== 1'b1 || f.fcs != 32'hCAFE_BABE) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: FCS-absent/present not distinguished (axi_fcs_absent_present)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::build_rs_wire(
      bit [47:0] da, bit [47:0] sa, bit [15:0] et,
      byte unsigned payload[], bit with_fcs, bit [31:0] fcs_val,
      output byte unsigned wq[$]);
    wq.delete();
    for (int i = 0; i < 7; i++)
      wq.push_back(8'h55);
    wq.push_back(8'hD5);
    void'(mac_hvl_utils_c::encode_be48(wq, da));
    void'(mac_hvl_utils_c::encode_be48(wq, sa));
    void'(mac_hvl_utils_c::encode_be16(wq, et));
    foreach (payload[i])
      wq.push_back(payload[i]);
    if (with_fcs)
      void'(mac_hvl_utils_c::fcs_to_wire_bytes(wq, fcs_val));
  endfunction

  function void mac_hvl_utils_test_c::run_rs_codec_vectors();
    // Clean RS frame with generated FCS: preamble/SFD must be excluded from
    // the canonical fields (payload[0] is the first byte after the header,
    // never 0x55/0xD5), the header decodes big-endian, FCS decodes
    // LSB-first, and the recomputed CRC matches (CLEAN).
    begin
      byte unsigned pl[6] = '{8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15};
      byte unsigned wq[$];
      byte unsigned head[$];
      mac_frame_c f;
      bit [31:0] fcs;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(head, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(head, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(head, 16'h0800));
      foreach (pl[i]) head.push_back(pl[i]);
      fcs = mac_hvl_utils_c::compute_fcs32(head);
      build_rs_wire(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                    16'h0800, pl, 1'b1, fcs, wq);
      if (mac_frame_codec_c::rs_to_frame(wq, 6, 1'b0, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.preamble_present !== 1'b1 || f.sfd !== 8'hD5) ok = 1'b0;
        if (f.da != 48'h00_11_22_33_44_55 || f.sa != 48'h66_77_88_99_aa_bb ||
            f.ether_type != 16'h0800) ok = 1'b0;
        if (f.payload.size() != 6) ok = 1'b0;
        if (f.payload[0] != 8'h10 || f.payload[5] != 8'h15) ok = 1'b0;
        if (f.payload[0] == 8'h55 || f.payload[0] == 8'hD5) ok = 1'b0;
        if (f.fcs_present !== 1'b1 || f.fcs != fcs) ok = 1'b0;
        if (f.result != MAC_FRAME_RESULT_CLEAN) ok = 1'b0;
        if (f.direction != MAC_FRAME_DIR_RS_RX) ok = 1'b0;
        if (f.eop_byte_count != 6) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS preamble/SFD not excluded from fields (rs_clean)")
      end
    end

    // RS frame without FCS: fcs_present stays clear, fcs = 0, the trailing
    // bytes remain payload, and result is CLEAN (no CRC check performed).
    begin
      byte unsigned pl[8] = '{8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27};
      byte unsigned wq[$];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      build_rs_wire(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                    16'h0800, pl, 1'b0, '0, wq);
      if (mac_frame_codec_c::rs_to_frame(wq, 8, 1'b0, 1'b0,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.fcs_present !== 1'b0 || f.fcs !== '0) ok = 1'b0;
        if (f.payload.size() != 8) ok = 1'b0;
        if (f.payload[7] != 8'h27) ok = 1'b0;
        if (f.result != MAC_FRAME_RESULT_CLEAN) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS FCS-absent frame mismatch (rs_no_fcs)")
      end
    end

    // RS frame with a corrupted FCS: recomputed CRC disagrees -> CRC_ERROR.
    begin
      byte unsigned pl[6] = '{8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15};
      byte unsigned wq[$];
      byte unsigned head[$];
      mac_frame_c f;
      bit [31:0] fcs;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(head, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(head, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(head, 16'h0800));
      foreach (pl[i]) head.push_back(pl[i]);
      fcs = mac_hvl_utils_c::compute_fcs32(head) ^ 32'h0000_0001;
      build_rs_wire(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                    16'h0800, pl, 1'b1, fcs, wq);
      if (mac_frame_codec_c::rs_to_frame(wq, 6, 1'b0, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.result != MAC_FRAME_RESULT_CRC_ERROR) ok = 1'b0;
        if (f.fcs_present !== 1'b1) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS CRC error not classified (rs_crc_err)")
      end
    end

    // RS frame whose ether_type is a length field that disagrees with the
    // counted payload -> LENGTH_ERROR.
    begin
      byte unsigned pl[46];
      byte unsigned wq[$];
      byte unsigned head[$];
      mac_frame_c f;
      bit [31:0] fcs;
      bit ok = 1'b1;
      for (int i = 0; i < 46; i++) pl[i] = 8'h30 + i[7:0];
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(head, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(head, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(head, 16'h002A));  // length field, not type
      foreach (pl[i]) head.push_back(pl[i]);
      fcs = mac_hvl_utils_c::compute_fcs32(head);
      build_rs_wire(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                    16'h002A, pl, 1'b1, fcs, wq);
      if (mac_frame_codec_c::rs_to_frame(wq, 46, 1'b0, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.result != MAC_FRAME_RESULT_LENGTH_ERROR) ok = 1'b0;
        if (f.ether_type != 16'h002A) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS length error not classified (rs_len_err)")
      end
    end

    // RS frame with the wire error flag set on the final beat ->
    // ALIGNMENT_ERROR.
    begin
      byte unsigned pl[6] = '{8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15};
      byte unsigned wq[$];
      byte unsigned head[$];
      mac_frame_c f;
      bit [31:0] fcs;
      bit ok = 1'b1;
      num_checked++;
      void'(mac_hvl_utils_c::encode_be48(head, 48'h00_11_22_33_44_55));
      void'(mac_hvl_utils_c::encode_be48(head, 48'h66_77_88_99_aa_bb));
      void'(mac_hvl_utils_c::encode_be16(head, 16'h0800));
      foreach (pl[i]) head.push_back(pl[i]);
      fcs = mac_hvl_utils_c::compute_fcs32(head);
      build_rs_wire(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                    16'h0800, pl, 1'b1, fcs, wq);
      if (mac_frame_codec_c::rs_to_frame(wq, 6, 1'b1, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != 0) ok = 1'b0;
      if (ok) begin
        if (f.result != MAC_FRAME_RESULT_ALIGNMENT_ERROR) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS alignment error not classified (rs_align_err)")
      end
    end

    // Malformed RS frames return -1: too short for preamble+SFD+header, and
    // an FCS-present frame whose payload would underflow.
    begin
      byte unsigned wq_short[$];
      byte unsigned wq_under[$];
      byte unsigned empty_pl[];
      mac_frame_c f;
      bit ok = 1'b1;
      num_checked++;
      for (int i = 0; i < 10; i++)
        wq_short.push_back(8'h55);
      build_rs_wire(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                    16'h0800, empty_pl, 1'b0, '0, wq_under);  // 22 bytes, no FCS
      if (mac_frame_codec_c::rs_to_frame(wq_short, 10, 1'b0, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != -1) ok = 1'b0;
      if (mac_frame_codec_c::rs_to_frame(wq_under, 22, 1'b0, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, f) != -1) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: malformed RS frame not rejected (rs_malformed)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_axi_roundtrip_vectors();
    // FCS-present frame: canonical -> AXI bytes -> canonical must recover a
    // byte-exact frame (payload, FCS, FCS-present, direction, EOP count).
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned q[$];
      byte unsigned pl[10] = '{8'hA0, 8'hA1, 8'hA2, 8'hA3, 8'hA4,
                               8'hA5, 8'hA6, 8'hA7, 8'hA8, 8'hA9};
      bit ok = 1'b1;
      num_checked++;
      a.da = 48'h00_11_22_33_44_55;
      a.sa = 48'h66_77_88_99_aa_bb;
      a.ether_type = 16'h0800;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      a.fcs = 32'hC704DD7B;
      a.fcs_present = 1'b1;
      a.direction = MAC_FRAME_DIR_AXI_TX;
      a.result = MAC_FRAME_RESULT_CLEAN;
      a.sop = 1'b1;
      a.eop = 1'b1;
      a.eop_byte_count = 28;  // 14 + 10 + 4
      a.preamble_present = 1'b0;
      a.sfd = 8'h00;
      if (mac_frame_codec_c::frame_to_axi(a, q) != 0) ok = 1'b0;
      if (q.size() != 28) ok = 1'b0;
      if (mac_frame_codec_c::axi_to_frame(q, 8'h02, 28,
                                          MAC_FRAME_DIR_AXI_TX, 1500, b) != 0) ok = 1'b0;
      if (ok) begin
        if (!a.compare(b)) ok = 1'b0;
        if (b.eop_byte_count != 28) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: AXI FCS-present round-trip mismatch (axi_rt_fcs)")
      end
    end

    // FCS-absent frame: round-trip with no FCS; byte count is header +
    // payload only.
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned q[$];
      byte unsigned pl[6] = '{8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15};
      bit ok = 1'b1;
      num_checked++;
      a.da = 48'hAA_BB_CC_DD_EE_FF;
      a.sa = 48'h00_01_02_03_04_05;
      a.ether_type = 16'h86DD;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      a.fcs_present = 1'b0;
      a.fcs = '0;
      a.direction = MAC_FRAME_DIR_AXI_RX;
      a.sop = 1'b1;
      a.eop = 1'b1;
      a.eop_byte_count = 20;  // 14 + 6
      if (mac_frame_codec_c::frame_to_axi(a, q) != 0) ok = 1'b0;
      if (q.size() != 20) ok = 1'b0;
      if (mac_frame_codec_c::axi_to_frame(q, 8'h00, 20,
                                          MAC_FRAME_DIR_AXI_RX, 1500, b) != 0) ok = 1'b0;
      if (ok) begin
        if (!a.compare(b)) ok = 1'b0;
        if (b.fcs_present !== 1'b0) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: AXI FCS-absent round-trip mismatch (axi_rt_nofcs)")
      end
    end

    // A null canonical frame cannot be encoded.
    begin
      byte unsigned q[$];
      bit ok = 1'b1;
      num_checked++;
      if (mac_frame_codec_c::frame_to_axi(null, q) != -1) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: null frame not rejected by frame_to_axi (axi_rt_null)")
      end
    end
  endfunction

  function void mac_hvl_utils_test_c::run_rs_roundtrip_vectors();
    // FCS-present frame: canonical -> RS wire -> canonical recovers a
    // byte-exact frame; wire layout pins preamble/SFD and FCS byte order.
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned wq[$];
      byte unsigned fcs_q[$];
      byte unsigned pl[6] = '{8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF};
      bit ok = 1'b1;
      num_checked++;
      a.da = 48'h00_11_22_33_44_55;
      a.sa = 48'h66_77_88_99_aa_bb;
      a.ether_type = 16'h0800;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      a.direction = MAC_FRAME_DIR_RS_RX;
      a.result = MAC_FRAME_RESULT_CLEAN;
      a.sop = 1'b1;
      a.eop = 1'b1;
      a.eop_byte_count = 6;
      a.preamble_present = 1'b1;
      a.sfd = 8'hD5;
      // True FCS over DA+SA+type+payload so the decoder recomputes CLEAN.
      void'(mac_frame_codec_c::frame_to_axi(a, fcs_q));
      a.fcs = mac_hvl_utils_c::compute_fcs32(fcs_q);
      a.fcs_present = 1'b1;
      if (mac_frame_codec_c::frame_to_rs(a, wq) != 0) ok = 1'b0;
      if (wq.size() != 8 + 14 + 6 + 4) ok = 1'b0;
      if (ok) begin
        // [7 x 55] D5 | DA | SA | type | payload | FCS(LSB-first)
        for (int i = 0; i < 7; i++)
          if (wq[i] != 8'h55) ok = 1'b0;
        if (wq[7] != 8'hD5) ok = 1'b0;
        if (wq[8] != 8'h00 || wq[9] != 8'h11 || wq[10] != 8'h22 ||
            wq[11] != 8'h33 || wq[12] != 8'h44 || wq[13] != 8'h55) ok = 1'b0;
        if (wq[14] != 8'h66 || wq[19] != 8'hbb) ok = 1'b0;
        if (wq[20] != 8'h08 || wq[21] != 8'h00) ok = 1'b0;
        if (wq[22] != 8'hAA || wq[27] != 8'hFF) ok = 1'b0;
        // FCS on the wire LSB-first: fcs[7:0], [15:8], [23:16], [31:24].
        if (wq[28] != a.fcs[7:0] || wq[29] != a.fcs[15:8] ||
            wq[30] != a.fcs[23:16] || wq[31] != a.fcs[31:24]) ok = 1'b0;
      end
      if (mac_frame_codec_c::rs_to_frame(wq, 6, 1'b0, 1'b1,
                                         MAC_FRAME_DIR_RS_RX, 1500, b) != 0) ok = 1'b0;
      if (ok) begin
        if (!a.compare(b)) ok = 1'b0;
        if (!b.preamble_present || b.sfd !== 8'hD5) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS FCS-present round-trip mismatch (rs_rt_fcs)")
      end
    end

    // FCS-absent frame: round-trip with no FCS tail; preamble/SFD re-added
    // by the encoder and removed again by the decoder.
    begin
      mac_frame_c a = new("a");
      mac_frame_c b;
      byte unsigned wq[$];
      byte unsigned pl[4] = '{8'h10, 8'h11, 8'h12, 8'h13};
      bit ok = 1'b1;
      num_checked++;
      a.da = 48'hAA_BB_CC_DD_EE_FF;
      a.sa = 48'h00_01_02_03_04_05;
      a.ether_type = 16'h86DD;
      a.payload = new[$size(pl)];
      foreach (pl[i]) a.payload[i] = pl[i];
      a.fcs_present = 1'b0;
      a.fcs = '0;
      a.direction = MAC_FRAME_DIR_RS_TX;
      a.result = MAC_FRAME_RESULT_CLEAN;
      a.sop = 1'b1;
      a.eop = 1'b1;
      a.eop_byte_count = 4;
      a.preamble_present = 1'b1;
      a.sfd = 8'hD5;
      if (mac_frame_codec_c::frame_to_rs(a, wq) != 0) ok = 1'b0;
      if (wq.size() != 8 + 14 + 4) ok = 1'b0;
      if (mac_frame_codec_c::rs_to_frame(wq, 4, 1'b0, 1'b0,
                                         MAC_FRAME_DIR_RS_TX, 1500, b) != 0) ok = 1'b0;
      if (ok) begin
        if (!a.compare(b)) ok = 1'b0;
        if (b.fcs_present !== 1'b0) ok = 1'b0;
      end
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: RS FCS-absent round-trip mismatch (rs_rt_nofcs)")
      end
    end

    // A null canonical frame cannot be encoded.
    begin
      byte unsigned wq[$];
      bit ok = 1'b1;
      num_checked++;
      if (mac_frame_codec_c::frame_to_rs(null, wq) != -1) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "codec: null frame not rejected by frame_to_rs (rs_rt_null)")
      end
    end
  endfunction

  function mac_frame_c mac_hvl_utils_test_c::mk_cmp_frame(
      bit [47:0] da = 48'h00_11_22_33_44_55,
      bit [47:0] sa = 48'h66_77_88_99_aa_bb,
      bit [15:0] et = 16'h0800,
      bit [31:0] fcs = 32'hDEAD_BEEF);
    byte unsigned pl[4] = '{8'h12, 8'h34, 8'h56, 8'h78};
    mac_frame_c f = new("f");
    f.da = da;
    f.sa = sa;
    f.ether_type = et;
    f.payload = new[$size(pl)];
    foreach (pl[i]) f.payload[i] = pl[i];
    f.fcs = fcs;
    f.fcs_present = 1'b1;
    f.direction = MAC_FRAME_DIR_RS_RX;
    f.result = MAC_FRAME_RESULT_CLEAN;
    f.sop = 1'b1;
    f.eop = 1'b1;
    f.eop_byte_count = 4;
    f.preamble_present = 1'b1;
    f.sfd = 8'hD5;
    return f;
  endfunction

  function void mac_hvl_utils_test_c::run_compare_vectors();
    // Exact match: compare() returns 1, no diffs, identity recorded.
    begin
      mac_frame_c a = mk_cmp_frame();
      mac_frame_c b = mk_cmp_frame();
      mac_compare_result_c d;
      bit ok = 1'b1;
      num_checked++;
      if (!mac_compare_utils_c::compare(a, b, "exp", "act", d)) ok = 1'b0;
      if (d == null || !d.matched || d.diff_count() != 0) ok = 1'b0;
      if (ok && (d.expected_id != "exp" || d.actual_id != "act")) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "compare: exact match misreported (cmp_exact)")
      end
    end

    // DA mismatch: single "da" diff, expected != actual.
    begin
      mac_frame_c a = mk_cmp_frame();
      mac_frame_c b = mk_cmp_frame(48'h00_11_22_33_44_56);
      mac_compare_result_c d;
      bit ok = 1'b1;
      num_checked++;
      if (mac_compare_utils_c::compare(a, b, "exp", "act", d)) ok = 1'b0;
      if (ok && (d == null || d.matched || d.diff_count() != 1)) ok = 1'b0;
      if (ok && d.diffs[0].field != "da") ok = 1'b0;
      if (ok && d.diffs[0].expected_str == d.diffs[0].actual_str) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "compare: DA mismatch misreported (cmp_da)")
      end
    end

    // Payload byte mismatch at index 2: "payload[2]" diff with byte_index.
    begin
      mac_frame_c a = mk_cmp_frame();
      mac_frame_c b = mk_cmp_frame();
      mac_compare_result_c d;
      bit ok = 1'b1;
      b.payload[2] = 8'hFF;
      num_checked++;
      if (mac_compare_utils_c::compare(a, b, "exp", "act", d)) ok = 1'b0;
      if (ok && (d == null || d.matched || d.diff_count() != 1)) ok = 1'b0;
      if (ok && d.diffs[0].field != "payload[2]") ok = 1'b0;
      if (ok && d.diffs[0].byte_index != 2) ok = 1'b0;
      if (ok && d.diffs[0].expected_str != "56") ok = 1'b0;
      if (ok && d.diffs[0].actual_str != "ff") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "compare: payload byte mismatch misreported (cmp_payload)")
      end
    end

    // FCS mismatch: single "fcs" diff.
    begin
      mac_frame_c a = mk_cmp_frame();
      mac_frame_c b = mk_cmp_frame(48'h00_11_22_33_44_55, 48'h66_77_88_99_aa_bb,
                                   16'h0800, 32'h1234_5678);
      mac_compare_result_c d;
      bit ok = 1'b1;
      num_checked++;
      if (mac_compare_utils_c::compare(a, b, "exp", "act", d)) ok = 1'b0;
      if (ok && (d == null || d.matched || d.diff_count() != 1)) ok = 1'b0;
      if (ok && d.diffs[0].field != "fcs") ok = 1'b0;
      if (ok && d.diffs[0].expected_str == d.diffs[0].actual_str) ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "compare: FCS mismatch misreported (cmp_fcs)")
      end
    end

    // Error metadata mismatch: result enum differs -> single "result" diff.
    begin
      mac_frame_c a = mk_cmp_frame();
      mac_frame_c b = mk_cmp_frame();
      mac_compare_result_c d;
      bit ok = 1'b1;
      b.result = MAC_FRAME_RESULT_CRC_ERROR;
      num_checked++;
      if (mac_compare_utils_c::compare(a, b, "exp", "act", d)) ok = 1'b0;
      if (ok && (d == null || d.matched || d.diff_count() != 1)) ok = 1'b0;
      if (ok && d.diffs[0].field != "result") ok = 1'b0;
      if (ok && d.diffs[0].expected_str != "MAC_FRAME_RESULT_CLEAN") ok = 1'b0;
      if (ok && d.diffs[0].actual_str != "MAC_FRAME_RESULT_CRC_ERROR") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "compare: result mismatch misreported (cmp_result)")
      end
    end

    // EOP metadata mismatch: eop_byte_count differs -> single diff.
    begin
      mac_frame_c a = mk_cmp_frame();
      mac_frame_c b = mk_cmp_frame();
      mac_compare_result_c d;
      bit ok = 1'b1;
      b.eop_byte_count = 7;
      num_checked++;
      if (mac_compare_utils_c::compare(a, b, "exp", "act", d)) ok = 1'b0;
      if (ok && (d == null || d.matched || d.diff_count() != 1)) ok = 1'b0;
      if (ok && d.diffs[0].field != "eop_byte_count") ok = 1'b0;
      if (ok && d.diffs[0].expected_str != "4") ok = 1'b0;
      if (ok && d.diffs[0].actual_str != "7") ok = 1'b0;
      if (!ok) begin
        num_failed++;
        `uvm_error("UTIL_VECTOR", "compare: EOP metadata mismatch misreported (cmp_eop)")
      end
    end
  endfunction

  task mac_hvl_utils_test_c::run_phase(uvm_phase phase);
    phase.raise_objection(this);
    run_keep_mask_vectors();
    run_valid_bytes_vectors();
    run_keep_roundtrip_vectors();
    run_eop_pos_vectors();
    run_ceil_div_vectors();
    run_ipg_cycles_vectors();
    run_byte_queue_vectors();
    run_be_vectors();
    run_fcs_vectors();
    run_format_vectors();
    run_frame_c_vectors();
    run_codec_vectors();
    run_rs_codec_vectors();
    run_axi_roundtrip_vectors();
    run_rs_roundtrip_vectors();
    run_compare_vectors();
    phase.drop_objection(this);
  endtask

  function void mac_hvl_utils_test_c::report_phase(uvm_phase phase);
    if (num_failed == 0)
      `uvm_info("UTIL_TEST",
                $sformatf("PASS: %0d utility vectors checked", num_checked), UVM_LOW)
    else
      `uvm_error("UTIL_TEST",
                 $sformatf("FAIL: %0d of %0d utility vectors failed", num_failed, num_checked))
  endfunction

`endif // MAC_HVL_UTILS_TEST_SVH
