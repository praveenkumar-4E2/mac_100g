# MAC UVM Test Layer

This MAC-local test layer follows the organizational pattern extracted from the AXI reference while retaining MAC-specific classes and protocol behavior.

```text
test/
  mac_base_test.svh             shared test setup, reset/APB bootstrap
  mac_sanity_test.svh           randomized bidirectional TX/RX sanity test
  sequences/
    axi_sequences/axi_seq.sv    AXI4-Stream client-ingress stimulus
    rs_sequences/rs_seq.sv      RS line-ingress stimulus
  virtual_sequences/
    mac_virtual_seq.sv          cross-agent MAC bootstrap sequence
../testlists/
  mac_regression.list           MAC regression selection
```

`mac_virtual_seqr.sv` stays in `tb/`: it is environment infrastructure, not a test scenario.  The sequence files are compiled through `mac_test_pkg.sv` using the MAC Questa filelist's explicit test-layer include directories.  No AXI source, package, include directory, or testlist is used.

The supplied traffic sanity test is `mac_sanity_test_c`; it sends ten random,
valid transactions through each MAC direction. New tests extend
`mac_base_test_c` and configure only the agents and scenario they require.
