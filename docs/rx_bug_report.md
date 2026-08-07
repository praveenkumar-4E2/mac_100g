# RX Path Bug Report — 100G MAC UVM Bring-up

**Test:** `rx_base_test_c` (+NUM_RS_FRAMES=10, LOGGER=1, QuestaSim 2024.1)
**Date:** 2026-08-07
**Status:** Fixed — RX BASE PASSED 10/10, UVM_ERROR = 0

---

## Summary

The RX bring-up test drove 10 clean RS frames (one without FCS) and expected 10
to appear on the AXI4-Stream RX interface. Two frames were dropped inside the
DUT and a third class of corruption went unnoticed because the test only
compared frame *counts*:

| Frame | Symptom | Root cause |
|-------|---------|------------|
| 1 (no FCS, 1220-byte body) | Dropped, `RX_STATUS crc_error` | `fcs_present` wire level sampled at EOP, repurposed by the next frame before the EOP drained |
| 10 (125-byte body) | Dropped, `RX_STATUS crc_error` | Partial EOP beat (< 64 bytes) padded with stale lanes |
| 2–9 (all FCS frames) | Delivered, but +4 bytes payload (FCS leaked) | `fcs_present` frame flag cleared before the EOP handshake sampled it |

## Bug 1 — `fcs_present` sampled at EOP instead of at SOP

### Symptom
Frame 1 (driven with `FCS_ON=0`, i.e. `fcs_present=0`) was dropped with
`crc_error`. Frame 10 of the first failing runs was also dropped for the same
reason (it was the last frame of the 8/10 run and followed the same wire-level
race).

### Root cause
`rx_crc_check` and `rx_length_check` sampled the *wire level* `in_fcs_present`
at the frame's **EOP handshake**. `fcs_present` is a level on the RS interface,
not a frame attribute. The RS driver repurposes it for the next frame
(`send_beat` drives `vif.fcs_present <= fcs_present` on every beat), so once the
driver started frame 2's beat 1 (`fcs_present=1`) while frame 1's EOP beat was
still draining through the pipeline (emit replay / backpressure), frame 1's EOP
evaluation read `fcs_present=1`:

```
CRC_CHK fcs_present=1 total=1220 crc=0f3d9813 residue=debb20e3 good=0 err=1
```

A 1220-byte FCS-less frame can never satisfy the CRC32 residue check, so the
frame was flagged `crc_error` and dropped.

### Fix
`rx_preamble_detect` now samples `in_fcs_present` **at SFD-found** (SOP of the
frame) into a flop `fcs_present_q` and exports it as `out_fcs_present`.
`rx_pipeline` forwards this registered frame attribute (`pre_stage_fcs_present`)
to the crc and length stages instead of the raw wire level. The flag is held
until the EOP beat has actually been consumed (cleared only after the handshake
in the FLUSH `!emit_valid` path).

## Bug 2 — Partial EOP beat padded to 64 bytes

### Symptom
Frame 10 (125-byte body = 56 + 64 + 5 lane structure) was dropped with
`crc_error`. The DUT counted `total=128` instead of 125:

```
CRC_CHK fcs_present=1 total=128 crc=62932081 residue=debb20e3 good=0 err=1
```

### Root cause
In `rx_preamble_detect` BODY state, the `in_eop` branch used

```systemverilog
if (total > 64) ... // full beat + FLUSH remainder
else begin
  stage_partial(64, in_data, out_cnt, 0, 1'b1);  // BUG: padded to 64
  ...
```

The `else` path was written for `total == 64`, but it also executes for
`total < 64` (any frame whose final beat contributes fewer than 8 bytes, e.g.
125 = 56 + 5). `stage_partial(64, …)` emitted 64 bytes with `keep_mask(64)`,
appending 3 stale/uninitialized lanes from `in_data` past the frame end. The CRC
and length stages then processed 128 bytes (64+64) instead of 125, the CRC
residue mismatch flagged `crc_error`, and the frame was dropped. Length
accounting was also wrong by 3.

### Fix
Emit the true byte count:

```systemverilog
stage_partial(total, in_data, out_cnt, 0, 1'b1);
emit_keep  <= keep_mask(total);
emit_pos   <= total;
```

## Bug 3 — Frame flag cleared before the EOP handshake

### Symptom
After fixing Bug 1, frames 2–9 were delivered but carried **4 extra bytes** (the
wire FCS appended to the payload). The count-based test still passed.

```
CRC_CHK fcs_present=0 total=162 ...  // frame 2 should be fcs_present=1
```

### Root cause
The FLUSH state stages the frame's final EOP beat *and* exits FLUSH on the same
edge:

```systemverilog
FLUSH: if (!emit_valid && flush_remain) begin
  stage_partial(out_cnt, '0, out_cnt, 0, 1'b1);  // stages the EOP beat
  ...
  state <= SEARCH;
```

Clearing `fcs_present_q` on that edge wiped the flag *before* the crc/length
stages consumed the EOP beat (their EOP handshake happens cycles later). With
`fcs_present=0` the length stage accounted 162−14=148 payload octets instead of
144; the emit stage then delivered `payload_octets` (148) for a Type frame,
sending `frame_buffer[18..165]` — 144 payload bytes plus the 4 FCS bytes.

### Fix
Do not clear `fcs_present_q` in the remainder-staging branch. It is cleared only
in the `!emit_valid` FLUSH branch, which runs after the staged EOP beat has been
consumed (safe by construction, and the flag is re-sampled at every SFD-found).

## Files changed

| File | Change |
|------|--------|
| `src/hdl_top/rx/rx_preamble_detect.sv` | `in_fcs_present`/`out_fcs_present` ports, `fcs_present_q` sampled at SFD-found, held through EOP consumption; partial-EOP beat emits true `total` bytes |
| `src/hdl_top/rx/rx_pipeline.sv` | Forward `pre_stage_fcs_present` (registered frame attribute) to `rx_crc_check` / `rx_length_check` instead of the wire level |

## How this helps in the future

1. **Frame attributes must be sampled at SOP.** Any per-frame side-band signal
   (fcs_present, pause flags, VLAN tags, …) on a streaming interface must be
   latched when the frame starts and carried with the frame data. Sampling
   levels at EOP is a race with the next frame whenever the pipeline can
   backpressure. Check every frame attribute against this rule when touching
   `rx_*` or `tx_*`.
2. **Partial beats: length must follow the count.** Any stage that re-packs
   beats (`stage_full` / `stage_partial`, flush remainders) must derive keep /
   eop_pos from the byte count it owns, never a fixed width. Grep for hard-coded
   `64` / `keep_mask(64)` next to a variable count.
3. **Clear flags only after the last consumer handshake.** When a staging FSM
   (FLUSH here) both emits the terminal beat and leaves the state, per-frame
   state must survive until the downstream handshake of that terminal beat.
   The safe pattern: clear on the *next* visit of the state with an empty stage.
4. **Count-based tests hide data corruption.** The RX BASE test compared only
   driven-vs-captured frame counts. A payload-size (and content) comparison
   between the RS driver item and the AXI monitor item turns silent +4-byte
   corruption into a hard failure. Consider adding payload byte comparison to
   `rx_base_test_c` and re-enabling `enable_ipg_check` now that the framing and
   timing races are resolved.
5. **Instrumentation first.** Two temporary `$display`s in `rx_crc_check` and
   `rx_length_check` (fcs_present, total, crc, residue at EOP) identified the
   exact failing frame semantics in one run. Keep a debug-flavored display
   pattern (guarded by a plusarg) available for future RX bring-up work.

## Remaining observations (not blocking)

- Per-frame backpressure stalls of ~150–200 cycles between frames (client/emit
  replay vs AXI adapter `mac_ready` flow control). Throughput-only; frames
  arrive intact. Worth a dedicated bandwidth/backpressure test later.
- `rx_frame_emit` hardwires `client_fcs_present = 1'b0`; the client stream never
  advertises FCS presence (the emit strips the FCS). Consistent today, but the
  AXI adapter / monitor cannot distinguish FCS-present streams until it is
  plumbed from `pre_stage_fcs_present`.
