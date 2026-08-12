# Test Guide

## Baseline test

Run this after RTL, interface, or UVM changes:

```bash
make run TEST=mac_sanity_test_c
```

It checks TX-only, RX-only, and concurrent traffic.

## Creating a test

1. Extend `mac_base_test_c`.
2. Register the class with the UVM factory.
3. Set agent/frame counts in the constructor.
4. Override `configure_test()` only for configuration changes.
5. Override `run_stimulus()` for the scenario.
6. Start sequences through named agent sequencers.
7. Wait for monitored completion, then report the result.

Use names such as `mac_rx_crc_error_test_c` or `mac_tx_min_frame_test_c`.
The name must state the feature and condition.

## Review checklist

- Does the test make one clear behavioral claim?
- Does it configure through APB rather than force internals?
- Does it check data plus relevant error/status behavior?
- Does it finish without arbitrary delays?
- Are UVM errors, protocol violations, and mismatches zero?
