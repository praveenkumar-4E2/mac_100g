# P0: Establish Stream Ownership and Backpressure Control

## Problem

`axi_driver_c::send_beat` can write `vif.tready` under `generate_backpressure`. On the TX AXI interface in `mac_tb_top`, `tready` is driven by the DUT (`s_axis_tx_tready`). Two owners can produce X values or mask a design bug. The harness also ties `tx_out_ready` and `axi_rx_if.tready` permanently high, so output-side backpressure is unverified.

## Proposal

Define signal ownership explicitly:

| Boundary | TB source owner | TB sink-ready owner |
|---|---|---|
| AXI TX input | `axi_driver_c` drives `tvalid/tdata/tkeep/tlast/tuser` | DUT drives `tready` |
| Native RX input | `rs_driver_c` drives frame signals | DUT drives `ready` |
| Native TX output | DUT drives frame signals | New passive RS sink/ready controller drives `ready` |
| AXI RX output | DUT drives AXI source signals | New AXI RX sink-ready controller drives `tready` |

Remove `generate_backpressure` and all `vif.tready <=` statements from `axi_driver_c`. Add ready-controller components or interfaces for DUT-output boundaries only. Ready controllers must be enabled/configurable without changing monitor behavior.

## Implementation Notes

- Maintain `ready=1` for basic smoke tests.
- Support deterministic patterns (always-ready, periodic stall, first-beat stall, last-beat stall) before random stalls.
- Monitors remain passive observers; ready control is not a monitor responsibility.

## Acceptance Criteria

- Compile/elaboration reports exactly one procedural/continuous owner for each TB-driven signal.
- AXI TX source runs correctly without any TB assignment to `tready`.
- TX wire and AXI RX paths retain data/sideband stability during randomized output stalls.
- Scoreboard-ready monitoring proves no duplicate or dropped beat under stall.
