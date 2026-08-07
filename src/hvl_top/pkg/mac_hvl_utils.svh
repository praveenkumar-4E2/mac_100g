/**
 * @brief HVL façade-owned pure utility class (mac_test_pkg member).
 *
 * `mac_hvl_utils_c` is a stateless collection of static methods: keep-mask
 * legality, valid-byte/EOP derivation, integer/IPG arithmetic, byte-queue
 * append/extract, header endianness, FCS byte order, and deterministic
 * formatting. It is package-private (declared inside mac_test_pkg via this
 * include); the protected constructor prevents instantiation because every
 * member is static.
 *
 * Contract (per skills/utilities/proposal.md):
 *  - stateless and deterministic: no hierarchy access, no global counters,
 *    no uvm_config_db access;
 *  - methods return success/error information; they never issue uvm_error
 *    themselves (monitors/drivers/checkers choose the report context and
 *    severity);
 *  - width-parameterized helpers take the active interface geometry
 *    (DATA_WIDTH, KEEP_WIDTH) as arguments; the class defines no global width.
 *
 * This file is a member of mac_test_pkg (text-included), so it must NOT
 * declare `package`/`endpackage`. UTL-026+ fill in the methods with directed
 * vectors; the empty shell only proves the include order compiles.
 */
`ifndef MAC_HVL_UTILS_SVH
`define MAC_HVL_UTILS_SVH

  class mac_hvl_utils_c;
    protected function new();
    endfunction
  endclass

`endif // MAC_HVL_UTILS_SVH
