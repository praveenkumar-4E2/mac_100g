# mac_if — MAC Client/Line-Side Stream Interface

## 1. Scope

This document is the interface contract for the internal 512-bit beat MAC stream
used between the client adapters (TX/RX) and the MAC datapath pipeline. It is
the **core internal transport** for all frame data — the AXI4-Stream world talks
to it through adapters, and the MAC pipeline speaks it natively.

Defined in: `src/hdl_top/interfaces/mac_if.sv`

## 2. How, Where, Why, When

### How does it work?

`mac_if` is a SystemVerilog interface with 9 signals. It uses a valid/ready
handshake — data moves only when both `valid` and `ready` are high in the same
clock cycle. The key distinction from AXI4-Stream is that `mac_if` has explicit
start-of-packet (`sop`), end-of-packet (`eop`), and byte-count (`eop_pos`)
signals — no frame state needs to be derived.

```
  AXI4-Stream                    mac_if                    MAC pipeline
  (testbench)        ─── tx_adapter ───►  tx_client_if  ───► mac_tx_path
                                                     ◄── mac_rx_path
  (testbench)        ◄── rx_adapter ───  rx_client_if  ◄── mac_rx_path
```

### Where is it instantiated?

| Instance | Location | Modport | Role |
|---|---|---|---|
| `tx_client_if` | `mac_top.sv:238` | client_mp / mac_mp | TX: adapter writes, MAC pipeline reads |
| `rx_client_if` | `mac_top.sv:549` | client_mp / mac_mp | RX: MAC pipeline writes, adapter reads |
| `mac_rx_if` | `mac_tb_top.sv:51` | scalar-bridged | Line-side RX: RS agent drives into DUT |
| `mac_tx_out_if` | `mac_tb_top.sv:59` | scalar-bridged | Line-side TX output: RS agent passively monitors |

### Why does it exist?

AXI4-Stream has no `sop` or `eop_pos` — the adapter would have to derive them
every cycle. `mac_if` makes the MAC pipeline simpler: every beat carries its
packet boundary markers explicitly. This splits the complexity:
- Adapters translate protocol (one-time, isolated)
- Pipeline operates on a clean beat-level contract (every cycle)

### When is each modport used?

| Modport | Used by | Drives | Samples |
|---|---|---|---|
| `client_mp` | AXI adapters (TX side), RS agent (RX) | valid, data, keep, sop, eop, eop_pos, error, fcs_present | ready |
| `mac_mp` | MAC pipeline (TX/RX paths) | ready | valid, data, keep, sop, eop, eop_pos, error, fcs_present |

## 3. Signal reference

| Signal | Width | Direction (client_mp) | Meaning |
|---|---|---|---|
| `valid` | 1 | output | Beat contains valid frame data |
| `ready` | 1 | input | Downstream can accept a beat this cycle |
| `data` | 512 | output | Beat payload — 64 bytes, lane-0 aligned |
| `keep` | 64 | output | Byte-lane enables: contiguous ones, `(1<<n)-1` |
| `sop` | 1 | output | Start of packet: asserted on the first beat of a frame |
| `eop` | 1 | output | End of packet: asserted on the final beat of a frame |
| `eop_pos` | 7 | output | Number of valid bytes in the final beat (`1..64`). `keep = (1<<eop_pos)-1` |
| `error` | 1 | output | Error flag for this beat |
| `fcs_present` | 1 | output | FCS bytes are included in the beat payload |

### `sop` — start of packet

Asserted on the beat carrying the first byte of a new frame. For the TX adapter,
`sop` is combinational: derived from the pre-handshake frame state
(`tvalid && !frame_active`). It stays asserted from the moment the first beat is
presented until it is accepted. An interior beat never carries `sop`.

### `eop` / `eop_pos` — end of packet + byte count

`eop` is asserted on the final beat. `eop_pos` tells the receiver exactly how
many bytes in that beat are valid (`1..64`). The keep mask is derived:
`keep = (1<<eop_pos)-1`. A frame that ends on a beat with 64 valid bytes has
`eop_pos = 64` and `keep = all ones`.

### `keep` — byte-lane enables

Interior beats always have `keep = all ones`. Only the `eop` beat may have a
partial keep. The keep value is always contiguous ones from lane 0 — a prefix
mask.

## 4. Handshake rules

Same as AXI4-Stream: **data moves only when `valid && ready`**. If `valid` is
high and `ready` is low, the driver must hold the current beat unchanged. A
stalled beat never changes `data`, `keep`, `sop`, `eop`, or any other signal.

```
cycle | valid ready | action
  1   |   1     0   | hold beat (no change)
  2   |   1     1   | beat transfers — move to next
```

## 5. In the testbench

`mac_if` is used in the testbench through the **RS (Reconciliation Sublayer)
agent**, which operates at the line side of the MAC:

- **`mac_rx_if`** (`mac_tb_top.sv:51`): The RS agent's driver uses `client_mp`
  to push frames into the DUT's RX input. The agent populates `data` with
  Ethernet frames (DA/SA/LT + payload), asserts `sop` on the first beat, `eop`
  on the last, and sets `eop_pos` for the final beat.

- **`mac_tx_out_if`** (`mac_tb_top.sv:59`): The RS agent's monitor observes the
  DUT's TX output. It samples all signals through `mac_mp` and reconstructs
  transmitted frames for scoreboard comparison.

- **`rx_client_if`** / **`tx_client_if`**: Internal instances — not directly
  driven by UVM agents but connected through the adapters.

### Why the RS agent uses mac_if, not AXI4-Stream

The RS agent operates at the **MAC-native boundary** (line side), not the client
boundary (AXI side). It tests the MAC's internal datapath behavior — CRC
calculation, preamble generation, frame validation — which happens *after* the
AXI adapter. Using `mac_if` lets the agent inject raw Ethernet frames and
observe the MAC's real output, bypassing the adapter translation layer.

## 6. Modport usage in RTL

```
// TX data flow:
[AXI TX Agent] --axi4_stream_if--> tx_adapter --mac_if(client_mp)--> mac_tx_path(mac_mp)

// RX data flow:
[RS Agent] --mac_if(client_mp)--> mac_top RX input --mac_rx_path(client_mp)--> rx_adapter --axi4_stream_if--> [AXI RX Agent]
```

The `client_mp` modport is always the frame source (drives data + sop/eop). The
`mac_mp` modport is always the frame consumer (drives ready).

## 7. Differences from AXI4-Stream

| Feature | mac_if | AXI4-Stream |
|---|---|---|
| Start-of-packet | explicit `sop` signal | derived from idle detection |
| End-of-packet | `eop` + `eop_pos` | `tlast` only |
| Byte count | `eop_pos` (1..64) | popcount of `tkeep` |
| Sideband | `error`, `fcs_present` | `tuser[0]`, `tuser[1]` |
| Keep semantics | `(1<<eop_pos)-1` on eop | prefix mask on every beat |

## Reference

- `src/hdl_top/interfaces/mac_if.sv` — interface definition
- `src/hdl_top/integration/mac_top.sv:238,549` — internal instantiation
- `src/hdl_top/tb_top/mac_tb_top.sv:51,59` — testbench instantiation
- `src/hdl_top/tx/tx_axi4_stream_adapter.sv` — TX side: AXI → mac_if
- `src/hdl_top/rx/rx_axi4_stream_adapter.sv` — RX side: mac_if → AXI
