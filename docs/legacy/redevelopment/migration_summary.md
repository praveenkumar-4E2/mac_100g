# MAC UVM Migration Summary

## Scope and separation

The AXI testbench was used only as a read-only architectural reference.  All
changes are within `mac_100g`; there are no AXI package imports, includes,
scripts, environment variables, or runtime paths in the MAC build.

## AXI style extracted

- Layered UVM test/base-test, sequence, environment, agent, and checker roles.
- Configuration objects and `uvm_config_db` for topology and policy.
- Analysis FIFO expected/actual scoreboard architecture.
- Per-test simulator artifacts, batch execution, result parsing, regression
  summary, timeout protection, and a Makefile-oriented workflow.
- Explicit change tracking and final handoff documentation.

## MAC implementation

- Reset-aware strict-order packet scoreboard with configurable TX/RX and
  field-level comparisons, residual checks, and concise match/error summary.
- MAC-specific reference model connected to client ingress and line ingress;
  passive TX/RX monitors feed the actual side of the scoreboard.
- One MAC-local base test style with sanity, directed minimum/50/64/1500-byte
  payload, VLAN, parallel TX+RX, RX/TX PAUSE, and APB/RAL tests.
- Batch-only regression (`vsim -c`, `run -all`, `exit`) with a UVM timeout,
  per-test log/WLF folder, JSON result, and test/seed/status/error/warning/
  duration/log-file summary.
- Transaction events append to the same test log rather than creating a second
  transaction-log artifact.
- Executable RAL model: RO/RW/W1C field policy, reset metadata, all four group
  table entries, APB adapter, virtual-sequencer frontdoor binding, a passive
  APB predictor/mirror, and a real frontdoor read in the semantic register test.
- APB semantic readback covers version, control aliases, MAC address, frame
  limits, speed programming, PAUSE-TX configuration, and group table storage.
- Functional coverage includes MAC TX, MAC RX, and APB configuration
  covergroups; Make supports per-test UCDB/HTML generation and UCDB merging
  through `coverage_merge`.
- A standalone valid-RX test proves line-to-client delivery with an RX
  scoreboard match, independent of the parallel and PAUSE scenarios.
- PAUSE-TX RTL now generates a valid preamble/SFD/body/FCS line-side frame;
  PAUSE arbitration honours ready/valid; normal bridge debug output is opt-in.

## Validation

| Check | Status | Evidence |
|---|---|---|
| Compile | PASS | WSL `make compile`; no compile errors (six pre-existing input-port warnings). |
| RAL/APB semantic | PASS | `mac_register_access_test_c`: 93 APB transfers, frontdoor RAL read, UVM_ERROR=0, UVM_FATAL=0. |
| Functional smoke/features | PASS | Final WSL batch regression: 11/11 sanity, TX payload, valid RX, VLAN, max payload, APB/RAL, parallel TX/RX, and PAUSE tests passed. |
| Regression automation | PASS | `make regression SEED=20260809 REGRESSION_ID=coverage_closure_20260809`: batch flow terminated all tests automatically; parser errors=0 and warnings=0. |
| Coverage | PASS | APB coverage run generated UCDB and HTML; 19.70% covergroup coverage for the APB-focused baseline. |

## Remaining handoff recommendations

- Set coverage targets and add dedicated negative/stress tests for unhit bins;
  19.70% is the APB-test baseline, not a signoff threshold.
- Extend the reference model when new MAC transformations or drop policies are
  added; do not use observed output as an expected packet source for new
  features.
