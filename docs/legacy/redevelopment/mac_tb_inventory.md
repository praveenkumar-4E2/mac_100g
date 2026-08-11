# 100G MAC Testbench Inventory

## Scope

Target root: `D:\Qsemiai\VLSI\Documents\Protocols\Ethernet\100g\repo\mac_100g`.

Phase 0 inspection only: no HDL, HVL, simulation flow, or RTL file has been modified.  This document identifies the current baseline for subsequent phases.

## Structure

- `src/hdl_top`: MAC RTL, packages, interfaces, TX/RX/control/pause/statistics logic, CDC, register block, and integration top.
- `src/hvl_top/pkg`: test package assembly, constants/types/utilities, transaction logging, wait utilities, configuration, and RAL.
- `src/hvl_top/mac_agents`: AXI4-Stream, RS/MAC-wire, APB, and reset agents, each with configuration, item, sequencer, sequence, driver, monitor, agent, and top-level collection classes as applicable.
- `src/hvl_top/tb`: testbench top, environment, environment configuration, virtual sequencer/sequence, reference model, scoreboard, protocol checker, and coverage subscriber.
- `src/hvl_top/test`: base, TX/RX base behavior, smoke, payload, configuration-negative, and utility tests.
- `sim/Questasim`: `mac_compile.f`, `Makefile`, `run.do`, and `regression.list`.
- `docs`: protocol and prior improvement/redevelopment documentation.

The compile filelist compiles RTL packages/interfaces/modules followed by a single `mac_test_pkg`, which includes the HVL classes, and then `mac_tb_top`.  The filelist is wholly MAC-local.

## Current UVM architecture

- `mac_tb_top` constructs and publishes `mac_tb_cfg_c` before `run_test()`; that object owns required virtual interfaces plus bootstrap/configuration state.
- `mac_base_test_c` retrieves and validates the top configuration, accepts selected plusargs (`NUM_AXI_ACTIVE`, `NUM_AXI_PASSIVE`, `NUM_FRAMES`, `NUM_RS_FRAMES`, `LOGGER`), creates `mac_env_cfg_c`, configures agents/RAL/reset services, and scopes environment configuration through `uvm_config_db`.
- `mac_env_c` contains AXI, RS, APB, and reset agent collections; virtual sequencer; reference model; scoreboard; coverage; and protocol checker.  It connects monitor analysis ports to the relevant consumers in `connect_phase`.
- The test package has an explicit base-test-before-concrete-test ordering and factory registration.
- Concrete tests use objections, reset/bootstrap configuration, virtual sequences, bounded completion utilities, and outcome-specific UVM reporting.

## Scoreboard and reference model

`mac_reference_model_c` is a separate MAC-specific predictor.  AXI TX observations predict RS wire frames (preamble/SFD, padding, FCS); RS RX observations predict AXI client frames, while malformed and PAUSE frames intentionally produce no client expectation.

`mac_scoreboard_c` has four typed `uvm_tlm_analysis_fifo` inputs:

- expected/actual AXI transactions for RX checking;
- expected/actual RS frames for TX checking.

It drains each FIFO into an explicit queue, matches FIFO order, compares packet header/payload/error/FCS fields, counts TX/RX matches and mismatches, drains again in `check_phase`, and reports residual unmatched traffic as a UVM error.  `report_phase` prints a compact count summary.

Current limitations relevant to refactoring:

- matching is strict in-order only; it has no configurable key/policy or reordering support;
- no scoreboard-owned reset notification/queue flush exists;
- no per-transaction timeout/age tracking exists;
- compare enablement and expected-drop policies are implicit in the reference model rather than explicit checker configuration;
- comparison lacks a structured field-level diff/count summary and frame identifiers;
- VLAN fields are not represented in the currently compared transaction attributes, so no VLAN check/coverage should be claimed until transaction support exists.

## Coverage

`mac_coverage_c` is an analysis-implementation subscriber connected to both AXI and RS monitor streams.  It has `option.per_instance` covergroups and is enabled by `mac_env_cfg_c.has_function_coverage`.

- AXI coverage: payload length bins (including 46, 64, 1500), FCS, CRC error, final beat byte count, and FCS×CRC.
- RS coverage: payload length, FCS, combined CRC/length/alignment fault state, PAUSE classification, and PAUSE×fault.

Questa coverage flags and UCDB/HTML generation already exist in the Makefile.  There is no documented merged regression coverage target, coverage threshold, or consolidated coverage result directory.

## Logging, Makefile, and regression

The existing `sim/Questasim/Makefile` is substantially more structured than the AXI reference for normal execution:

- `help`, `check`, `compile`, optimized compile/run, batch/GUI modes, coverage compile/run/report, regression, audit, and clean targets;
- overrides for test, verbosity, seed, top, filelist, testlist, and waveform script;
- per-test `run_<TEST>/` log/WLF/UCDB folders;
- `+UVM_TESTNAME`, `+UVM_VERBOSITY`, and `-sv_seed` propagation;
- a testlist loop that ignores blank/comment lines and fails on detected UVM errors/fatals.

`regression.list` currently contains four baseline tests: smoke, utilities, deterministic TX payload, and TX base.  RX end-to-end is intentionally excluded pending a documented first-frame-loss issue.

Gaps against the requested framework are: no stable `logs/`, `results/`, or `coverage/` roots; no `PLUSARGS`, `DEFINES`, `SOURCE_DIR`, `LOG_DIR`, `RESULT_DIR`, or `COVERAGE_DIR` variables; no `smoke` alias; no seed-per-test mechanism; no timestamped regression run ID; no error/warning/duration extraction; no summary table or machine-readable result; and no regression coverage merge.

## Configuration and hardcoding baseline

Already appropriately configurable: agent counts, frame count, logger enable, RS error injection, coverage enable, test selection/verbosity/seed, virtual interfaces, reset/configuration delay, and agent active/passive state.

Values requiring Phase 1 classification before changing:

- `max_frame_octets = 65535`: valid RTL range; retain as a protocol/RTL constraint unless a test-specific override is needed.
- frame length bins (46/64/1500): coverage assumptions that need traceability to MAC requirements and explicit jumbo-frame policy.
- PAUSE destination `01:80:C2:00:00:01`, EtherType `0x8808`, opcode bytes: protocol-defined constants; centralize only if currently duplicated.
- reference-model preamble/SFD/FCS/padding constants: protocol behavior, not generic testbench configuration.
- fixed test defaults and directory naming: framework/test-specific values suitable for Makefile/configuration refactoring.

## Independence and risks

No MAC source/filelist/Makefile content references `axi4_avip-production`, AXI packages, AXI filelists, or AXI scripts.  The MAC project is independent at compile and runtime.

The main functional risk for refactoring is changing current predictor-to-scoreboard ordering or reset behavior while RX bring-up is already constrained.  Scoreboard changes must therefore preserve the existing TX/RX expected/actual flow and be validated first with the existing smoke and deterministic TX regression subset.  RTL is explicitly out of scope.
