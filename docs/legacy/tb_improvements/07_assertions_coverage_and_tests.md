# P2: Add Assertions, Coverage, and Completion Tests

## Preconditions

Complete P0 transaction, reset, and ownership fixes first. Assertions and coverage cannot compensate for an ambiguous monitor contract.

## Assertions

Bind or place interface assertions for source stability under stall, keep mask shape, SOP/EOP ordering, reset quiescence, and AXI/`mac_if` sideband consistency. Add DUT-level assertions for RX-disabled no-delivery, accepted-frame status consistency, and legal TX arbitration. Use scoreboard logic for data transformations; use SVA for cycle/protocol invariants.

## Coverage

Cover frame-size boundaries, last-beat geometry, length/type range, FCS state, destination/filter result, errors and drop result, backpressure shape, reset position, and pause/control contention. Favor outcome crosses such as `fault x accept/drop`, `frame_shape x stall`, and `destination_class x promiscuous`; avoid unconstrained payload-data Cartesian crosses.

## Tests

Add directed smoke/boundary tests first, then constrained-random traffic, deterministic/random output stall tests, reset tests, APB configuration changes, PAUSE/control arbitration, and long throughput runs. Each test must end using scoreboard drains/timeouts rather than fixed `#1us` settle delays.

## Acceptance Criteria

- Protocol assertion failures are distinguishable from functional scoreboard mismatches.
- Coverage reports meaningful bins and crosses with documented exclusions.
- Regression includes both always-ready and randomized-ready variants for each direction.
