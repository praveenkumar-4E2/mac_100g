# Verification Guide

## Transaction flow

```text
AXI TX driver -> DUT TX -> RS TX monitor -> scoreboard
RS RX driver  -> DUT RX -> AXI RX monitor -> scoreboard
APB driver configures the DUT before traffic
```

The reference model produces expected transactions. The scoreboard compares
expected and observed transactions. The protocol checker reports bus-rule
violations separately from functional mismatches.

## Responsibilities

| Component | Responsibility |
|---|---|
| Driver | Drive signals and wait for handshake. |
| Monitor | Sample accepted beats and reconstruct frames. |
| Reference model | Predict expected result. |
| Scoreboard | Compare expected and actual frames. |
| Protocol checker | Check handshake and interface rules. |

## Pass criteria

A useful pass has zero UVM errors/fatals, zero scoreboard mismatches, zero
protocol violations, and no APB error. Use the packet ID to trace a failing
frame: driver -> ingress monitor -> expected item -> egress monitor ->
scoreboard -> waveform.
