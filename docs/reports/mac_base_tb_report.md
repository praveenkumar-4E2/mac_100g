# MAC Base UVM Testbench Architecture Review

Review scope: the RTL under `src/hdl_top`, the UVM environment under `src/hvl_top`, and the executable harness in `src/hvl_top/tb/mac_tb_top.sv`.  Findings labelled **confirmed** are directly visible in the source; **likely risk** needs a specification decision or simulation confirmation.

## 1. Executive Summary

**Verdict: C — MAJOR FOUNDATION CHANGES REQUIRED.** Do not begin a functional scoreboard or reference model until the transaction boundaries and monitor outputs are corrected. The environment has useful frame pack/unpack code, active/passive agent separation, clocking-block input sampling, and deep-copy implementations. However, the current monitors omit essential protocol/status information, the reference model only republishes the observed handle, and the top-level TX admission control is not transactionally coupled to the AXI stream.

The deliberate TODO implementations in `mac_sb.sv`, `mac_ref_model.sv`, and `mac_cov.sv` are not defects by themselves. The problem is that building them on the present transaction contracts would either compare unlike representations or miss drops, status, and backpressure behavior.

## 2. DUT Functional Understanding

`mac_top` is a dual-clock Ethernet MAC integration shell. It accepts an AXI4-Stream TX client frame (`s_axis_tx_*`), converts it to an internal `mac_if`, schedules/formats/transmits it as a native line-side frame (`tx_out_*`), and receives native line-side frames (`rx_in_*`) before validating, filtering, and emitting accepted frames on `m_axis_rx_*`. APB configures enable, promiscuous mode, size limits, PAUSE, and related functions.

Both `mac_rst` and `apb_rst` are active-high synchronous resets. `mac_clk` is the data clock; `apb_clk` is independent. The 512-bit streams transfer one 64-byte beat per successful handshake. TX and RX have variable, frame-dependent latency; they contain capture/format/CRC, RX preamble/CRC/length/filter stages, arbitration, configuration CDC, and PAUSE/control logic. The testbench currently forces TX output ready and RX AXI ready high, so it does not exercise output backpressure.

**Confirmed RTL concern:** `tx_axi4_stream_adapter.sv` assigns `mac_sop = mac_sop_r`, but `mac_sop_r` is updated only after `s_tvalid && mac_ready` in `always_ff`. Thus the first accepted AXI beat sees the previous SOP value, not SOP asserted combinationally for that beat. A one-beat frame has no accepted beat with SOP; a multi-beat frame can mark its second beat as SOP. This must be fixed in RTL or explicitly masked from verification before using TX results as a reference.

## 3. DUT Transaction / Protocol Model

| Boundary | Start / acceptance | Completion | Logical payload |
|---|---|---|---|
| AXI TX input | First `tvalid && tready`; frame context begins with first beat | Handshake of `tlast` | DA, SA, Length/Type, payload, optional supplied FCS; `tuser[0]` error, `tuser[1]` supplied-FCS flag |
| Native RX line input | `valid && ready` beat with `sop` | Handshake of `eop` | Preamble/SFD, header, body, optional FCS, final-beat error |
| Native TX line output | DUT asserts `valid && sop`, accepted by `ready` | `valid && ready && eop` | Formatted wire frame including preamble/SFD and generated or preserved FCS |
| AXI RX output | DUT asserts first `tvalid`; accepted by `tready` | Handshake of `tlast` | Accepted client frame; RX wire FCS is normally removed; `tuser` conveys error/FCS-valid semantics |

There is no request ID. Ordering is consequently expected to be in-order per path, but control/PAUSE arbitration means a scoreboard must distinguish data frames, control frames, and dropped RX frames. Reset aborts partial frames; no monitor currently publishes an explicit abort/drop event.

## 4. Current UVM Architecture

`mac_env_c` creates AXI and RS agent-top containers, a scoreboard, reference model, and coverage collector. Active AXI monitors feed the reference-model AXI input; passive RS monitors feed the TX-wire actual FIFO. The inverse is used for RX: active RS feeds the reference model and passive AXI feeds actual. This is the right high-level direction.

The implemented `mac_reference_model_c` is only a type-preserving pass-through. `mac_scoreboard_c::run_phase` and coverage callbacks are TODO. The reset-agent classes are skeletal and are not integrated into `mac_env_c`.

## 5. Current Testbench Strengths

- `axi_driver_c` and `rs_driver_c` wait for handshake rather than using a fixed latency.
- `axi_monitor_c` and `rs_monitor_c` create a new object per completed frame; neither republishes a mutable frame handle.
- `axi_item_c` and `frame_xtn_c` implement deep `do_copy`, payload-aware `do_compare`, `do_print`, and CRC computation.
- `mac_if.mon_cb` and `axi4_stream_if.mon_cb` use `#1step` input skew, a sound sampling intent for pre-edge RTL values.
- Active/passive agent construction is mostly correct: passive agents omit sequencer/driver and retain monitors by default.

## 6. Critical Issues To Fix Before Continuing

| Priority | Classification | Finding | Required action |
|---|---|---|---|
| Critical | Confirmed | TX AXI-to-`mac_if` SOP is registered after acceptance. | Correct `tx_axi4_stream_adapter`; prove SOP on the first accepted beat. |
| Critical | Confirmed | The reference model passes observed transaction handles unchanged. | Build direction-specific predictors that create new expected objects. |
| Critical | Confirmed | Current transaction classes do not encode observed timing, stream status, drops, source boundary, or transaction identity. | Split stimulus and observed/result types or add a neutral frame-observation type. |
| High | Confirmed | AXI driver can procedurally drive `vif.tready`, which is DUT-driven in `mac_tb_top`. | Remove `generate_backpressure` from this master driver; create a separate sink-ready driver for an AXI output agent. |
| High | Confirmed | Top-level permanently ties `tx_out_ready` and `axi_rx_if.tready` high. | Add configurable ready drivers and stall tests. |
| High | Confirmed | Reset agent has no VIF, driver behavior, sequence body, or environment connection. | Either remove it for now or implement one reset controller and reset notifications. |

## 7. Sequence Item Review

`axi_item_c` is a reasonable *AXI client frame request* and `frame_xtn_c` is a reasonable *wire-frame stimulus/observation*. They should not be a common expected/actual comparison type without normalization.

Problems:

- **Confirmed:** `length_error` and `alignment_error` in `axi_item_c` are randomized but `axi_driver_c::drive_frame` states that they are ignored. A sequence can claim coverage of an error that was never driven.
- **Confirmed:** `frame_xtn_c::post_randomize` leaves FCS random for `crc_error`, but no constraint says it differs from the computed CRC. The error can randomly be non-error.
- **Likely risk:** `insert_fcs=0` is not a normal wire RX frame for the current CRC validation path; it needs an explicit expected status rather than being treated as an ordinary legal frame.
- **Confirmed:** Neither item stores SOP/EOP time, first/last handshake cycle, byte count as observed, error/status pulses, configuration snapshot, or a correlation key.

Recommendation: retain `axi_item_c` for requests and `frame_xtn_c` for line frames, but introduce `mac_frame_obs_c` for monitors/predictors. It should contain `source`, `direction`, byte queue, header fields, `fcs_present`, `received_fcs`, `crc_error`, `length_error`, `alignment_error`, `filter_hit`, `drop_reason`, `first_cycle`, `last_cycle`, `accepted_cycle`, and an allocated `stream_id`. Only request-controlled fields should be `rand`; observed status and timing must not be randomized.

## 8. Interface / Clocking Review

The interfaces declare inputs-only clocking blocks, avoiding implicit clocking-block output drivers. That is a good solution for the connected RTL interfaces. Drivers use raw nonblocking assignments and sample ready through `drv_cb`, which can be safe when all signal ownership is singular.

**Confirmed issue:** `axi_driver_c::send_beat` writes `vif.tready` when `cfg_h.generate_backpressure` is set. On its TX-source interface, `tready` is an output of the DUT (`s_axis_tx_tready`). This is illegal ownership and can create X/multiple-driver behavior. Backpressure belongs in a driver for the AXI RX sink, not in the AXI TX source driver.

Both interfaces need protocol assertions located near the interfaces or bound to the DUT: stability of all source-controlled signals while `valid && !ready`; valid `keep`; SOP/EOP ordering; and reset quiescence.

## 9. Driver Detailed Review

`get_next_item()` / `drive_frame()` / `item_done()` is used correctly on the normal path, and completion waits for every accepted beat. However, no driver watches reset while blocked on ready. If reset asserts during `send_beat`, the driver can retain a request, continue to wait, then call `item_done()` as if it completed. There is no timeout either.

`axi_driver_c` correctly packs header bytes in network order and FCS bytes LSB-first. It must stop advertising unsupported `length_error` and `alignment_error` generation or implement a defined transport/error-injection mechanism.

`rs_driver_c` correctly holds a beat until ready. Its IPG delay counts only post-frame idle cycles and is not aware of reset. Its generated length-error EtherType is derived from a legal payload size but mutates a semantic field behind the sequence item's back; publish the actual driven value in a cloned driven-observation object.

## 10. Monitor Detailed Review

The monitors correctly reconstruct bytes only on successful handshakes and create fresh object handles. `axi_monitor_c` clears partial bytes on reset. `rs_monitor_c` does **not** check reset or clear `in_frame`, `frame_q`, idle/IPG state, or latched final fields. A reset mid-frame can contaminate the next frame or manufacture a false protocol error.

`axi_monitor_c` does not validate contiguous `tkeep`, `tkeep != 0`, `tlast` ownership, missing SOP semantics, FCS flag consistency across a frame, or a frame that remains incomplete forever. It also emits no timestamps or status metadata.

`rs_monitor_c::check_keep` samples raw `vif.keep/error/eop_pos` rather than `vif.mon_cb.*` after the monitor already captured the clocking-block sample. That reintroduces a race in the checker even though the capture path is race-aware. Use the sampled values stored in local fields. It also begins a frame after any handshake even when SOP is absent, reports an error, and still captures/publishes it; malformed traffic needs an explicit policy/event.

## 11. Driver vs Monitor Protocol Consistency

| Protocol event | Driver behavior | Monitor behavior | RTL expected behavior | Problem |
|---|---|---|---|---|
| AXI source beat | Holds beat until ready | Captures on handshake | Correct | Compatible; driver must not drive ready |
| AXI start | No explicit SOP in AXI | Infers frame from bytes/tlast | Adapter must derive SOP | Adapter SOP implementation is wrong |
| RS start | Drives SOP on first beat | Checks SOP but continues after missing SOP | SOP required | Malformed frame can be published |
| RS end | Drives EOP/eop_pos | Reconstructs at EOP | Correct | Reset and sampled/raw checker mismatch |
| Output stalls | Never driven in top | Monitor supports them | DUT supports ready | Untested |
| Reset | Only initial idle drive | AXI clears; RS does not | Abort partial frame | Inconsistent |

## 12. Agent / Sequencer Review

Both agents create a sequencer and driver only when active and monitor when `has_monitor` is true. This is reusable active/passive behavior. However, `mac_env_c::connect_phase` dereferences `monitor_h` for every configured agent without checking `has_monitor`; setting `has_monitor=0` causes a null-handle failure. Make the monitor mandatory for checking configurations or guard every connection.

The agent-top component instance names use strings such as `"active_agents[0]*"`. The star is appropriate in a config-db instance pattern, but should not be in the object instance name. Create as `"active_agents[0]"` and set config on `"active_agents[0]*"`.

## 13. Configuration Architecture Review

`mac_env_cfg_c`, `axi_agent_cfg_c`, and `rs_agent_cfg_c` are useful starts. They should be extended with clock/reset policy, output-ready behavior, monitoring/checking enable, per-agent direction, timeout cycles, error-policy, and a snapshot of operational APB configuration.

**Confirmed risk:** the top uses broad `uvm_config_db::set(null, "*", ...)` for all VIFs and `rst_done`. This is convenient but not robust in a multi-instance environment. Set VIFs/config objects at the intended agent paths from the test. Also replace top-level `#100ns` / `#50ns` configuration sequencing with a reset/configuration coordinator or an APB agent.

## 14. Reset Architecture Review

Initial reset is generated directly in `mac_tb_top`; it is synchronous in RTL but is deasserted with a blocking assignment immediately after `@(posedge mac_clk)`, creating scheduling ambiguity relative to DUT `always_ff` blocks. Deassert on a non-active edge or via clocking-block timing.

For any reset: sources must drive idle, abort and report the current item, monitors must discard partial state and emit an optional reset event, predictor/scoreboard queues must flush with a reason, and tests must wait for both reset release and APB configuration completion. A dedicated reset agent is useful only if random/mid-test reset is a requirement; otherwise implement a small reset controller plus reset event rather than retaining the current empty agent hierarchy.

## 15. Race Condition Analysis

The use of `mon_cb`/`drv_cb` input #1step is generally sound. The remaining races are: raw-signal reads in `rs_monitor_c::check_keep`; reset deassertion at a clock edge; `tx_start` generated sequentially from AXI valid instead of a request-level handshake; and optional TX-driver writes to DUT-owned `tready`. Fix those before interpreting failure/pass results.

## 16. Transaction Object Lifetime / Handle Analysis

Driver requests are read-only in the AXI driver. RS driver conceptually mutates the transmitted EtherType for length-error injection without changing `item`; this makes the sequence item an inaccurate record of what was driven. Both monitors allocate a new object for publication, which is correct.

The reference model's `write_axi` and `write_rs` publish the incoming monitor handle directly. Any subscriber could modify it and affect another subscriber; a predictor must create or clone a new expected object, then normalize fields before publishing.

## 17. False-Pass Risks

| False-Pass Risk | Why it hides an RTL bug | Severity | Fix |
|---|---|---|---|
| Count-only base tests | Equal frame counts do not prove data, FCS, padding, status, or ordering | Critical | Compare normalized expected/actual frames |
| Forced ready high | Backpressure bugs cannot occur | High | Add controlled output-ready agents |
| Pass-through reference model | It predicts no transformation | Critical | Implement independent behavioral predictor |
| Missing drop/status monitor | Bad RX handling may disappear without mismatch | Critical | Publish RX status/drop events |
| AXI item error fields ignored | Coverage may claim un-driven errors | High | Remove or map the fields |
| No timeout/end checks | Lost frame can leave queues unchecked | High | Add watchdogs and final queue audit |

## 18. False-Fail Risks

| False-Fail Risk | Why | Severity | Fix |
|---|---|---|---|
| Raw RS checker reads | May observe a different delta-cycle value than capture | High | Use stored `mon_cb` sample |
| Reset mid-frame | RS monitor retains partial state | High | Flush on reset |
| IPG checker | It assumes an exact rounded gap despite DUT-owned scheduling/backpressure | Medium | Check minimum IEEE gap at TX wire; disable only with documented reason |
| FCS-less frame | Transaction parser may treat it as normal despite RX CRC requirements | Medium | Define explicit malformed/drop expectations |
| Fixed `#1us` settling | Variable latency/regression load can be longer | Medium | Wait on observed completion/queues with timeout |

## 19. RTL Areas Requiring Strong Verification

Prioritize AXI adapter SOP and ready/valid stability; TX admission (`tx_start`, scheduler/IPG, frame capture); preamble/SFD/FCS insertion; RX preamble search, CRC residue, length/type and size checks; destination filtering/promiscuous mode; RX drop/status pulses; PAUSE/control arbitration; APB-to-MAC CDC; and the boundary between reset/configuration and traffic.

## 20. Recommended Future Reference Model Architecture

Use a `mac_predictor_c` UVM component with separate analysis implementations for TX-client AXI observations and RX-line observations. It must be behavioral, not copied from pipeline state machines.

```text
AXI TX input monitor -> tx_predictor -> expected wire-frame stream -> TX scoreboard
RS RX input monitor  -> rx_predictor -> expected client/result events -> RX scoreboard
```

TX predictor: validate input frame, model padding/FCS policy and configured control/PAUSE arbitration at an abstract level, then emit normalized line frames. RX predictor: parse wire bytes, validate preamble/SFD/FCS/length/filter/control policy using a configuration snapshot, emit either a client frame or a drop/status event. Predictors must clone/new output objects and reset their state on reset events.

## 21. Recommended Future Scoreboard Architecture

Use two in-order scoreboards initially, each with an expected FIFO and actual FIFO, plus a third FIFO for RX status events. There is no ID in the current protocol, so do not claim out-of-order support. Match TX input-derived expected wire frames to passive RS TX observations; match RS input-derived expected client frames/drop events to passive AXI RX and status observations. Compare bytes, FCS policy, header, payload, error/drop classification, and applicable latency bounds. On reset flush queues; at end-of-test fail for expected-but-missing or unexpected actual entries.

## 22. Scoreboard Readiness Verdict

**NO, FIX THE MONITOR FIRST.** The monitor objects do not carry enough information to compare all observable outcomes: RX drops/status pulses are not transactions, no timestamps/configuration snapshot are retained, AXI protocol violations are not represented, and reset handling is asymmetric. The current reference model cannot create expected transformations.

## 23. Recommended Functional Coverage Plan

| Coverage Item | Why Needed | Suggested bins | Suggested cross |
|---|---|---|---|
| Frame size | Boundary/padding validation | 46, 47, 1500, 1501, max configured | size x FCS mode |
| Length/Type | RX semantic split | <=1500, 1536, EtherType values | length/type x length-error |
| FCS | CRC policy | valid, corrupt, absent | FCS x accept/drop |
| Filter | Address behavior | local, broadcast, group-hit/miss, foreign, promiscuous | DA class x promiscuous |
| Stream shape | Beat assembly | one beat, exact 64, partial final, multi-beat | shape x backpressure |
| Errors/status | Visible outcomes | CRC, length, alignment, malformed preamble | injected fault x outcome |
| Reset | State recovery | idle, first beat, middle, final/stall | reset point x direction |
| TX control | Arbitration/IPG | data only, pause pending, config mode | traffic class x IPG/backpressure |

## 24. Recommended Assertion Plan

Add assertions for valid stability while stalled on all four stream boundaries; `keep` nonzero/contiguous and final `eop_pos` agreement; SOP exactly on first accepted beat and never mid-frame; no EOP before SOP; reset drives valid low/clears state; no output client traffic when RX disabled; and bounded eventual response where the architecture guarantees it.

Example interface property:

```systemverilog
property p_axi_stable_when_stalled;
  @(posedge clk) disable iff (rst)
    tvalid && !tready |=> tvalid &&
      $stable({tdata, tkeep, tlast, tuser});
endproperty
assert property (p_axi_stable_when_stalled);
```

For TX adapter SOP, assert that the first accepted AXI beat maps to an accepted internal beat with SOP in the same transaction; this assertion should fail on the present registered `mac_sop_r` implementation.

## 25. Recommended Sequence/Test Plan

Basic: one-beat minimum frame, exact-64-byte frame, multi-beat frame, idle gaps, consecutive frames. Random: legal random headers/payloads/FCS and randomized sink backpressure. Boundary: payload 46/47/1500, partial/full last beat, length/type threshold, configured min/max. Stress: sustained traffic, randomized ready, full buffering/IPG, pause/control contention. Reset: initial, idle, first/middle/final beat, stall, repeated resets. Error tests: corrupt FCS, invalid declared length, asserted line error, bad preamble/SFD, absent FCS only if specification defines the result. Add APB configuration sequences before traffic rather than procedural top-level writes.

## 26. Proposed Final UVM Architecture

```text
mac_test
  mac_env
    apb_agent (active)
    axi_tx_source_agent (active monitor + driver)
    rs_rx_source_agent (active monitor + driver)
    rs_tx_wire_agent (passive monitor)
    axi_rx_sink_agent (passive monitor + configurable ready driver)
    reset_controller/monitor
    tx_predictor -> tx_scoreboard
    rx_predictor -> rx_scoreboard
    status_monitor -> rx_scoreboard
    coverage_collector
```

A virtual sequencer is justified once tests coordinate APB, traffic, ready control, and reset. RAL is recommended if the APB map becomes a verification target, not merely fixed bring-up configuration.

## 27. Current Testbench Scorecard

| Area | Score | Rationale |
|---|---:|---|
| Transaction design | 5/10 | Good field packing/copying, inadequate separation and metadata |
| Interface design | 6/10 | Good input-skew intent; ownership/backpressure flaw |
| Driver correctness | 5/10 | Handshake loops good; reset/unsupported errors/top admission unresolved |
| Driver robustness | 3/10 | No reset abort or timeout |
| Monitor correctness | 5/10 | Basic reassembly works; missing status and RS reset bug |
| Monitor robustness | 3/10 | Weak malformed/stall/reset handling |
| Reset handling | 2/10 | Initial reset only; reset agent is nonfunctional |
| UVM architecture | 5/10 | Directional agents present; integration incomplete |
| Configurability | 4/10 | Useful objects, broad config paths and no APB agent |
| Reusability | 4/10 | Agent modes exist, but top hardwires VIFs/readies/config |
| Readiness for scoreboard | 2/10 | Event model insufficient |
| Readiness for reference model | 3/10 | Boundary monitors exist, transformations/status absent |

## 28. Prioritized Fix List

1. Fix and unit-test `tx_axi4_stream_adapter` SOP timing.
2. Remove DUT-ready driving from `axi_driver_c`; implement a distinct AXI sink ready controller.
3. Add reset-aware cancellation/state flush to both drivers and both monitors.
4. Introduce normalized observation/result transactions and RX status/drop monitoring.
5. Replace reference-model pass-through with two cloned, behavioral predictors.
6. Correct config-db instance naming/scoping and guard optional monitors.
7. Replace delay-based completion checks with monitored completion plus timeouts.

## 29. Recommended Development Order

1. Repair AXI adapter and prove its handshake/SOP assertions.
2. Stabilize interface ownership and add output-ready control.
3. Define transaction/event classes and monitor contracts; manually inspect captured frames.
4. Implement reset notification/flush and reset tests.
5. Add protocol assertions and negative monitor tests.
6. Implement TX and RX predictors independently.
7. Implement in-order scoreboards with final queue/timeout checks.
8. Add coverage, then constrained-random, stress, APB, PAUSE, and error sequences.

Validate each step with waveform evidence at the boundary being modeled before proceeding.

## 30. Example Improved Code

Correct the adapter SOP generation by deriving it from pre-handshake frame state, not a value registered after the handshake:

```systemverilog
assign mac_sop = s_tvalid && !frame_active;

always_ff @(posedge clk) begin
  if (rst) frame_active <= 1'b0;
  else if (s_tvalid && s_tready)
    frame_active <= !s_tlast;
end
```

For RS monitor reset handling and race-free checking:

```systemverilog
@(posedge vif.mon_cb);
if (vif.rst) begin
  frame_q.delete(); in_frame = 0; idle_cnt = 0; beats = 0;
  continue;
end
// Save mon_cb.keep/error/eop_pos into local sampled fields, then
// have check_keep() use those fields only.
```

For the AXI driver, delete the `vif.tready <=` branch. A separate RX-sink agent owns `tready` and can randomize it without conflicting with a DUT output.

## 31. Final Readiness Assessment

The environment is a promising bring-up framework, not yet a trustworthy checking foundation. Its strongest pieces are byte packing/reassembly and basic UVM agent structure. Its blockers are observable protocol correctness (especially AXI-to-MAC SOP), missing reset/event semantics, and the lack of a directional prediction contract.

**Final verdict: C — MAJOR FOUNDATION CHANGES REQUIRED. Do not start scoreboard/reference-model implementation until the driver/monitor/transaction architecture above is corrected.**
