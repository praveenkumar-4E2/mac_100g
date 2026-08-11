# AXI-to-MAC Framework Migration Matrix

## Decision legend

- **[REUSE]** Generic framework pattern can be retained conceptually.
- **[ADAPT]** Architecture is useful, but implementation must be MAC-specific.
- **[REJECT]** AXI protocol behavior must not enter the MAC testbench.
- **[IMPROVE]** MAC already has a stronger implementation; retain it.
- **[NEW]** MAC needs framework work not present in a sufficient form in AXI.

| Priority | Area | AXI reference finding | MAC baseline | Decision | MAC Phase 1+ action |
|---|---|---|---|---|---|
| P0 | Scoreboard ingress | Typed monitor analysis ports connect to typed TLM analysis FIFOs in environment `connect_phase`. | Four typed expected/actual FIFOs are already connected from monitors and reference model. | [IMPROVE] | Preserve MAC's predictor boundary and explicit expected/actual FIFOs. Document each path and prevent accidental fan-in from multiple agents without a source key. |
| P0 | Scoreboard matching | AXI pairs per-channel master/slave transactions in concurrent workers. | MAC FIFO-pairs TX RS and RX AXI frames in strict order. | [ADAPT] | Keep packet-level FIFO matching; add configurable matching policy/keys only where MAC requirements justify it. Do not import AXI channel behavior. |
| P0 | Scoreboard checking | AXI has detailed field counters and end reporting. | MAC compares core header/payload/FCS/error fields and totals matches/mismatches. | [ADAPT] | Add MAC field-level result accounting/diffs, configurable check enables, and explicit expected-drop accounting. Include length, destination/source, EtherType, payload, FCS/CRC, and error semantics; add VLAN only after transaction support exists. |
| P0 | Scoreboard completion/reset | AXI has no clean generic timeout/reset flush contract. | MAC has residual end checks but no scoreboard reset policy or item age timeout. | [NEW] | Add a scoreboard configuration object/fields for timeout, reset flush/epoch policy, ordering, and enabled checks; connect reset notifications through MAC's reset service. |
| P0 | Logging | Per-test folders, simulator `-l`, compile log, grep-based UVM error report. | Per-test logs/WLF/UCDB exist under `run_<TEST>`. | [ADAPT] | Create configurable `logs/compile`, `logs/tests`, `logs/regression`, and `logs/summary` roots; retain per-run isolation, add timestamp/test/seed naming, and a single summary extractor. |
| P0 | Makefile | `usage`, compile, simulate, regression, UCDB merge; paths/defaults are hardcoded and errors are ignored. | Richer Makefile with check/compile/run/coverage/regression and configurable test/seed. | [IMPROVE] | Retain standard/optimized flow; add requested aliases (`smoke`, `coverage`) and variables (`SIMULATOR`, `PLUSARGS`, `DEFINES`, `SOURCE_DIR`, `LOG_DIR`, `RESULT_DIR`, `COVERAGE_DIR`). Do not copy AXI filelist/source names. |
| P0 | Regression | Testlist parser skips comments; timestamped folders; separate coverage merge. No seed/result metadata. | Testlist loop detects UVM errors/fatals but uses one seed setting and no detailed summary. | [ADAPT] | Implement a MAC-local regression runner/list format with per-test seed resolution, duration, UVM error/warning counts, status, log link, rerun command, and text/CSV-or-JSON summary. |
| P0 | Coverage | Agent `uvm_subscriber`s use per-instance covergroups, coverpoints/crosses; Makefile saves and merges UCDBs. | MAC subscriber already samples AXI/RS traffic and makes an HTML report per run. | [ADAPT] | Preserve existing legal MAC coverpoints; add regression UCDB merge and report root. Trace any new jumbo/VLAN/IPG/reset/configuration bins to requirements before adding them. Define coverage enable/threshold policy. |
| P1 | Structure | Layered globals, HDL, agents, env, sequences/tests, simulator folders, documentation. | Layered RTL/HVL with agent collections, `tb`, package assembly, and tests. | [IMPROVE] | Preserve current MAC-specific hierarchy. Add generated artifact directories and scripts without moving all classes solely to resemble AXI. |
| P1 | Configuration | Environment config owns agents and feature flags; agents receive config handles. | Top config + validated environment config + scoped `config_db` publication. | [IMPROVE] | Keep top-config ownership and validation. Add only scoreboard/logging/regression configuration needed for maintainability. |
| P1 | Test/sequence organization | Base tests and virtual sequences coordinate protocol roles. | Base test bootstraps reset/APB and delegates to virtual/agent sequences. | [IMPROVE] | Keep MAC execution flow; add tests only for verified MAC features and avoid AXI sequence reuse. |
| P1 | Reporting | UVM component messages plus Makefile greps. | UVM IDs plus compact scoreboard/test summaries. | [ADAPT] | Standardize summary markers so runner parsing does not depend on broad simulator text matching. |
| P2 | Naming/style | Protocol-prefixed lowercase files/classes, `_h` handles, package assembly, include guards. | MAC uses `_c` class suffix, descriptive names, Doxygen-style comments, package assembly. | [IMPROVE] | Retain the existing MAC convention; apply it consistently to newly introduced local framework files. |
| P2 | Utilities | Per-simulator Makefiles and a Python regression helper. | Wait utilities, transaction logger, source audit, and a single Questa Makefile. | [ADAPT] | Add a MAC-owned runner/parser only if Make becomes unwieldy; retain no dependency on AXI's Python helper. |
| P2 | Cleanup | Older AXI code has duplicated counters/comments and broad error ignoring. | MAC has prior improvement documentation and source audit. | [IMPROVE] | Avoid importing AXI weaknesses. Remove only confirmed obsolete MAC framework artifacts after replacement and validation. |
| Separation | AXI dependencies | AXI packages, BFMs, filelists, testlists, and paths are protocol/project-specific. | MAC compile filelist and package are MAC-local. | [REJECT] | Add a Phase 7 repository scan for AXI root/path/package/script references; no compile-time or runtime AXI dependency is permitted. |

## Proposed validation gates

1. Before each implementation phase, preserve the MAC compile filelist and RTL source set; do not edit `src/hdl_top`.
2. For a scoreboard change: compile, run `mac_smoke_test_c`, run `mac_tx_payload_50_test_c`, inspect `UVM_ERROR`/`UVM_FATAL`, and confirm scoreboard counts and generated logs.
3. For logging/Makefile changes: exercise `make help`, `make compile`, `make run TEST=mac_smoke_test_c`, and the smoke alias once introduced.
4. For regression: run the existing four-test baseline list, confirm a per-test status/seed/error/warning/duration/log record, and preserve a failing regression exit status.
5. For coverage: run at least the supported baseline coverage tests, produce per-test UCDB plus merged MAC-only report, and record threshold status.
6. After every phase: scan MAC files for AXI root/package/filelist/script references and verify no RTL source changed.

## Phase 0 conclusion

The MAC testbench should adopt AXI's framework ideas, not its AXI implementation.  The recommended next deliverable is `docs/mac_tb_target_architecture.md`, defining MAC-local artifact layout, run metadata contract, scoreboard configuration/reset contract, regression result schema, and coverage merge policy before any code changes.
