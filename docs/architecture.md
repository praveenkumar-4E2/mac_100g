# Architecture Guide

## What the MAC does

The MAC sends and receives Ethernet frames. TX converts a client AXI stream to
a native MAC/RS stream. RX converts a native MAC/RS stream to a client AXI
stream. APB3 configures the MAC.

```text
TX: ingress_tx_axis_* -> TX logic -> egress_tx_mac_*
RX: ingress_rx_mac_* -> RX logic -> egress_rx_axis_*
```

## Directory map

| Path | Purpose |
|---|---|
| `src/rtl_verilog/rtl_top.v` | Synthesizable DUT boundary. |
| `src/rtl_verilog/integration/mac_core_v.v` | APB, TX, and RX integration. |
| `src/rtl_verilog/tx/` | Capture, scheduling, formatting, padding, FCS. |
| `src/rtl_verilog/rx/` | Preamble, header, CRC, filtering, AXI output. |
| `src/rtl_verilog/registers/` | APB registers and configuration CDC. |
| `src/hvl_top/` | SystemVerilog/UVM verification environment. |
| `sim/Questasim/` | File lists, Makefile, and waveform layout. |

## Naming and clock domains

`ingress` means entering the MAC; `egress` means leaving it. Names are from
the DUT point of view, not the testbench point of view.

`clk_core` clocks the data path. `pclk` clocks APB. `rst_n` and `presetn` are
active-low top-level resets. Never cross a multi-bit signal between clock
domains without a CDC scheme.
