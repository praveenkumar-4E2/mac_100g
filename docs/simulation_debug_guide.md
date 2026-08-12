# Simulation and Debug Guide

## WSL commands

```bash
cd /mnt/d/Qsemiai/VLSI/Documents/Protocols/Ethernet/100g/repo/mac_100g/sim/Questasim
make compile
make run TEST=mac_sanity_test_c
```

Run `make help` for the complete target list. There is no forced global UVM
timeout. Request one only when necessary:

```bash
make run TEST=mac_sanity_test_c UVM_TIMEOUT=50000000
```

## GUI and Visualizer

```bash
make gui_waves TEST=mac_sanity_test_c
make visualizer TEST=mac_sanity_test_c
make visualizer_wlf TEST=mac_sanity_test_c
```

`waves.do` shows reset, APB3, TX AXI ingress, TX MAC/RS egress, RX MAC/RS
ingress, and RX AXI egress in order.

## Failure triage

1. Read the final UVM summary and find the first error.
2. Check reset release and APB configuration.
3. Check `valid && ready` at the source and sink boundaries.
4. Check `sop`, `eop`, `keep`, and `frame_end_byte_index`.
5. Trace the packet ID through logs, monitor output, expected item, and
   scoreboard result.
6. Reproduce with the same seed before trying a new seed.
