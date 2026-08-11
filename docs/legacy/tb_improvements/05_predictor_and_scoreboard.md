# P1: Build Directional Predictors and Scoreboards

## Problem

`mac_reference_model_c` only writes the exact observed input handle to its expected port. `mac_scoreboard_c::run_phase` is empty. A pass-through cannot predict preamble, padding, FCS behavior, RX filtering, errors, or drops.

## Proposal

Implement two predictors and two in-order comparators:

```text
AXI TX monitor -> tx_predictor -> expected RS wire frames -> tx_scoreboard <- RS TX monitor
RS RX monitor  -> rx_predictor -> expected AXI frames + status -> rx_scoreboard <- AXI RX/status monitors
```

Predictors must create new objects. TX predictor models frame formatting and FCS/padding policy. RX predictor models protocol validation, length/FCS checks, filtering, control/PAUSE classification, and whether client output or a drop/status is expected. Neither may reproduce RTL pipeline state or timing cycle-by-cycle.

Use a pair of analysis FIFOs per direction. Match in order initially because the interfaces expose no transaction ID. Add an explicit bounded-latency watchdog; report unexpected actual, missing expected, and residual entries in `check_phase`/`final_phase`.

## Acceptance Criteria

- Deliberate payload/FCS/filter defects produce a single directed mismatch or expected-drop result.
- Predictions are independent cloned/new objects.
- Reset flushes queues with a recorded reason.
- End-of-test fails if any expected or actual queue is non-empty.
