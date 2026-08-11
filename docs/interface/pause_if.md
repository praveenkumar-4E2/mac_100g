# pause_if — PAUSE Event and TX Admission Interface

## 1. Scope

This document defines the `pause_if` interface contract — the intended boundary
between the PAUSE subsystem (RX detection, timer, admission control) and the
rest of the MAC. It carries PAUSE events, admission decisions, and timer status
between the three PAUSE sub-blocks.

Defined in: `src/hdl_top/interfaces/pause_if.sv`

IEEE reference: IEEE 802.3 Annex 31B.3.4 (PAUSE) and Annex 31B.3.7 (100GBASE
CR/KR PAUSE)

## 2. How, Where, Why, When

### How does it work?

`pause_if` connects three PAUSE sub-blocks in a producer/consumer chain:

1. **`pause_rx`** detects incoming PAUSE frames on the RX path and produces
   events (`pause_event_valid`, `pause_dest_addr`, `pause_time`).
2. **`pause_timer`** processes PAUSE events, manages the countdown timer, and
   produces status (`paused`, `timer_done`).
3. **`pause_admission`** uses the timer status to gate TX frame admission
   (`data_admit`, `control_admit`).

```
  RX path                    PAUSE subsystem                    TX path
  (pause_rx)            (timer + admission gate)            (TX pipeline)
       |                         |                               |
       +-- pause_event_valid --> timer --> paused --> data_admit -+
           pause_dest_addr              timer_done    control_admit
           pause_time                               event_accepted
```

### Where is it instantiated?

**It is NOT instantiated anywhere.** The signals it describes are currently
passed as individual scalar wires between `pause_rx`, `pause_timer_engine`,
`pause_admission_gate`, and `mac_top`.

### Why does it exist?

The PAUSE subsystem has three distinct concerns (event detection, timing, TX
gating) that are currently wired together with flat scalar signals. `pause_if`
was designed to make these connections explicit and checkable:
- Event detection → timer: a clean "PAUSE event" handoff
- Timer → admission: a clean "am I paused?" handoff
- Admission → TX: a clean "may I transmit?" handoff

### When would it be used?

When the PAUSE subsystem is refactored from flat wires into three separate
modules communicating through typed interface ports. This would:
- Allow independent verification of each PAUSE sub-block
- Make clock-domain crossing explicit (if PAUSE RX and TX use different clocks)
- Enable assertion checking at module boundaries

## 3. Signal reference

| Signal | Width | Direction (pause_rx_mp) | Meaning |
|---|---|---|---|
| `pause_event_valid` | 1 | input | A valid PAUSE frame was detected |
| `pause_dest_addr` | 48 | input | Destination MAC address of the PAUSE frame |
| `pause_time` | 16 | input | Requested PAUSE quanta (in 512-bit-time units) |
| `transmission_in_progress` | 1 | input | TX path is currently sending a frame |
| `data_admit` | 1 | output | Data frames are allowed to enter the TX path |
| `control_admit` | 1 | output | Control frames are allowed to enter the TX path |
| `paused` | 1 | output | PAUSE timer is active (TX should be paused) |
| `timer_done` | 1 | output | PAUSE timer has expired (or was never started) |
| `event_accepted` | 1 | output | The PAUSE event was accepted by the timer |

### Modports

| Modport | Role | Drives |
|---|---|---|
| `pause_rx_mp` | RX-side consumer (pause_rx) | data_admit, control_admit, paused, timer_done, event_accepted |
| `pause_status_mp` | Status-side producer | pause_event_valid, pause_dest_addr, pause_time, transmission_in_progress |

### PAUSE admission flow

1. RX detects PAUSE frame → asserts `pause_event_valid` with `pause_dest_addr`
   and `pause_time`.
2. Timer accepts event (if addressed to us) → starts countdown → asserts
   `paused`, clears `timer_done`.
3. Admission gate sees `paused` → deasserts `data_admit` → TX pipeline
   backpressures.
4. Timer reaches zero → asserts `timer_done`, deasserts `paused` → admission
   gate re-asserts `data_admit`.

## 4. In the testbench

`pause_if` is **not used in the testbench**. PAUSE behavior is tested through
the UVM agents using the existing scalar wires:

- The RS agent drives PAUSE frames into the DUT RX input using `mac_if`.
- The APB agent reads/writes PAUSE registers (enable, quanta) through `apb_if`.
- PAUSE admission effects are observed indirectly: when `paused` is active,
  the AXI TX agent sees `tready` go low on `axi_tx_if` (TX backpressure).

## 5. Current scalar-wire equivalent

| pause_if signal | Current scalar wire | Between modules |
|---|---|---|
| `pause_event_valid` | `pause_event_valid` | pause_rx → pause_timer_engine |
| `pause_dest_addr` | `pause_dest_addr[47:0]` | pause_rx → pause_timer_engine |
| `pause_time` | `pause_time[15:0]` | pause_rx → pause_timer_engine |
| `transmission_in_progress` | `transmission_in_progress` | mac_tx_path → pause_admission_gate |
| `data_admit` | `data_admit` | pause_admission_gate → mac_tx_path |
| `control_admit` | `control_admit` | pause_admission_gate → mac_tx_path |
| `paused` | `paused` | pause_timer_engine → pause_admission_gate |
| `timer_done` | `timer_done` | pause_timer_engine → pause_admission_gate |
| `event_accepted` | `event_accepted` | pause_timer_engine → pause_rx |

## Reference

- `src/hdl_top/interfaces/pause_if.sv` — interface definition
- `src/hdl_top/rx/pause_rx.sv` — PAUSE frame detection (event producer)
- `src/hdl_top/rx/pause_timer_engine.sv` — PAUSE timer (event consumer, status producer)
- `src/hdl_top/tx/pause_admission_gate.sv` — TX admission gating (status consumer)
- IEEE 802.3 Annex 31B.3.4 — PAUSE mechanism specification
