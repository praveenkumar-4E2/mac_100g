# UVM Coding Guidelines

## Naming

Classes use the existing `_c` suffix. Object handles end in `_h`, virtual
interfaces end in `_vif`, and configuration handles end in `_cfg_h`.

Use the factory for UVM objects:

```systemverilog
item_h = axi_item_c::type_id::create("item_h");
```

## Ownership

Active agents contain sequencer, driver, and monitor. Passive agents contain
only monitoring logic. Drivers drive source signals; monitors only sample.
Never drive a signal from a monitor.

## Tests and sequences

Sequences create transactions and run on named sequencers. Tests choose the
scenario and configuration. `mac_tb_top` is only a clock/reset/wiring harness.

A test that raises an objection must drop it after monitored completion. Do
not use a fixed delay as evidence of frame completion.

## Messages

Use meaningful UVM IDs such as `MAC_SANITY`, `MAC_SB`, and `MAC_PROTOCOL`.
Packet IDs should be included in logs when a transaction crosses a boundary.
