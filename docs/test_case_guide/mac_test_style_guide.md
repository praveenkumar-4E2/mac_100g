# MAC UVM Test Style Guide

The MAC test layer follows the reusable organization/style pattern observed in the AXI reference, but only MAC classes, sequences, configuration, and checking behavior are used.

## Required pattern

1. Each test file has a MAC-specific include guard.
2. A concrete test extends `mac_base_test_c` and registers with `` `uvm_component_utils ``.
3. The base test owns top configuration retrieval, environment configuration, reset/APB bootstrap, topology reporting, objections, and standard reporting.
4. A derived test overrides `configure_test()` only when it must change agent/configuration policy and `run_stimulus()` only for its scenario.
5. Sequences are factory-created, named for their scenario, and started on a typed MAC sequencer.
6. Tests wait for independently monitored completion; do not use an arbitrary delay as proof that a packet reached the DUT boundary.
7. Use component/type-oriented UVM message IDs and report a clear PASS/FAIL result. The scoreboard remains responsible for packet-level comparison.

## Reference example

- Base implementation: `src/hvl_top/test/mac_base_test.svh`
- Directed feature examples: `src/hvl_top/test/mac_payload_tests.svh`

```systemverilog
class mac_feature_test_c extends mac_base_test_c;
  `uvm_component_utils(mac_feature_test_c)

  extern function new(string name = "mac_feature_test_c",
                      uvm_component parent = null);
  extern virtual function void configure_test();
  extern task run_stimulus(uvm_phase phase);
endclass

function void mac_feature_test_c::configure_test();
  super.configure_test();
  // Set only feature-specific MAC environment policy here.
endfunction

task mac_feature_test_c::run_stimulus(uvm_phase phase);
  mac_feature_sequence_c seq_h;
  seq_h = mac_feature_sequence_c::type_id::create("feature_seq_h");
  seq_h.start(env_h.virtual_sequencer_h.client_ingress_seqr_h);
  // Wait for a monitored completion condition, then issue feature result.
endtask
```

Do not import AXI packages, inherit AXI tests, or copy AXI transfer fields.
