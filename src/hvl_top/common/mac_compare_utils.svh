/**
 * @brief Structured canonical-frame comparison utilities (mac_test_pkg
 * member).
 *
 * The scoreboard needs more than a pass/fail bit: it must report exactly
 * which field or payload byte mismatched, the expected and actual values,
 * the byte index (for payload bytes), and the transaction identities of the
 * expected vs actual frame. These classes provide that structured diff.
 *
 * UTL-065 declares the diff entry, the result object, and the stateless
 * static compare() API; UTL-066 implements compare(). UTL-067 adds
 * comparison vectors.
 *
 * This file is a member of mac_test_pkg (text-included after the codec), so
 * it must NOT declare `package`/`endpackage`.
 */
`ifndef MAC_COMPARE_UTILS_SVH
`define MAC_COMPARE_UTILS_SVH

  // One field/byte-level mismatch between an expected and an actual frame.
  class mac_compare_diff_entry_c;
    string     field;        // "da", "sa", "ether_type", "fcs",
                             // "fcs_present", "direction", "result", "sop",
                             // "eop", "eop_byte_count", "preamble_present",
                             // "sfd", "payload.size", "payload[i]"
    string     expected_str; // formatted expected value
    string     actual_str;   // formatted actual value
    int unsigned byte_index; // payload byte index for payload[i], else 0

    function new();
    endfunction

    // Factory: `new` inside a method constructs the enclosing class, so this
    // builds an entry without Questa's `new Type(...)` parse limitation.
    static function mac_compare_diff_entry_c mk(string field = "",
                                                string expected_str = "",
                                                string actual_str = "",
                                                int unsigned byte_index = 0);
      mac_compare_diff_entry_c e;
      e = new();
      e.field        = field;
      e.expected_str = expected_str;
      e.actual_str   = actual_str;
      e.byte_index   = byte_index;
      return e;
    endfunction

    function string convert2string();
      return $sformatf("%s: expected %s, actual %s", field, expected_str,
                       actual_str);
    endfunction
  endclass

  // Structured result of comparing two canonical frames.
  class mac_compare_result_c;
    bit                       matched;  // 1 when no diffs were recorded
    mac_compare_diff_entry_c  diffs[$]; // ordered mismatch list
    string                    expected_id; // expected transaction identity
    string                    actual_id;   // actual transaction identity

    function new();
      matched = 1'b1;
    endfunction

    // Records one diff and clears matched.
    function void add_diff(string field, string expected_str,
                           string actual_str, int unsigned byte_index = 0);
      diffs.push_back(mac_compare_diff_entry_c::mk(field, expected_str,
                                                   actual_str, byte_index));
      matched = 1'b0;
    endfunction

    function int unsigned diff_count();
      return diffs.size();
    endfunction

    // One line per diff, for diagnostics / report rendering.
    function string convert2string();
      string s;
      foreach (diffs[i]) begin
        if (i > 0)
          s = {s, "\n"};
        s = {s, diffs[i].convert2string()};
      end
      return s;
    endfunction
  endclass

  // Stateless, static compare API. Compares in order; out-of-order matching
  // is not invented without a design requirement (per proposal.md).
  class mac_compare_utils_c;
    protected function new();
    endfunction

    // Fills `diff` (never null on return) with every mismatch between the
    // expected and actual canonical frame; returns matched.
    extern static function bit compare(mac_frame_c expected,
                                       mac_frame_c actual,
                                       string expected_id,
                                       string actual_id,
                                       output mac_compare_result_c diff);
  endclass

  // UTL-065: placeholder body — full comparison implemented by UTL-066.
  function bit mac_compare_utils_c::compare(
      mac_frame_c expected,
      mac_frame_c actual,
      string expected_id,
      string actual_id,
      output mac_compare_result_c diff);
    diff = new();
    diff.expected_id = expected_id;
    diff.actual_id   = actual_id;
    if (expected == null || actual == null) begin
      diff.add_diff("handle",
                    expected == null ? "null" : "object",
                    actual   == null ? "null" : "object", 0);
      return diff.matched;
    end
    if (expected.da !== actual.da)
      diff.add_diff("da", $sformatf("%h", expected.da), $sformatf("%h", actual.da), 0);
    if (expected.sa !== actual.sa)
      diff.add_diff("sa", $sformatf("%h", expected.sa), $sformatf("%h", actual.sa), 0);
    if (expected.ether_type !== actual.ether_type)
      diff.add_diff("ether_type", $sformatf("%h", expected.ether_type),
                    $sformatf("%h", actual.ether_type), 0);
    if (expected.fcs !== actual.fcs)
      diff.add_diff("fcs", $sformatf("%h", expected.fcs),
                    $sformatf("%h", actual.fcs), 0);
    if (expected.fcs_present !== actual.fcs_present)
      diff.add_diff("fcs_present", $sformatf("%0b", expected.fcs_present),
                    $sformatf("%0b", actual.fcs_present), 0);
    if (expected.direction != actual.direction)
      diff.add_diff("direction", expected.direction.name(), actual.direction.name(), 0);
    if (expected.result != actual.result)
      diff.add_diff("result", expected.result.name(), actual.result.name(), 0);
    if (expected.sop !== actual.sop)
      diff.add_diff("sop", $sformatf("%0b", expected.sop), $sformatf("%0b", actual.sop), 0);
    if (expected.eop !== actual.eop)
      diff.add_diff("eop", $sformatf("%0b", expected.eop), $sformatf("%0b", actual.eop), 0);
    if (expected.eop_byte_count != actual.eop_byte_count)
      diff.add_diff("eop_byte_count", $sformatf("%0d", expected.eop_byte_count),
                    $sformatf("%0d", actual.eop_byte_count), 0);
    if (expected.preamble_present !== actual.preamble_present)
      diff.add_diff("preamble_present", $sformatf("%0b", expected.preamble_present),
                    $sformatf("%0b", actual.preamble_present), 0);
    if (expected.sfd !== actual.sfd)
      diff.add_diff("sfd", $sformatf("%h", expected.sfd), $sformatf("%h", actual.sfd), 0);
    if (expected.payload.size() != actual.payload.size())
      diff.add_diff("payload.size", $sformatf("%0d", expected.payload.size()),
                    $sformatf("%0d", actual.payload.size()), 0);
    for (int i = 0;
         i < (expected.payload.size() < actual.payload.size()
              ? expected.payload.size() : actual.payload.size());
         i++) begin
      if (expected.payload[i] !== actual.payload[i])
        diff.add_diff($sformatf("payload[%0d]", i),
                      $sformatf("%02x", expected.payload[i]),
                      $sformatf("%02x", actual.payload[i]), i);
    end
    return diff.matched;
  endfunction

`endif // MAC_COMPARE_UTILS_SVH
