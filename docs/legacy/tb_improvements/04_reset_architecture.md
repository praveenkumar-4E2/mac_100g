# P0: Implement a Single Reset Architecture

## Problem

Only initial reset is active. The reset-agent driver and sequence are empty and are not integrated into `mac_env_c`. Reset deassertion in `mac_tb_top` happens immediately after a posedge despite the DUT using synchronous reset. Drivers and monitors do not consistently abort/flush work.

## Proposal

Use a small reset controller/monitor, not a full reset agent unless tests require independently sequenced random resets. It owns reset drive in the top-level harness and publishes `reset_asserted` / `reset_released` events to UVM components.

Rules:

1. Assert/deassert synchronous reset away from sampling ambiguity; hold it through a defined number of relevant clock edges.
2. AXI/RS drivers immediately drive idle on reset, terminate or report their in-flight sequence item using a documented policy, and wait for release.
3. Monitors delete all partial state and optionally publish an aborted-frame event.
4. Predictor and scoreboard flush queues on reset and account for flushed expected frames.
5. Test waits for both reset release and completed APB configuration before traffic.

## Tests

- Initial reset
- Reset while idle
- Reset before first-beat handshake
- Reset mid-frame
- Reset on last beat/output stall
- Two consecutive resets

## Acceptance Criteria

- No monitor publishes bytes from both sides of reset in one transaction.
- No driver calls `item_done()` for a transaction presented only before reset unless the policy declares it aborted/completed.
- Scoreboard reports reset flushes separately from DUT mismatches.
