# P0: RTL Immediate-Fix Proposal

## Scope and Decision

This proposal covers only defects directly observed in the active RTL paths. The fixes must be completed and unit-tested before scoreboard results are trusted. They are not testbench workarounds.

## Immediate Issue 1 — TX AXI SOP Is One Handshake Late

**Classification:** confirmed functional defect  
**File:** `src/hdl_top/tx/tx_axi4_stream_adapter.sv`

### Evidence

`mac_sop` is assigned from `mac_sop_r`; `mac_sop_r` is only updated in the sequential block after `s_tvalid && mac_ready`. Therefore it represents the previous transfer. The first AXI beat is passed through with SOP low; for multi-beat frames SOP can be asserted on a later beat. This violates the internal `mac_if` transaction contract and can corrupt capture/framing.

### Required Change

Remove `mac_sop_r`. Derive SOP from the pre-handshake frame state and update state only on the same successful transfer.

```systemverilog
logic frame_active;

assign s_tready = mac_ready;
assign mac_valid = s_tvalid;
assign mac_data  = s_tdata;
assign mac_keep  = s_tkeep;
assign mac_sop   = s_tvalid && !frame_active;
assign mac_eop   = s_tlast;
assign mac_eop_pos = popcount_keep(s_tkeep);
assign mac_error = s_tuser[0];
assign mac_fcs_present = s_tuser[1];

always_ff @(posedge clk) begin
  if (rst)
    frame_active <= 1'b0;
  else if (s_tvalid && s_tready)
    frame_active <= !s_tlast;
end
```

### Required Assertions

- If `frame_active==0` and a beat is accepted, internal SOP is high on that beat.
- SOP remains asserted/stable while a first beat is stalled.
- An accepted EOP returns `frame_active` to zero.
- SOP is never asserted on an accepted interior beat.

## Immediate Issue 2 — TX Admission Is Not Coupled to AXI Frame Acceptance

**Classification:** confirmed architectural defect  
**Files:** `src/hdl_top/integration/mac_top.sv`, `src/hdl_top/tx/tx_pipeline.sv`, `src/hdl_top/tx/tx_scheduler.sv`

### Evidence

`mac_top` starts the TX pipeline from `tx_start && data_admit && cfg_control[0]`, while the AXI adapter independently forwards `s_axis_tx_tvalid` to the client capture interface. `mac_tb_top` compensates by generating `tx_start` sequentially from AXI `tvalid`. This is not a request/acceptance protocol: a first beat can be presented or accepted before the scheduler has admitted the associated frame, and a one-cycle start pulse can be lost when IPG/capture resources are unavailable.

The TX path's `req_ready` output is left open at the `mac_tx_path` instance, so the top has no outward indication that the scheduler can admit a request. `pause_admission_gate.data_req_ready` is only pause/busy policy; it is not the TX scheduler's true readiness.

### Required Change

Choose one of the following contracts and document it at the ports. Option A is preferred because it preserves AXI semantics.

**Option A — make AXI first-beat acceptance the admission point (preferred):**

1. Add a small request/metadata buffer before `tx_client_capture`.
2. Do not assert AXI `s_tready` for the first beat until scheduler, PAUSE, enable, and capture resource conditions all permit admission.
3. Latch request metadata and establish the capture state atomically on that first handshake.
4. Keep AXI `tready` under the same capture-resource policy for subsequent beats.

**Option B — retain a separate request channel:**

1. Expose `tx_req_valid`/`tx_req_ready` and frame metadata as an explicit request interface.
2. Require request handshake before any AXI data beat; assert a protocol error for data without an admitted request.
3. Drive `tx_start` internally from that handshake, not from a testbench process.

In both options, connect `mac_tx_path.req_ready` to an internal `tx_pipeline_req_ready` and derive the externally visible request readiness from the conjunction of scheduler, PAUSE, and TX-enable conditions.

### Required Assertions

- No data beat is accepted when no frame request is admitted.
- Each admitted request has exactly one first input beat and one EOP.
- An input request held valid while IPG is incomplete is not lost; it is accepted only once resources are available.
- AXI `tready` accurately reflects capacity, not a testbench timing pulse.

## Immediate Issue 3 — Speed Configuration Is Implemented but Disconnected

**Classification:** confirmed feature disconnect  
**Files:** `src/hdl_top/integration/mac_top.sv`, `src/hdl_top/registers/apb_cfg_bridge.sv`, `src/hdl_top/registers/reg_file.sv`

### Evidence

`reg_file.sv` implements `cfg_mac_speed` and `cfg_speed_override`, but `apb_cfg_bridge.sv` leaves those outputs open. `mac_top.sv` then declares them and drives `cfg_mac_speed` with a hardwired `3'b100`; `cfg_speed_override` is unused. TX IPG and PAUSE timer both consume the hardwired value. Software writes to the speed register therefore cannot affect hardware behavior.

### Required Change

Route both speed signals through the APB configuration bridge to `mac_top`. Define the effective speed policy explicitly, for example:

```systemverilog
assign effective_mac_speed = cfg_speed_override ? cfg_mac_speed : MAC_SPEED_100G;
```

Use `effective_mac_speed` consistently for TX IPG, PAUSE timing, and any speed-dependent interface logic. If runtime speed changes are unsupported, remove the writable register or return an error rather than silently ignoring it.

### Required Assertions and Tests

- Speed is stable while a frame is active, unless the design explicitly supports safe deferred application.
- APB write/readback of speed reflects the effective value at the MAC boundary.
- IPG and PAUSE-timer directed tests run for each supported speed.

## Immediate Issue 4 — RX AXI `tuser[0]` Uses a Frame-Drop Status Rather Than a Beat/Frame Error Contract

**Classification:** likely functional risk; resolve with specification decision  
**Files:** `src/hdl_top/integration/mac_top.sv`, `src/hdl_top/rx/rx_axi4_stream_adapter.sv`

### Evidence

`mac_top` maps `rx_mac_error = rx_frame_drop`, and `rx_axi4_stream_adapter` maps `mac_error` directly to `m_tuser[0]`. `rx_frame_drop` is a status result of the RX pipeline; it is not visibly registered with the emitted AXI frame or documented as stable across every stalled beat. Furthermore, a dropped frame normally has no AXI client output, making a sideband error on an emitted accepted frame semantically ambiguous.

### Required Decision and Change

Choose one contract:

1. **Accepted-frame-only AXI RX:** suppress invalid/dropped frames entirely; expose CRC/length/alignment/drop as separate status pulses/counters. Drive AXI `tuser[0]=0` for every emitted frame unless a defined delivered-frame error exists.
2. **Error-delivery AXI RX:** emit malformed frames intentionally and latch a per-frame error bit at first emitted beat, holding it stable through EOP and stall.

Do not use a late global status pulse as live AXI sideband data. Add an assertion that `m_tuser` is stable while `m_tvalid && !m_tready`.

## Immediate Issue 5 — Placeholder Assertions Do Not Protect the Boundary

**Classification:** confirmed verification gap  
**Files:** `tx_axi4_stream_adapter.sv`, `rx_axi4_stream_adapter.sv`, `tx_scheduler.sv`, `mac_top.sv`

Several RTL files contain comments beginning `ASSERT:` but no actual SVA. Replace the immediate boundary comments with synthesizable-neutral `ifndef SYNTHESIS` properties. Minimum set: source stability under stall, SOP/EOP ordering, keep/eop-pos correctness, TX admission uniqueness, reset output quiescence, and effective-speed stability during active TX.

## Implementation Order

1. Fix SOP (Issue 1) and add its assertion/unit test.
2. Select and implement a real TX admission contract (Issue 2); delete testbench-generated functional `tx_start` afterward.
3. Resolve speed configuration wiring (Issue 3).
4. Decide/document RX error delivery, then implement a stable sideband or status path (Issue 4).
5. Add assertions and run directed stall/reset regressions (Issue 5).

## Exit Criteria

- Lint finds no intentionally unconnected functional output (`req_ready`, speed configuration) on active paths.
- Unit simulations cover one-beat, multi-beat, pre-first-beat stall, IPG wait, output stall, and speed register read/write behavior.
- Assertions remain clean in directed and randomized backpressure tests.
- The UVM monitor/scoreboard work begins only after the corrected port contracts are frozen.
