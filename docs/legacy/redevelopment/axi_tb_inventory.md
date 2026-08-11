# AXI4 Reference Testbench Inventory

## Scope and separation

Reference root (read-only): `D:\Qsemiai\VLSI\Questasim_workspace\AMBA_VIP\axi4_avip-production\axi4_avip-production`.

This inventory records architecture and workflow patterns only.  No AXI source, build file, script, configuration, or generated artifact was changed.  Nothing in the target MAC testbench currently imports, includes, or executes content from this root.

## Structure

- `src/globals`: shared AXI package.
- `src/hdl_top`: AXI interface, master/slave BFMs, assertions, and HDL top.
- `src/hvl_top/master`, `slave`: agent packages, configuration, transaction objects, proxies, sequencers, adapters/converters, coverage, and optional slave memory.
- `src/hvl_top/env`: environment, environment configuration, virtual sequencer, and scoreboard.
- `src/hvl_top/test`: base test, concrete tests, master/slave sequences, virtual sequences, and test packages.
- `src/hvl_top/testlists`: named regression lists.
- `sim`: a shared compile filelist plus Cadence, Questa, and Synopsys flows.
- `doc`: architecture, verification plan, assertion plan, coverage plan, naming guidance, and user documentation.

The project uses package-per-layer compilation: globals; protocol/agent packages; sequence packages; environment package; virtual sequence package; test package; then HDL/HVL tops.

## UVM architecture

- Two protocol agents: master and slave.  Each has configuration, transaction, sequencer(s), driver/monitor proxy, and HDL BFM.
- `axi4_env_config` controls agent counts and feature presence (`has_scoreboard`, virtual sequencer, coverage-related agent options).
- `axi4_env` conditionally builds agents, a virtual sequencer, and a scoreboard; it connects monitor analysis ports to the scoreboard and assigns physical-interface configuration to each agent.
- Tests derive from `axi4_base_test`; virtual sequences coordinate master/slave channel sequences.
- Components are factory-created and registered with UVM macros.  Configuration is passed through objects and `uvm_config_db`.

## Scoreboard pattern

`axi4_scoreboard` is a `uvm_scoreboard` with a `uvm_tlm_analysis_fifo` per observed protocol channel and per role.  The environment makes all monitor-to-FIFO connections in `connect_phase`.

- Concurrent run-phase workers block on paired master/slave FIFOs and compare write address, write data, write response, read address, and read data traffic.
- Semaphores serialize each channel-specific comparison worker.
- The checker tracks transaction counts and detailed field pass/fail counters; `report_phase` emits channel and field summaries.
- The implementation is direct master/slave observation comparison; it does **not** expose a distinct protocol-independent predictor/reference-model boundary, timeout policy, reset-flush policy, or a compact end-of-test unmatched-item policy.

Reusable principle: isolate each observed stream in typed analysis FIFOs, pair transactions deliberately, compare at protocol-relevant granularity, retain counters, and report outcomes at end of test.  AXI channel semantics and field counters are protocol-specific.

## Logging, build, and execution

The Questa `makefile` provides `usage`, `compile`, `simulate`, `regression`, coverage merge/report, and cleanup.

- Compilation invokes `vlib`, `vlog -sv`, assertions/access/coverage options, a filelist, and `axi4_compile.log`.
- Simulation takes `test`, `uvm_verbosity`, `args`, and `test_folder`; it passes `+UVM_TESTNAME` and `+UVM_VERBOSITY` and records a test log and WLF under a per-run folder.
- The simulator saves a per-test UCDB and generates a per-test HTML report.
- `simulate_war_err` greps the simulation log for simulator errors plus `UVM_FATAL`, `UVM_ERROR`, and `UVM_WARNING` and prints artifact locations.
- The defaults are AXI-specific: base test, 32-bit data width, and the AXI filelist.

## Regression and coverage

`regression_handling.py` reads `src/hvl_top/testlists/<name>`, ignores comment lines, creates a timestamped folder for each selected test, and invokes `make simulate` for it.  The Makefile merges UCDBs with `vcover merge` and creates HTML with `vcover report`.

Coverage is implemented as agent-local `uvm_subscriber` components with covergroups, named coverpoints/crosses, `option.per_instance`, and sampling from observed transactions.  AXI coverpoints cover bursts, sizes, IDs, response codes, cache/protection/lock attributes, transfer mode, and key crosses.

Strengths to reuse: filelist-driven compilation, per-run artifacts, testlist filtering, timestamped regression isolation, UCDB save/merge, and HTML reporting.  Limitations to improve in MAC: the AXI regression helper does not capture seed, duration, UVM counts, or a machine-readable pass/fail summary; its Makefile ignores errors in key targets and hardcodes run locations.

## Coding and reporting style

- Lowercase, protocol-prefixed file/class names (`axi4_*`), one primary class per file, include guards, and package assembly files.
- UVM factory macros and phase methods are consistently used.
- Configuration class handles use an `_h` suffix; generated object names are descriptive.
- Reporting uses `uvm_info`, `uvm_error`, and `uvm_fatal` with component/type-oriented IDs and selectable UVM verbosity.
- Comments use section banners and function/class documentation, although the older codebase has inconsistent prose and spelling.

## Applicability assessment

The reference is a viable framework reference but is not a template to copy.  MAC should keep its protocol-aware predictor and its more modern configuration/validation style while adapting AXI's run isolation, artifact discovery, coverage merge, and Make-driven execution structure.
