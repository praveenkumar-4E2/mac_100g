# 100G Ethernet MAC Verification Environment Redevelopment Plan

## 1. Purpose and decision requested

This document is the implementation blueprint for redeveloping the MAC UVM environment. It is intentionally a planning document: it proposes no RTL or HVL changes and authorizes no implementation work. Each roadmap phase must be reviewed and approved before code is changed.

The target is a production-quality, reusable UVM environment for the MAC's AXI4-Stream client interfaces, line-side RS interface, APB register interface, reset behavior, statistics, and PAUSE/control behavior. The design should follow UVM Cookbook separation of concerns: transactions describe intent or observations, agents own protocol activity, the environment owns connectivity, sequences own stimulus, and scoreboards/predictors own functional checking.

## 2. Review scope and evidence

The review covered `src/hdl_top`, `src/hvl_top`, `src/globals`, `sim/Questasim`, documentation, package inclusion order, agent implementations, testbench top, and RTL integration. It also considered the current compile/run flow and generated run logs. The RTL itself is substantial and organized by TX, RX, control, PAUSE, registers, CDC, statistics, and integration. The verification code is distributed across `pkg`, `common`, `mac_agents`, `tb`, and `test`.

Important current status: source compilation succeeds, but an optimized Questa simulation has a pre-existing APB multi-driver error: APB request signals are procedurally driven through the testbench interface while also connected as DUT input nets. This must be resolved as an early framework blocker before claiming a passing end-to-end regression.

## 3. Current architecture in simple terms

### Direction naming used in this plan

To avoid the ambiguous terms “active,” “passive,” “TX agent,” and “RX
agent,” all paths are named from the DUT's point of view:

| Simple name | Interface | Meaning |
| --- | --- | --- |
| Client ingress | AXI TX input | Frame enters the MAC from the client. |
| Line egress | RS TX output | Frame leaves the MAC toward the Ethernet line. |
| Line ingress | RS RX input | Frame enters the MAC from the Ethernet line. |
| Client egress | AXI RX output | Frame leaves the MAC toward the client. |

An **ingress agent** drives traffic into the DUT. An **egress agent** observes
the DUT output; the client-egress agent also owns AXI `tready` because the
testbench is the downstream receiver. “Active” and “passive” remain UVM
implementation settings, but are not part of a component's name.

### What exists and why

| Area | Current implementation | Intended role | Assessment |
| --- | --- | --- | --- |
| RTL | `hdl_top/{tx,rx,pause,control,registers,statistics,integration}` | DUT implementation and integration | Retain; it is sensibly grouped by feature. |
| Interfaces | AXI4-Stream, native `mac_if`, APB, reset, stats, pause interfaces | Pin-level boundary between DUT and UVM | Retain, but define ownership/modports rigorously. |
| AXI and RS agents | Separate driver, monitor, sequencer, config, agent, and agent-top classes | Drive/observe client and line traffic | Retain the protocol knowledge, redesign role naming and topology. |
| APB agent | A relatively complete reusable agent plus a standalone APB unit test environment | Register programming and APB protocol checking | Retain and integrate into the MAC environment. |
| Reset agent | Reset item/driver/monitor/sequencer/top are present | Initial and future mid-test reset control | Retain only if random/mid-test resets are required; otherwise simplify to a reset controller/monitor. |
| Canonical frame utilities | `mac_frame_c`, codec, compare utilities, byte/CRC helpers | Normalize AXI and RS frame representation | Strong foundation; retain and make the single observation contract. |
| Environment | `mac_env_c` builds agent tops, checker, predictor, scoreboard, coverage | Connect monitors to checking | Redesign its responsibilities and use one configuration hierarchy. |
| Checking | Reference model, scoreboard, protocol checker, monitor checks and RTL assertions | End-to-end and protocol verification | Retain intent, redesign data model, matching, reset handling, and ownership. |
| Tests | Base TX/RX tests, deterministic sanity tests, negative config tests, utility tests | Bring-up and feature exercise | Archive most until the framework is stable; rebuild feature tests. |
| Build | Questa file lists, Makefile, regression list, unit APB file list | Compile/run/coverage execution | Retain Questa support; replace ad-hoc artifacts and add reproducible suites. |

### How the current MAC path interacts

```text
client-ingress agent -> DUT -> line-egress monitor
                            |          |
                            v          v
                 client-to-line predictor -> line-egress scoreboard

line-ingress agent -> DUT -> client-egress monitor
                          |          |
                          v          v
                 line-to-client predictor -> client-egress scoreboard

APB bootstrap task -> DUT register interface
reset agent/top-level reset -> DUT domains
```

The topology is directionally correct. However, the current implementation makes the active/passive position carry too much meaning, uses two transaction classes as both stimulus and observation, and lets the top-level bootstrap perform APB work that belongs to a sequenced agent.

## 4. Findings and architectural issues

### A. Transaction contract and checking

1. `axi_item_c` and `frame_xtn_c` mix requested fields, randomization controls, observed data, and error outcomes. For example, AXI fields for length/alignment errors are randomized although the AXI driver explicitly cannot drive them. A transaction must not claim a fault that was not represented at the interface.

   **Recommendation:** separate request items from a neutral `mac_frame_obs` observation/prediction object. The latter must carry source/direction, canonical bytes/header, FCS state, protocol result, filter/drop reason, timestamps, and a correlation ID. **Benefit:** one unambiguous contract for monitors, reference models, scoreboards, and coverage. **Trade-off:** an up-front conversion layer and migration effort.

2. The current reference model is a compact behavioral transform rather than a complete independent predictor. It does not model all configuration-dependent RX disposition, filtering, status/statistics behavior, reset flushing, PAUSE timing, or transaction correlation.

   **Recommendation:** implement separate client-to-line and line-to-client predictors using configuration snapshots and canonical observations. **Benefit:** localized, reviewable functional policy independent of pipeline timing. **Trade-off:** requires an agreed executable specification for every enabled feature.

3. The scoreboard polls analysis FIFOs on a time delay and compares in-order, without a robust transaction key, latency policy, reset event handling, expected-drop/status model, or independently configured timeouts.

   **Recommendation:** use analysis FIFOs/exports to feed per-direction queues, pair by explicit frame ID when available and in order only where protocol ordering guarantees it, centralize timeout policy, flush on reset with reason, and fail residuals in `check_phase`. **Benefit:** deterministic diagnostics and regression-safe completion. **Trade-off:** transaction IDs or carefully documented ordering assumptions are required.

4. Multiple layers check overlapping protocol facts: monitors report violations, the added protocol checker rechecks transaction content, and the RTL contains SVA. The responsibilities are not defined.

   **Recommendation:** define a checker ownership matrix: interface SVA for cycle invariants; monitor validation for malformed captures; predictor/scoreboard for transformations; register model/checker for configuration and side effects. **Benefit:** no duplicate noise and clearer debug ownership. **Trade-off:** some current checks will be moved or removed.

### B. Agent and sequence architecture

5. `axi_agent_c` is described as a “MAC Master TX Agent,” but is also used for the client-egress AXI output. `rs_agent_c` similarly represents both line ingress and line egress. Names describe implementation history, not the interface role.

   **Recommendation:** organize by simple data direction: `client_ingress_agent`, `client_egress_agent`, `line_ingress_agent`, and `line_egress_agent`, sharing protocol monitor/codec code where safe. **Benefit:** signal ownership and test intent are self-evident. **Trade-off:** more named wrappers/classes, but less ambiguity.

6. Agent-top containers exist only to allocate arrays. A single-DUT MAC normally has one instance of each endpoint; multi-DUT support is not actually completed.

   **Recommendation:** keep one agent instance per physical endpoint in `mac_env`; introduce a higher-level multi-instance environment only when multiple DUTs are a real requirement. **Benefit:** simpler topology and config paths. **Trade-off:** a future multi-port/multi-DUT wrapper is needed rather than incidental dynamic arrays.

7. `mac_virtual_seqr.sv` and `mac_virtual_seq.sv` are zero-length but included in the main package. `has_virtual_sequencer` exists with no usable implementation.

   **Recommendation:** either remove these placeholders during stabilization or implement a real virtual sequencer containing handles only for ingress/APB/reset sequencers. **Benefit:** avoids false abstraction; a real virtual sequence coordinates configuration, traffic, and reset. **Trade-off:** virtual sequencing adds structure that simple tests may not need, but is justified for feature scenarios.

8. The APB agent is feature-rich and has a good standalone unit harness, but the MAC environment does not instantiate or use it. The top-level `apb_bootstrap()` task directly drives APB.

   **Recommendation:** integrate one active APB agent and replace procedural bootstrap with an APB configuration sequence started by the virtual sequence. Preserve the APB unit environment as agent-level verification. **Benefit:** one bus owner, reusable configuration sequences, and no top-level multi-driver hazard. **Trade-off:** initial configuration moves later into UVM phasing and needs a well-defined reset/config handshake.

### C. Configuration, reset, and top-level ownership

9. Configuration is split between `mac_tb_cfg_c`, `mac_env_cfg_c`, agent configs, plusargs, hard-coded module values, and top-level procedural tasks. Some flags exist but are not consistently consumed (`has_axi_agents`, `has_rs_agents`, `has_virtual_sequencer`, APB counts).

   **Recommendation:** create one immutable `mac_env_cfg` assembled by the base test before child construction; it owns interfaces, feature enables, timing/protocol limits, agent roles, and test knobs. Agent configs are derived from it. Use typed config objects in `uvm_config_db` only at clear component scopes. **Benefit:** a single source of truth and reproducible tests. **Trade-off:** upfront config schema design.

10. Reset is driven initially by top-level defaults and subsequently by a reset agent. Completion is also coupled to APB bootstrap completion. This blurs physical reset, configuration completion, and test readiness.

   **Recommendation:** model reset as an explicit event service: reset asserted/deasserted events per domain, monitor notifications, and a separate `configuration_complete` event. Choose either a reset agent (required for random/mid-test reset) or a simple top-level reset controller (initial reset only). **Benefit:** deterministic queue flushing and clearer test sequencing. **Trade-off:** explicit event plumbing.

11. The testbench top contains DUT clocks, tick generation, RX-ready policy, APB bootstrap ownership, direct scalar tie-offs, status `$display` logging, and `run_test("mac_base_test_c")` alongside `+UVM_TESTNAME` usage.

   **Recommendation:** retain only synthesizable-like static harness wiring, clocks/resets, interfaces, DUT instantiation, and passive assertions in the top. Move all stimulus/configuration/readiness policies to UVM agents/sequences. Use `run_test()` with no fixed test name. **Benefit:** no competing ownership and correct command-line test selection. **Trade-off:** test startup must wait on explicit UVM events.

### D. Coverage, assertions, tests, and build

12. Coverage is currently enabled by a default-off flag, uses fixed bins tied to the present 512-bit port geometry, and does not have a coverage plan or closure targets. It does not cover configuration/state transitions comprehensively.

   **Recommendation:** write a feature-to-coverpoint matrix before implementation. Sample normalized observations and configuration state; cover boundaries, error/disposition, backpressure shape, reset position, PAUSE/control arbitration, APB configuration, and meaningful crosses. **Benefit:** measurable closure rather than incidental bins. **Trade-off:** coverage becomes a planned deliverable, not a by-product.

13. Assertions are mainly embedded in RTL and monitors. There is no documented bind strategy, assertion enable policy, or assertion test suite.

   **Recommendation:** keep design assertions where they express design invariants; add interface bind checkers for handshake stability, marker ordering, keep geometry, reset quiescence, and APB protocol. Make assertion enablement consistent across simulation/formal where applicable. **Benefit:** cycle-accurate failures separated from functional mismatches. **Trade-off:** bind module maintenance and simulator setup.

14. The repository includes build logs, transcripts, WLF/Questa work artifacts, backups, and one-off `*_console.log`, `*_v3.log`, `w5_*`, and bring-up files under `sim/Questasim`. The root README has no usable onboarding content. Makefile help references obsolete `mac_smoke_test` names.

   **Recommendation:** remove generated artifacts from version control, extend `.gitignore`, maintain versioned test lists/configurations only, and publish a short root README with prerequisites, exact commands, and test suites. **Benefit:** clean ownership and fast onboarding. **Trade-off:** historical debugging evidence must move to issue attachments or an archived reports area.

## 5. Tests to archive or remove until the framework is stable

These are useful evidence, but should not define the production regression at this stage.

| Item | Classification | Recommendation | Rationale |
| --- | --- | --- | --- |
| `mac_tx_sanity_test_c`, `mac_rx_sanity_test_c` | Directed bring-up/sanity | Archive as `legacy_bringup`; later replace with formal smoke tests | They directly inspect monitor queues and duplicate scoreboard functionality. |
| `tx_base_test_c`, `rx_base_test_c`, `mac_base_test_c` | Framework scaffolding | Keep a minimal base test; archive traffic-count tests | Count-only pass criteria are weaker than end-to-end checking. |
| `mac_hvl_utils_test_c` | Unit test | Keep, move to a unit-test suite | It is valuable but not a MAC integration regression test. |
| `axi_null_vif_negative_test_c`, `axi_count_mismatch_negative_test_c` | Negative configuration experiments | Keep only as a separate configuration-negative suite | They should intentionally fail and must never be in normal regressions. |
| `apb_unit_*` test family | APB agent unit verification | Remove | Standalone APB harness removed; APB register behavior is covered by the integrated APB agent in the main MAC environment. |
| `sim/Questasim/*console.log`, `*_v3.log`, `w5_*`, `base_hang.log`, `modelsim.ini.sanity_bak`, `run_base/` | Debug/temporary artifacts | Remove from working regression inputs; archive externally if needed | They are generated evidence, not source of truth. |
| Makefile references to `mac_smoke_test` | Stale experimental naming | Remove/update during build-flow phase | The named test does not exist. |

No test should be deleted before its coverage/reason is recorded. “Archive” means excluded from standard compilation/regression and retained under a documented legacy location or tagged baseline.

## 6. Target professional architecture

### Proposed hierarchy

```text
tb_top (static harness only)
  mac_test_base
    mac_env
      apb_agent                 (active)
      client_ingress_agent      (drives AXI TX input)
      client_egress_agent       (observes AXI RX output; owns tready)
      line_ingress_agent        (drives RS RX input)
      line_egress_agent         (observes RS TX output)
      reset_service             (agent or controller/monitor by requirement)
      mac_virtual_sequencer     (handles active sequencers only)
      mac_predictor
        client_to_line_predictor
        line_to_client_predictor
        register/config model
      mac_scoreboard
        line_egress_comparator
        client_egress_comparator
        status/statistics checker
      mac_coverage_subscriber
      protocol assertion bindings/checker subscribers
```

This retains interface agents and uses composition instead of an unnecessary “agent top” layer. The single environment represents one MAC instance. A system environment can instantiate multiple `mac_env`s later if required.

### Configuration strategy

Use a typed `mac_env_cfg` as the source of truth. It includes all virtual interfaces, enabled features, MAC address/filter tables, supported MTU/port width/speed, reset and timeout policy, APB defaults, error policy, coverage enablement, and agent active/passive roles. It is frozen after `build_phase`.

Tests should choose named configuration profiles and use plusargs only for externally useful overrides such as seed, test name, verbosity, and a documented profile. Protocol constants belong in a package; DUT dimensions come from parameters or interfaces; feature policy belongs in config. This avoids hidden hard-coded 64-byte/46-byte/1500-byte assumptions outside the protocol profile.

### Transactions and factory use

Use factory registration for every component, sequence, configuration object, request item, and normalized observation object. Factory overrides are permitted only at documented extension points: error injection, reference-model policy, sink ready policy, and feature-specific sequence/item variants. Do not use global instance overrides to alter unrelated behavior.

Each monitor publishes immutable normalized observations. Drivers consume request objects. Predictors create new expected observations; they never forward input handles. This makes cloning ownership and debug traceability explicit.

### Sequence and virtual-sequence architecture

Protocol sequences sit with their agents: APB read/write/configuration, client-ingress frame streams, line-ingress frame streams, client-egress ready/backpressure policies, and reset sequences. Feature virtual sequences coordinate them in a semantic order: reset, APB configuration, stimulus, expected status, completion/drain.

Feature tests contain only configuration-profile selection and one virtual-sequence launch. Tests must never directly reach through the environment to inspect monitor queues or call a driver's protocol task.

### Reference model and scoreboard

The model is transaction-level, not cycle-accurate. Client-to-line prediction covers header/preamble/SFD, padding, FCS selection/generation, IPG expectation where observable, PAUSE/control arbitration policy, and configured enable state. Line-to-client prediction covers preamble/SFD, FCS/length/error classification, filtering/promiscuous/control handling, PAUSE consumption, client delivery/drop, status, and statistics effects.

The scoreboard has separate directional comparators plus explicit status/statistics checking. It uses a documented ordering/correlation policy, bounded latency watchdogs, and reset-aware flushes. It emits a concise summary and field-level differences. No polling delay belongs in its functional algorithm.

### Coverage and assertion plan

Functional coverage samples normalized observations and configuration snapshots. Required groups include frame size and last-beat geometry, length/type boundaries, FCS mode and error, destination/filter outcome, drop/status outcome, AXI/RS stall patterns, reset position, APB configuration, PAUSE quanta/acceptance/expiry, and data-vs-PAUSE arbitration. Cross only causal factors and outcomes.

Assertions are divided into AXI, RS, APB, reset, and MAC integration sets. They cover valid/ready stability, `keep` shape, SOP/EOP legality, reset quiescence, APB setup/access sequence, and no delivery under disabled/paused conditions. A separate assertion regression produces distinct report IDs.

### Regression flow

Adopt named suites: `unit`, `smoke`, `feature`, `error`, `reset`, `stress`, `assertion`, and `coverage`. Every run has a unique output directory, immutable seed/config manifest, compile/elaboration/run status, UVM error scan, assertion summary, and optional UCDB merge/report. The default regression contains only stable passing smoke/feature tests. Negative tests run in an expected-failure target.

## 7. Phased redevelopment roadmap

| Phase | Deliverables | Dependencies / risks | Validation and approval gate |
| --- | --- | --- | --- |
| 0. Baseline and governance | Freeze a known baseline, manifest current failures, clean generated artifacts policy, write onboarding/build contract | Existing APB multi-driver prevents trustworthy E2E baseline | Clean compile, documented known simulation blocker, approved directory and naming rules |
| 1. Interface ownership and transaction contract | Endpoint-role map, modport/ownership contract, request vs observation classes, codec contract, frame ID policy | Needs agreement on AXI `tuser`, FCS, error, and control-frame semantics | Agent/unit tests prove byte order, CRC, partial beat, cloning, and correlation contract |
| 2. Core agent stabilization | Rebuild/rename AXI and RS endpoint agents; integrate APB active agent; decide reset service; eliminate top-level procedural bus ownership | High integration risk; preserve pin behavior while changing ownership | One directed TX, RX, APB, and reset smoke per endpoint; optimized elaboration must pass |
| 3. Environment and configuration | Single env config, real virtual sequencer, configuration profiles, reset/config events, static top simplification | Config migration can break legacy tests | Topology/config audit passes; all active sequencers reachable; no wildcard VIF dependencies |
| 4. Predictors and scoreboard | Independent client-to-line and line-to-client predictors, comparators, status/statistics checking, reset flush and timeout behavior | Requires signed-off behavioral decisions for drops/filtering/PAUSE | Deliberate mutation tests produce exactly one actionable mismatch; missing/unexpected/reset cases fail correctly |
| 5. Protocol assertions and coverage | Bind/checker framework, coverage plan, feature covergroups/crosses, coverage exclusions | Avoid duplicating monitor and scoreboard checks | Assertion suite and coverage report demonstrate planned bins on directed tests |
| 6. Feature test redevelopment | Smoke/boundary/error/reset/backpressure/APB/PAUSE/control/stress virtual sequences and tests | Depends on all previous phases | Feature matrix traceability complete; legacy tests archived; stable regression list approved |
| 7. Regression closure and handoff | CI-ready targets, UCDB merge, seed rerun support, dashboards, user guide, maintenance ownership | Runtime/coverage targets need agreement | Multiple-seed stable regression, reviewed coverage closure, sign-off checklist complete |

Each phase has a hard stop: do not begin the next phase if its validation gate is not met. This limits rework and preserves a runnable branch after every approved increment.

## 8. Compatibility policy

### Preserve where practical

- DUT module ports, RTL behavior, published register map, and synthesizable parameter interfaces.
- Existing APB agent protocol implementation and its standalone unit regression.
- Shared byte-order, CRC, frame-codec, and compare utility knowledge after it is covered by unit tests.
- Questa command-line compatibility and the ability to select a UVM test by `+UVM_TESTNAME`.
- Existing agent functionality where it conforms to the new ownership contract.

### Intentionally change during approved redevelopment

- Testbench-internal class/file names and hierarchy where role clarity requires it.
- Configuration object shape and config-db paths.
- Top-level procedural APB bootstrap, direct readiness control, debug `$display`, and fixed default test selection.
- Legacy test implementation and regression membership.
- Scoreboard/reference-model interfaces, once the normalized observation contract is approved.
- Generated artifacts and stale logs in source directories.

Compatibility adapters may be used temporarily for one approved migration phase only. They must have an owner and removal milestone; permanent dual architectures are prohibited.

## 9. Decisions and questions requiring confirmation

1. Which MAC features are product commitments for the first closure target: basic Ethernet only, PAUSE RX/TX, filtering, statistics/interrupts, all advertised speeds, jumbo/VLAN, and control frames?
2. What is the authoritative specification for AXI `tuser`, supplied-FCS behavior, error injection semantics, absent FCS, and RX delivery/drop policy?
3. Is a random/mid-stream reset a verified product requirement? This determines whether a full reset agent is justified.
4. Is randomized RX downstream backpressure required? If yes, confirm the desired policy model and performance limits.
5. Does the MAC have one logical instance only, or must the environment support multi-port/multi-DUT configurations now?
6. Must the APB agent replace bootstrap configuration in the first architecture phase, and which reset-domain sequencing rules apply to APB writes?
7. Which status/statistics counters and interrupts are architecturally observable and therefore scoreboard obligations?
8. What are required regression runtime, seed count, simulator versions, coverage targets, and CI environment?
9. Is a UVM Register Abstraction Layer required for APB, or are typed APB sequences sufficient for this project? RAL improves register reuse/coverage but adds model-maintenance cost.
10. Which legacy tests/logs must be retained for traceability, and where should archived artifacts live outside the active source tree?

## 10. Initial design decisions proposed for approval

1. One `mac_env` represents one DUT instance; endpoint agents replace generic active/passive agent tops.
2. The normalized observation object is the sole predictor/scoreboard/coverage contract.
3. APB configuration is agent-owned and virtual-sequence-driven; the top never drives APB after static initialization.
4. Virtual sequencing is used for multi-interface feature scenarios, not for simple protocol unit tests.
5. The scoreboard checks functional transformations; assertions check cycle/protocol invariants.
6. Legacy sanity and count-only tests are archived after replacement smoke tests pass.
7. No RTL functional behavior changes are made as part of environment redevelopment unless a separately approved RTL defect is demonstrated.

Approval of these decisions and the phase order is required before Phase 0 implementation begins.
