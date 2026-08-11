# stats_if — Statistics Event and Snapshot Interface

## 1. Scope

This document defines the `stats_if` interface contract — the intended boundary
between the MAC-domain statistics event sources and the APB-domain snapshot
registers. It carries event pulses from the datapath and a captured snapshot
back to the register interface.

Defined in: `src/hdl_top/interfaces/stats_if.sv`

## 2. How, Where, Why, When

### How does it work?

`stats_if` is a clock-domain-crossing interface between the MAC domain
(`mac_clk`) and the APB domain (`apb_clk`). It has two directions:

- **MAC → APB** (events): The MAC datapath produces single-cycle event pulses
  for each statistics condition (CRC error, oversize frame, etc.). These events
  cross into the APB domain where they are accumulated in counters.

- **APB → MAC** (snapshot): When the APB register interface wants a consistent
  read of all counters, it asserts `snapshot_request`. The MAC domain captures
  all counters into a snapshot register and pulses `snapshot_acknowledge`. The
  APB side then reads the stable snapshot values.

```
  MAC datapath                              APB register file
  (event sources)                          (snapshot registers)
       |                                          |
       +-- rx_invalid_event --> snapshot[0]  <--- snapshot_request
           rx_crc_event      --> snapshot[1]  <---+
           rx_oversize_event --> snapshot[2]      |
           ...                  ...               |
           tx_error_event     --> snapshot[11] <--+
                               snapshot_acknowledge
```

### Where is it instantiated?

**It is NOT instantiated anywhere.** The events and snapshot signals are
currently passed as individual scalar wires between the event sources,
`mac_event_collector`, and `apb_regs_if`.

### Why does it exist?

Statistics counting requires two operations that must be carefully coordinated:
1. **Event accumulation** (MAC domain): free-running counters increment on
   events — no handshake needed, just pulse detection.
2. **Consistent readout** (APB domain): reading 12 counters atomically requires
   a snapshot mechanism — otherwise the counters could change mid-read.

`stats_if` formalizes this contract and makes the CDC boundary explicit.

### When would it be used?

When the statistics subsystem is refactored into a standalone module with a
typed interface port. This would:
- Isolate the CDC logic (pulse synchronizers or handshaking) into the interface
- Enable standalone verification of the statistics counter block
- Allow the APB side to be developed independently of the MAC datapath

## 3. Signal reference

### Event signals (MAC → APB)

| Signal | Width | Direction | Meaning |
|---|---|---|---|
| `rx_invalid_event` | 1 | MAC output | Frame with invalid format detected |
| `rx_crc_event` | 1 | MAC output | Frame with CRC error detected |
| `rx_oversize_event` | 1 | MAC output | Frame exceeding max size detected |
| `rx_unsupported_control_event` | 1 | MAC output | Unsupported control frame detected |
| `pause_active` | 1 | MAC output | PAUSE timer is currently active |
| `pause_expired` | 1 | MAC output | PAUSE timer just expired |
| `tx_error_event` | 1 | MAC output | TX error occurred |

All event signals are single-cycle pulses in the `mac_clk` domain. They are
level-sensitive for `pause_active` (held while the condition persists).

### Snapshot signals (APB → MAC → APB)

| Signal | Width | Direction | Meaning |
|---|---|---|---|
| `snapshot_request` | 1 | APB output | Request a consistent snapshot of all counters |
| `snapshot_acknowledge` | 1 | MAC output | Snapshot is ready; APB side may read |
| `snapshot` | 12 × 32 | MAC output | Frozen counter values (12 counters × 32 bits) |

### Modports

| Modport | Used by | Drives |
|---|---|---|
| `mac_mp` | MAC event sources + snapshot logic | events, snapshot_acknowledge, snapshot |
| `apb_mp` | APB register interface | snapshot_request |

## 4. In the testbench

`stats_if` is **not used in the testbench**. Statistics verification in the UVM
environment works through the existing scalar wires:

- **Event generation**: The RS agent sends frames that trigger events (bad CRC,
  oversize, etc.) via `mac_if`. The events propagate as scalar pulses to the
  statistics counters.
- **Counter readout**: The APB agent reads the statistics registers through
  `apb_if` → `apb_regs_if` → `cfg_status_snapshot` scalar wires.
- **Scoreboard check**: The UVM scoreboard compares expected vs. actual counter
  values read via APB.

## 5. Current scalar-wire equivalent

| stats_if signal | Current scalar wire | Between modules |
|---|---|---|
| `rx_invalid_event` | `rx_invalid_event` | mac_rx_path → mac_event_collector |
| `rx_crc_event` | `rx_crc_event` | mac_rx_path → mac_event_collector |
| `rx_oversize_event` | `rx_oversize_event` | mac_rx_path → mac_event_collector |
| `rx_unsupported_control_event` | `rx_unsupported_control_event` | mac_rx_path → mac_event_collector |
| `pause_active` | `pause_active` | pause_timer_engine → mac_event_collector |
| `pause_expired` | `pause_expired` | pause_timer_engine → mac_event_collector |
| `tx_error_event` | `tx_error_event` | mac_tx_path → mac_event_collector |
| `snapshot_request` | `status_request` | apb_regs_if → mac_event_collector |
| `snapshot_acknowledge` | `status_ack` | mac_event_collector → apb_regs_if |
| `snapshot` | `status_snapshot[12]` | mac_event_collector → apb_regs_if |

## Reference

- `src/hdl_top/interfaces/stats_if.sv` — interface definition
- `src/hdl_top/rx/mac_event_collector.sv` — event accumulator and snapshot logic
- `src/hdl_top/registers/apb_regs_if.sv` — APB-side adapter that produces status_request
- IEEE 802.3 Clause 5.2 — MAC statistics counters specification
