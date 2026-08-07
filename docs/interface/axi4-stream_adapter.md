# AXI4-Stream Adapter — Feynman Notes for Juniors

> Goal: by the end you can explain the adapter to a friend who knows nothing about
> buses. If you can't, re-read the section you stuttered on.

## 1. What problem does it solve?

The MAC chip speaks two languages:

- **Outside world (AXI4-Stream)**: `tdata/tkeep/tvalid/tready/tlast/tuser`
- **Inside the MAC (mac_if)**: `valid/ready/data/keep/sop/eop/eop_pos/error/fcs_present`

The adapter is a **translator** between these two. It converts the handshake and
frame markers so the outside world doesn't have to know about MAC internals, and
vice versa.

```
  AXI4-Stream                   adapter                   mac_if
  (your testbench)      ──────► translator ──────►        (MAC)
  s_axis_tx_*                   TX adapter              tx_client_if
```

## 2. The ONE idea you must master first: the handshake

Every beat (one clock-cycle busload of 64 bytes) moves only when **both** sides agree:

> `tvalid` = "I (sender) have data ready right now"
> `tready` = "I (receiver) can accept data right now"
> **A transfer happens only on the clock edge where BOTH are high.**

Think of it like two people passing a heavy box:

- Person A says "I'm holding a box, ready to pass" (`valid`).
- Person B says "I'm ready to catch" (`ready`).
- The box only changes hands when *both* statements are true simultaneously.

If `valid` is high but `ready` is low, the sender **must hold the data stable**
and keep waiting. Never change the data mid-wait — the receiver may sample it at
any moment.

## 3. Decoding the signals in plain English

| Signal | What it really means | mac_if twin |
|---|---|---|
| `tdata` | 64 bytes of frame data (one beat) | `data` |
| `tkeep` | A "ticket" saying **which of the 64 byte slots actually hold a byte** | `keep` |
| `tvalid` | "data is present right now" | `valid` |
| `tready` | "I can accept right now" | `ready` |
| `tlast` | "this is the last beat of the frame" | `eop` |
| `tuser[0]` | error flag for this frame | `error` |
| `tuser[1]` | "FCS is included / FCS is valid" | `fcs_present` |
| (none) | "this is the first beat" — **invented** by the TX adapter | `sop` |

The two signals inside the MAC that AXI4-Stream doesn't have are `sop` (start of
packet) and `eop_pos` (how many valid bytes are in the final beat). AXI4-Stream
has no "start" bit, and it folds the byte count into `tkeep` — so the adapter
must **derive** these.

## 4. TX adapter — follow one frame through, like a story

You (the testbench) are the AXI master. You push a 3-beat frame:

- **Beat 1** — `tvalid=1`, `tkeep=all-ones`, `tlast=0`, frame bytes starting at
  `tdata[7:0]` (lane 0).
- **Beat 2** — `tvalid=1`, `tkeep=all-ones`, `tlast=0`.
- **Beat 3** — `tvalid=1`, `tkeep=partial (say 0x0F, 4 bytes)`, `tlast=1`.

What the adapter does, signal by signal:

- **Pass-through** (no translation needed): `tdata→mac_data`,
  `tkeep→mac_keep`, `tvalid→mac_valid`, `tlast→mac_eop`. Straight wires.
- **`tuser[0]→mac_error`**, **`tuser[1]→mac_fcs_present`**: the side-note bits
  become MAC status bits. Same idea, different name.
- **`eop_pos` = popcount of `tkeep`**: because `tkeep` must be contiguous ones,
  the number of set bits *is* the byte count. Beat 3's `0x0F` → `eop_pos = 4`.
  This is exactly the "how many bytes in this last box" number.
- **`sop` is derived from the *pre-handshake* frame state**, not translated:
  - Keep a memory of "is a frame currently in flight?" (`frame_active`).
  - `mac_sop = s_tvalid && !frame_active`: any presented beat while no frame is
    in flight **is** the first beat — asserted the very cycle it is presented,
    even while it stalls waiting for `tready`.
  - The memory updates **only on a real handshake** (`s_tvalid && s_tready`),
    so a stalled first beat keeps `sop` asserted until it transfers.
- **`mac_ready→s_tready`**: backpressure passes straight through (in AXI mode it
  is produced by the admission controller; see §4.2). When the MAC is busy,
  your `tvalid` simply stays high and waits.

### 4.1 How it knows a new transaction (the simplest view)

Think of the adapter as a **reader of sentences**. AXI4-Stream has an
"end of frame" marker (`tlast`, like a **period** at the end of a sentence) but
**no "start of frame" marker**. So the adapter answers "is this a new
transaction?" the same way *you* know a new sentence started:

> The previous sentence already ended (you saw a period), so the next word must
> start a new sentence.

It remembers just one fact: **"Am I currently inside a sentence?"**
(`frame_active`). `mac_sop = s_tvalid && !frame_active` — the answer is
**combinational**: any presented beat seen while the answer is "no" is marked as
a first beat, immediately, in the same cycle. The memory only changes on a real
handshake.

**Example A — one frame, two beats (a two-word sentence):**

```
cycle | tvalid tready | beat | tlast | "mid-frame?" memory | sop
  1   |   1      1    |  A   |  0    |   was NO  -> now YES |  1 (A starts it)
  2   |   1      1    |  B   |  1    |   was YES -> now NO  |  0 (already mid)
  3   |   0      -    |  -   |  -    |   NO                 |  0
```

Frame A-B is one transaction. The first beat carries `sop` in the same cycle it
transfers.

**Example B — two frames back-to-back (two sentences, no pause):**

```
cycle | tvalid tready | beat | tlast | "mid-frame?" memory | sop
  1   |   1      1    |  A   |  0    |   NO  -> YES         |  1 (frame 1 start)
  2   |   1      1    |  B   |  1    |   YES -> NO          |  0
  3   |   1      1    |  C   |  1    |   NO  -> NO          |  1 (frame 2 start!)
  4   |   0      -    |  -   |  -    |   NO                 |  0
```

Even though `tvalid` never dropped, the adapter still knows frame 2 is new —
because beat B's `tlast` reset the memory to "not mid-frame", so beat C is seen
as a fresh start.

**Example C — same frame, but the receiver stalls (backpressure):**

The "mid-frame?" memory only changes on a **real handshake**
(`tvalid && tready`). Waiting cycles don't touch it — and `sop` stays asserted
on the presented first beat the whole time it waits:

```
cycle | tvalid tready | beat | tlast | what happens
  1   |   1      0    |  A   |  0    | handshake NO -> wait, memory unchanged, sop=1
  2   |   1      0    |  A   |  0    | handshake NO -> wait, sop=1 (still the first beat)
  3   |   1      1    |  A   |  0    | handshake YES -> "new frame", sop=1, memory -> YES
  4   |   1      1    |  B   |  1    | handshake YES -> frame ends
```

A stalled first beat never loses its `sop`, and a stalled beat never tricks the
memory into thinking a new frame started.

**Why do it this way instead of a start bit?**

| Approach | Start-of-frame bit | Watch idle state (what the RTL does) |
|---|---|---|
| Needs an extra signal | AXI spec has none -> can't | No extra signal needed |
| Handles back-to-back frames | must clear/guard it | automatic (tlast resets memory) |
| Extra state | none | one flip-flop |
| Timing | immediate | `sop` is combinational (pre-handshake), same-cycle |

**One-line summary:** the adapter doesn't know "a frame started" — it knows "the
last frame *ended*" (saw `tlast`), so any presented beat when the memory says
idle is a new transaction, stamped `sop` in the same cycle. One flip-flop of
memory, `frame_active`, is the entire trick.

### 4.2 The admission controller (who is allowed to start a frame)

In AXI mode (`USE_AXI4=1`) a first beat may **not** be accepted just because
the MAC can buffer it. Frame starts are gated by a small admission controller
(`tx_axi_admission`) placed between the TX adapter and the capture path. The
first-beat ready gate is:

```
first_beat_ready = tx_enabled && pause_admit && pipeline_req_ready
```

- `tx_enabled` — TX enable bit (REG_GLOBAL_CONTROL[CTRL_TX_BIT])
- `pause_admit` — PAUSE gate permits data admission (not paused)
- `pipeline_req_ready` — TX scheduler request readiness (IPG complete,
  capture/builder idle)

When a first beat is presented and `first_beat_ready` is true, the controller
**admits** it: it pulses the internal scheduler start (`start_capture`) for
exactly one cycle and latches the frame-active state. The first beat itself is
accepted on the following cycle; **every later beat** follows capture capacity
(`c_ready`) only. No second admission is possible until the accepted `tlast`
closes the frame (or reset). Scalar TX metadata ports (`tx_dest_addr`,
`tx_src_addr`, `tx_length_type`) are **ignored in AXI mode** — the frame content
is the only payload.

Time diagram, one frame, first beat waits for admission:

```
cycle | tvalid tready | sop | admit pulse | capture sees
  1   |   1      0    |  1  |     1       | nothing (gated until accepted)
  2   |   1      1    |  1  |     0       | first beat (capture active)
  3   |   1      1    |  0  |     0       | interior beats
  ...
  N   |   1      1    |  0  |     0       | final beat (tlast), frame closes
```

## 5. RX adapter — the reverse journey

Now the MAC is the AXI master (it sends frames to you, the testbench):

- `mac_eop→tlast`, `mac_valid→tvalid`, `mac_data→tdata`: pass-through.
- **Accepted-frame-only policy (frozen):** only accepted frames are ever
  presented on the AXI RX stream. CRC errors, length errors, alignment errors,
  and filter drops terminate the frame inside the MAC; the client stream never
  sees them. The delivered frames' status is reported exclusively through the
  status outputs and statistics counters. Consequently:
  - `mac_error` is driven **0** for every delivered beat (a failing frame is
    never delivered), and
  - `mac_fcs_valid` is driven **0** — the wire FCS is always stripped before
    delivery, so AXI RX `tuser[1]` is **reserved-zero**.
  - `tuser = {6'b0, mac_fcs_valid, mac_error}` — for every delivered beat this
    is all zeros, and it is stable across the whole frame (no live status
    pulses on the sideband).
- `tkeep`: here's the only clever part. Inside the MAC, interior beats have full
  keep anyway, so the adapter outputs **all-ones for every interior beat, and the
  real (partial) keep only on the `tlast` beat.**

Why? Because a receiving AXI master is lazy: it can reconstruct the whole frame
by just counting bytes in the final beat's `tkeep`. It never needs to look at
interior keep.

## 6. Confusions decoded (the FAQ juniors actually have)

**Q: Is `mac_sop` in sync with the first beat's data, or late?**

Since the W1 fix, `mac_sop` is **same-cycle**: it is asserted from the moment
the first beat is presented (pre-handshake) until that beat is accepted, and it
is asserted exactly on the accepted first beat. A first beat that stalls keeps
its `sop`. An accepted interior beat never carries `sop`.

**Q: Why must `tkeep` be contiguous ones?**

`0b1011` (bytes 0, 1, 3 valid but not 2) is illegal per the AXI4-Stream spec.
`tkeep` is a *prefix mask* — always `(1<<n)-1`. This is exactly what makes
`eop_pos = popcount(tkeep)` legal: no gaps, so count = position.

**Q: When does data actually "move"?**

Only when `valid && ready` in the same cycle. Everything else is a wait. The
assertions in the adapter even check that a stalled beat stays unchanged, and
that the first accepted beat always carries internal `sop`.

**Q: Why does the RX adapter force interior `tkeep` to all-ones?**

The MAC's own `keep` is already all-ones on interior beats — so this is a
guaranteed rewrite, not a guess. It collapses the contract: "read the final
beat's keep, ignore the rest."

**Q: `tlast` vs `eop`, `tuser` vs `error`?**

Same concept, different bus vocabulary. `tlast` **is** `eop`; on TX, `tuser[0]`
**is** `error` and `tuser[1]` **is** `fcs_present`. On RX, `tuser` is
reserved-zero (accepted-frame-only policy — see §5): every delivered beat
carries `tuser = 0`, stable across the frame.

**Q: Why can't I get per-frame error status on the RX stream?**

Because a frame that fails CRC/length/alignment/filter is **never delivered**
(accepted-frame-only). If it were delivered with an error sideband, you'd have
to treat error-marked frames differently from clean ones in every consumer, and
a failing frame might be mis-consumed before the sideband arrived. Instead, the
failure is captured exactly once by the status/statistics path, where it
belongs. `tuser[1]` is reserved-zero because the wire FCS is always stripped:
there is no "valid FCS" indicator to report.

**Q: What is "lane 0"?**

The first byte of a frame must sit in the lowest byte lane of the first beat
(`tdata[7:0]`). No middle-of-beat alignment games — the MAC assumes lane-0
alignment.

**Q: What's combinational vs registered here?**

Nearly everything in both adapters is a plain wire (combinational). The *only*
registers are the `frame_active` flip-flops (one in each adapter, plus the
admission controller's frame state and metadata latch). The important change
from earlier revisions: `mac_sop` is **combinational** — derived from the
pre-handshake frame state — so the first accepted beat carries `sop` in the
same cycle, even after waiting through stalls.

**Q: How does the adapter know a frame started? It has no "start" bit from AXI.**

Exactly the trick: it watches for any *presented beat while idle*.
`frame_active` was 0 → this presented beat is the start, `sop` asserted
immediately. One flip-flop of memory does all the work.

**Q: Why does the first AXI beat take one extra cycle to be accepted?**

The admission controller (TX only) accepts the first beat only after it has
pulsed the internal scheduler start (IPG/PAUSE/TX-enable permitting). The beat
is presented with `sop` the whole time; `tready` rises once admission
completes. Interior beats are never delayed this way — they follow capture
capacity directly.

## 7. Trace it yourself (3-beat frame, no backpressure)

```
cycle | tvalid tready | tlast | tkeep    | mac_sop (same-cycle) | frame_active
  1   |   1      1    |  0    | all-ones |  1 (idle -> start)   | -> 1
  2   |   1      1    |  0    | all-ones |  0 (mid-frame)       | -> 1
  3   |   1      1    |  1    | 0x0F     |  0 (mid-frame)       | -> 0
  4   |   0      x    |  x    |   x      |  0 (nothing presented)|   0
```

Notice: `mac_sop` is high in cycle 1 — the same cycle the first beat transfers.
With admission (AXI mode) the first beat may wait a cycle or two for
`tready`; `mac_sop` stays high until the transfer. Now say it out loud: "sop
marks the first beat, from presentation until it is accepted."

## 8. Teach it back (one paragraph)

> The adapter is a translator between two bus languages. Both use a
> valid/ready handshake: data moves only when both sides agree. `tdata`,
> `tkeep`, `tlast`, `tuser` map 1:1 onto the MAC's `data`, `keep`, `eop`,
> `error` + `fcs`. The only new things are derived: `eop_pos` (count of valid
> bytes = popcount of keep) and `sop` (a marker saying "this is the first beat,"
> generated by watching whether a frame is already in flight — combinational,
> asserted from the first presentation until acceptance). On TX, the first beat
> is additionally gated by an admission controller (TX enable, PAUSE, and
> scheduler readiness) that pulses the internal frame start exactly once; all
> later beats follow capture capacity only. The RX direction is just the
> reverse, with the bonus rules that interior beats always carry full keep and
> that only accepted frames are delivered (`tuser` is zero on every beat). If I
> can explain that without notes, I understand the adapter.

## Reference

- `src/hdl_top/interfaces/axi4_stream_if.sv` — the AXI4-Stream bus definition
- `src/hdl_top/tx/tx_axi4_stream_adapter.sv` — TX (slave→mac_if) adapter
- `src/hdl_top/rx/rx_axi4_stream_adapter.sv` — RX (mac_if→master) adapter
- `src/hdl_top/interfaces/mac_if.sv` — the internal beat contract
- `src/hdl_top/integration/mac_top.sv` — where both adapters are instantiated
