# APB Agent Interface Contract

## 1. Scope

This document is the interface contract for the reusable master-side UVM APB
agent at the MAC register boundary. It defines the supported APB signal
subset and the phase vocabulary (idle, setup, access, wait, completion) that
the agent's driver, monitor, and assertions share.

The contract targets the APB3-style subset exposed by
`src/hdl_top/interfaces/apb_if.sv`. APB4-only signals (`PSTRB`, `PPROT`) are
out of scope and are neither generated nor sampled.

## 2. Supported signal subset

| Signal | Direction (agent view) | Width | Owner | Meaning |
|---|---|---|---|---|
| `clk` | input | 1 | environment | Single APB clock; every phase boundary is an edge of `clk`. |
| `rst` | input | 1 | environment | Synchronous reset. Assertion aborts any incomplete transfer. |
| `psel` | master output | 1 | active driver | "Selected": this slave is addressed for a transfer. |
| `penable` | master output | 1 | active driver | "Enable": the access phase is active. |
| `pwrite` | master output | 1 | active driver | Direction: `1` = write, `0` = read. |
| `paddr` | master output | 16 | active driver | Address of the transfer. |
| `pwdata` | master output | 32 | active driver | Write data; meaningful only when `pwrite == 1`. |
| `prdata` | slave input | 32 | slave only | Read data; sampled only at completion of a read. |
| `pready` | slave input | 1 | slave only | "Ready": the access phase completes on this edge. |
| `pslverr` | slave input | 1 | slave only | Slave error; sampled only at completion. |

Master outputs (`psel`, `penable`, `pwrite`, `paddr`, `pwdata`) are driven
exclusively by the active APB driver. Slave outputs (`prdata`, `pready`,
`pslverr`) are owned by the slave and must never be driven by the agent.

## 3. Phase vocabulary

Every transfer on this subset is a sequence of the phases below. A phase is a
state observed at an APB clock edge; a transfer changes phase only on a clock
edge, never combinational.

### 3.1 Idle

`psel == 0`.

No slave is selected. No request is pending. In idle, `penable` is also `0`
and the remaining master outputs hold stable, defined values. Idle is the
required quiescent state of the bus and the recovery state after a completed,
timed-out, or reset-aborted transfer.

### 3.2 Setup

`psel == 1` and `penable == 0`.

The master has selected a slave and presented the request: `pwrite`, `paddr`,
and (for writes) `pwdata` are stable for the whole setup phase. Setup lasts
exactly one APB clock cycle and is a prerequisite for access.

### 3.3 Access

`psel == 1` and `penable == 1`.

The enable phase of the selected transfer. The request fields presented in
setup (`pwrite`, `paddr`, `pwdata`) are held stable throughout access, and
`psel` is retained from setup. The transfer leaves access either by completing
(see completion) or by aborting (reset assertion).

### 3.4 Wait

`psel == 1`, `penable == 1`, and `pready == 0`.

A wait state is one APB clock cycle of access during which the slave is not
ready. While waiting, all master outputs remain stable: `psel`, `penable`,
`pwrite`, `paddr`, and `pwdata` do not change. A transfer may pass through
zero or more wait states before completion.

### 3.5 Completion

`psel == 1`, `penable == 1`, and `pready == 1`.

A transfer completes only when the access phase is sampled with the full
conjunction `psel && penable && pready` true at a clock edge. Completion is
the single point at which the transfer outcome is fixed: read data
(`prdata`) and slave error (`pslverr`) are sampled only on this edge, for
reads and for every transfer respectively. After completion the master
returns the bus to idle on the next legal clock boundary, or begins the next
transfer's setup as permitted by the hand-off policy.

### 3.6 Abort

An abort is not a normal phase: reset asserting during setup, access, or wait
aborts the transfer. An aborted transfer never completes, never samples
`prdata` or `pslverr` as a response, and leaves the bus in idle at the next
safe clock boundary after reset release.

## 4. Transfer lifecycle summary

```text
idle --> setup --> access --+--> completion --> idle
      (1 cycle)   (1+ wait) |          |
                            |          +--> next setup
                            +--> abort (reset) --> idle
```

- setup is exactly one cycle;
- access is one cycle plus any wait states;
- completion is the access edge on which `pready == 1`;
- a transfer interrupted by reset is aborted and never reports a normal
  completion.

## 5. Sampling and drive rules

- The driver drives master outputs through its clocking block with defined
  output skew.
- The monitor samples all signals through its pre-edge clocking block, so it
  observes stable values at the point where the driving edge takes effect.
- `prdata` and `pslverr` are consumed by the monitor (and by the driver for
  its response) only at the completion edge.
