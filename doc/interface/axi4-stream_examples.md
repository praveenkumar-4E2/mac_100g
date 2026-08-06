# AXI4-Stream Driving Examples

> How to actually put data on the 512-bit AXI4-Stream bus, frame by frame.
> Read `axi4-stream_adapter.md` first if the handshake is new to you.

## 1. The driving recipe (memorize this)

A frame is sent as a stream of **beats**. Every beat is driven with the same
ritual:

1. Put the beat's `tdata`, `tkeep`, `tlast`, `tuser` on the bus.
2. Raise `tvalid`.
3. Wait until `tready` is high **in the same cycle** (the handshake fires).
4. Only then move to the next beat. Hold `tvalid` low between frames.

```
beat 1  ──► handshake ──► beat 2  ──► handshake ──► ... ──► last beat (tlast=1) ──► tvalid=0
```

Key rules from the RTL contract:

- **Lane-0 aligned**: the first byte of the data must be in `tdata[7:0]`.
- **`tkeep` is a prefix mask**: contiguous ones only, always `(1<<n)-1`.
- **Interior beats** (not last): `tkeep = all ones` (64 bytes).
- **Last beat** (`tlast=1`): `tkeep = (1<<n)-1` where `n` = valid bytes, `1..64`.
- A 64-byte-aligned frame ends with **full keep and `tlast=1`** — that's legal.

| Signal | Drive value | Width |
|---|---|---|
| `tdata` | frame bytes (DA/SA/LT + payload) | 512 |
| `tkeep` | byte mask (prefix of ones) | 64 |
| `tvalid` | 1 while presenting a beat | 1 |
| `tlast` | 1 only on the final beat | 1 |
| `tuser[0]` | error flag | 1 |
| `tuser[1]` | FCS present/valid | 1 |

### What your stream carries

You drive the **full frame body** — the MAC only wraps it:

```
your stream:  [ DA (6 B) | SA (6 B) | Length/Type (2 B) | payload ... ] [+ FCS if tuser[1]=1]
MAC adds:     preamble (7x 0x55) + SFD (0xD5) before it, FCS after it
```

- Bytes 0-13 of your first beat are the Ethernet header: **DA, SA, Length/Type**.
  They are part of the stream — do not add them twice.
- **Preamble and SFD are never sent by you.** The MAC's `tx_frame_builder`
  prepends `7 x 8'h55` + `8'hD5` on the wire.
- **FCS is appended by the MAC** (Clause 3.2.9), unless you assert `tuser[1]`
  (`fcs_present`) — then the last 4 bytes you send are treated as the FCS.

So a "64-byte frame" example below means 64 stream bytes = 14 header + payload.
The MAC turns them into `8 + 14 + payload` on the wire (preamble/SFD + header +
payload), then appends FCS.

## 2. Frame Example 1 — 64-byte minimum frame (1 beat)

A minimum Ethernet frame (64 bytes incl. FCS) fits **exactly** in one 64-byte
beat. The last beat has full keep.

```systemverilog
vif.tvalid <= 1'b1;
vif.tdata  <= 512'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F
             // ... fill 64 bytes across lanes 0..63
             ;
vif.tkeep  <= 64'hFFFF_FFFF_FFFF_FFFF;   // all 64 bytes valid
vif.tlast  <= 1'b1;                       // frame ends on beat 1
vif.tuser  <= 8'h00;                      // no error, no FCS flag
do @(posedge vif.clk); while (!vif.tready);
vif.tvalid <= 1'b0;
```

Cycle view:

```
cycle | tvalid tready | tdata | tkeep                 | tlast | result
  1   |   1      1    | 64 B  | all ones              |   1   | beat1 + frame done
  2   |   0      -    |  x    | x                     |   x   | idle
```

## 3. Frame Example 2 — 100-byte frame (2 beats)

100 bytes = beat 1 (64 B, full) + beat 2 (36 B, partial).

```systemverilog
// beat 1: bytes 0..63
vif.tvalid <= 1'b1;
vif.tdata  <= beat1;                       // 64 bytes, lane 0 first
vif.tkeep  <= 64'hFFFF_FFFF_FFFF_FFFF;
vif.tlast  <= 1'b0;
vif.tuser  <= 8'h00;
do @(posedge vif.clk); while (!vif.tready);

// beat 2: bytes 64..99 (36 bytes) — partial keep, tlast=1
vif.tvalid <= 1'b1;
vif.tdata  <= beat2;                       // only lanes 0..35 meaningful
vif.tkeep  <= 64'h0000_000F_FFFF_FFFF;     // (1<<36)-1
vif.tlast  <= 1'b1;
vif.tuser  <= 8'h00;
do @(posedge vif.clk); while (!vif.tready);

vif.tvalid <= 1'b0;
```

Cycle view:

```
cycle | tvalid tready | tdata | tkeep            | tlast | result
  1   |   1      1    | beat1 | all ones         |   0   | beat1 moved
  2   |   1      1    | beat2 | (1<<36)-1        |   1   | beat2 + frame done
```

## 4. Frame Example 3 — 128-byte frame (2 full beats)

128 bytes is exactly 2 beats. Both beats are full; the last one has **full keep
and `tlast=1`**.

```
cycle | tvalid tready | tdata | tkeep            | tlast | result
  1   |   1      1    | beat1 | all ones         |   0   | beat1 moved
  2   |   1      1    | beat2 | all ones         |   1   | beat2 + frame done
```

Same waveform as Example 2 except beat 2's `tkeep` is all ones. This is the
legal "full-keep on tlast" case.

## 5. Frame Example 4 — standard 1518-byte frame (24 beats)

`1518 = 23 × 64 + 46`. So: 23 full beats + 1 final beat of 46 bytes.

```
beats 1..23 : tkeep = all ones, tlast = 0
beat  24    : tkeep = (1<<46)-1, tlast = 1
```

Cycle view (only the edges shown):

```
cycle | tvalid tready | tkeep           | tlast | result
  1   |   1      1    | all ones        |   0   | beat 1
  2   |   1      1    | all ones        |   0   | beat 2
  ...   (21 more full beats)
 24   |   1      1    | (1<<46)-1       |   1   | beat 24 + frame done
```

## 6. Frame Example 5 — jumbo 9000-byte frame (141 beats)

`9000 = 140 × 64 + 40`. 140 full beats + 1 final beat of 40 bytes.

```
beats 1..140: tkeep = all ones, tlast = 0
beat  141   : tkeep = (1<<40)-1, tlast = 1
```

## 7. Frame Example 6 — tuser variants (error / FCS)

`tuser[1:0]` is set on the beat that carries the flag; the MAC maps
`tuser[0]→error`, `tuser[1]→fcs_present`.

| Scenario | `tuser[1:0]` | Meaning |
|---|---|---|
| normal data frame | `2'b00` | no flags |
| frame with client-supplied FCS | `2'b10` | `fcs_present`, last 4 bytes are FCS |
| injected error (drop/tell MAC) | `2'b01` | `error` |

```systemverilog
// error injection on the final beat of an otherwise normal frame
vif.tuser  <= 8'h01;   // tuser[0] = 1
```

## 8. Frame Example 7 — backpressure (tready low mid-frame)

The MAC may deassert `tready`. You must **hold the current beat unchanged**
until `tready` goes high — never advance or modify `tdata` while waiting.

A 100-byte frame with `tready` low for one cycle on beat 1:

```
cycle | tvalid tready | tdata | tkeep            | tlast | transfer?
  1   |   1      0    | beat1 | all ones         |   0   | NO — keep beat1 stable
  2   |   1      1    | beat1 | all ones         |   0   | YES — beat1 moves
  3   |   1      1    | beat2 | (1<<36)-1        |   1   | YES — beat2 + frame done
```

Notice beat 1's `tdata`/`tkeep` are identical in cycles 1 and 2. The RTL even
asserts this (`mac_tx_top.sv:117-127`): a stalled beat must not change.

## 9. Comparison table — the frames side by side

| Example | Stream bytes | Beats | Full interior beats | Final beat keep | `tlast` on cycle |
|---|---|---|---|---|---|
| 1. minimum | 64 | 1 | 0 | all ones | 1 |
| 2. small | 100 | 2 | 1 | `(1<<36)-1` | 2 |
| 3. 2×beat | 128 | 2 | 1 | all ones | 2 |
| 4. standard | 1518 | 24 | 23 | `(1<<46)-1` | 24 |
| 5. jumbo | 9000 | 141 | 140 | `(1<<40)-1` | 141 |
| 7. backpressure | 100 | 2 | 1 | `(1<<36)-1` | 3 (one extra wait cycle) |

"Stream bytes" = the bytes you drive (DA/SA/LT + payload, + FCS if supplied).
The MAC's wire frame is 8 bytes larger (preamble + SFD) plus the appended FCS.

Rule of thumb: `beats = ceil(bytes / 64)`, final keep = `(1 << (bytes mod 64
or 64)) - 1`, and `tlast` fires on the last beat cycle.

## 10. RX side — what you observe instead

On RX (`m_axis_rx_*`), the MAC drives the same bus but you are the *receiver*:

- **Interior beats always have full `tkeep`** (the RX adapter forces it).
- Only the final beat carries the real partial mask.
- To read a frame: on every `tvalid && tready` cycle, latch the beat; stop at
  `tlast`; count bytes = full beats × 64 + popcount(final `tkeep`).

```
same 100-byte frame, seen from the RX side:

cycle | tvalid tready | tdata | tkeep            | tlast
  1   |   1      1    | beat1 | all ones         |   0
  2   |   1      1    | beat2 | (1<<36)-1        |   1
```

## 11. Reusable driver task (SystemVerilog)

The same logic, parameterized for any byte queue:

```systemverilog
task automatic drive_frame(virtual axi4_stream_if.master_mp vif, byte q_data[$]);
  logic [511:0] tdata;
  logic [63:0]  tkeep;
  int           beats;
  int           byte_idx;

  beats = (q_data.size() + 63) / 64;
  for (int b = 0; b < beats; b++) begin
    tdata = '0;
    tkeep = '0;
    for (int lane = 0; lane < 64; lane++) begin
      byte_idx = b * 64 + lane;
      if (byte_idx < q_data.size()) begin
        tdata[lane * 8 +: 8] = q_data[byte_idx];
        tkeep[lane]          = 1'b1;
      end
    end
    vif.tvalid <= 1'b1;
    vif.tdata  <= tdata;
    vif.tkeep  <= tkeep;
    vif.tlast  <= (b == beats - 1);
    vif.tuser  <= 8'h00;
    do begin
      @(posedge vif.clk);
    end while (!vif.tready);
  end
  vif.tvalid <= 1'b0;
endtask
```

## 12. Self-check checklist

Before you call a frame "done", verify:

- [ ] First byte in `tdata[7:0]` of the first beat (lane 0).
- [ ] Every interior `tkeep` is all ones.
- [ ] Final `tkeep` is `(1<<n)-1` for some `n` in `1..64`.
- [ ] `tlast` is high only on the final beat.
- [ ] No beat changed while `tready` was low.
- [ ] `tvalid` dropped to 0 after the final handshake.
- [ ] `tuser[0]`/`tuser[1]` set only when you meant error / FCS.

## Reference

- `src/hdl_top/interfaces/axi4_stream_if.sv` — bus definition (512-bit, 64-byte
  beats)
- `src/hdl_top/tx/tx_axi4_stream_adapter.sv` — TX adapter (what consumes your
  stream)
- `src/hdl_top/rx/rx_axi4_stream_adapter.sv` — RX adapter (what produces your
  stream)
- `src/hdl_top/tx/tx_client_capture.sv` — asserts EOP keep consistency
  (`eop_keep_consistent`, lines 160-167)
- `doc/interface/axi4-stream_adapter.md` — the adapter explained in plain
  language
