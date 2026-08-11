# ctrl_if — Configuration/Control-Event Interface

## 1. Scope

This document defines the `ctrl_if` interface contract — the intended boundary
between the APB register subsystem and the MAC configuration logic. It is the
"configuration bus" that carries MAC settings from the register file to the
datapath and filter blocks.

Defined in: `src/hdl_top/interfaces/ctrl_if.sv`

## 2. How, Where, Why, When

### How does it work?

`ctrl_if` is a unidirectional interface: the APB side writes configuration
values, and the MAC side reads them. A single `update` pulse tells the MAC to
latch the new configuration. The interface has no handshake — the APB side
writes, pulses `update`, and the MAC picks up the new values on the next clock.

```
  APB register file                         MAC datapath
  (apb_regs_if)                             (filters, TX, RX, PAUSE)
        |                                        |
        +--- ctrl_if (apb_mp) --update--> (mac_mp) ---+
```

### Where is it instantiated?

**It is NOT instantiated anywhere.** The signals it describes (`cfg_update`,
`cfg_control`, `cfg_mac_addr`, etc.) are currently passed as individual scalar
wires between `apb_regs_if` and the rest of `mac_top`.

### Why does it exist?

It is a **prepared contract** for future modular integration. The current
flat-wire approach works but creates a high fan-out from `apb_regs_if` to every
consumer. Switching to `ctrl_if` would:
- Make the configuration boundary explicit (typed port, not magic wires)
- Allow the APB and MAC domains to be developed independently
- Enable clock-domain crossing checks at the interface boundary

### When would it be used?

When the design is refactored to separate the APB register subsystem from the
MAC datapath into independently synthesizable blocks. Until then, the scalar
wires serve the same purpose.

## 3. Signal reference

| Signal | Width | Direction (apb_mp → mac_mp) | Meaning |
|---|---|---|---|
| `ctrl` | 32 | output → input | Global control register (TX enable, RX enable, speed select, etc.) |
| `mac_addr` | 48 | output → input | Local MAC address for address matching |
| `max_client_data` | 16 | output → input | Maximum client data size (for frame length checks) |
| `group_addr` | 4×48 | output → input | Group (multicast) address filter table |
| `group_valid` | 4 | output → input | Group address valid bits (which entries are active) |
| `update` | 1 | output → input | Configuration update pulse — MAC latches values on this edge |

### Clock domains

The interface accepts two clocks (`mac_clk`, `apb_clk`) — it is designed for
a clock-domain-crossing boundary. The APB side writes in `apb_clk` domain; the
MAC side reads in `mac_clk` domain. In the current flat-wire implementation,
the CDC is handled by the `apb_regs_if` adapter, not by this interface.

## 4. Modports

| Modport | Used by | Drives |
|---|---|---|
| `apb_mp` | APB register subsystem | ctrl, mac_addr, max_client_data, group_addr, group_valid, update |
| `mac_mp` | MAC configuration consumers | reads all outputs from apb_mp |

## 5. In the testbench

`ctrl_if` is **not used in the testbench**. The UVM APB agent drives
configuration through `apb_if`, which goes to `apb_regs_if`, which produces
scalar `cfg_*` wires. The testbench never touches `ctrl_if` directly.

## 6. Current scalar-wire equivalent

The signals in `ctrl_if` map 1:1 to the scalar outputs of `apb_regs_if`:

| ctrl_if signal | apb_regs_if output | Consumed by |
|---|---|---|
| `ctrl` | `cfg_control[31:0]` | mac_tx_path, mac_rx_path, pause_tx |
| `mac_addr` | `cfg_mac_addr[47:0]` | mac_rx_path (address filter) |
| `max_client_data` | `cfg_max_client_data[15:0]` | mac_rx_path (length check) |
| `group_addr` | `cfg_group_addr[GROUP_COUNT-1:0][47:0]` | mac_rx_path (group filter) |
| `group_valid` | `cfg_group_valid[GROUP_COUNT-1:0]` | mac_rx_path (group filter) |
| `update` | `cfg_update` | mac_tx_path, mac_rx_path, pause_tx (register latch) |

## Reference

- `src/hdl_top/interfaces/ctrl_if.sv` — interface definition
- `src/hdl_top/registers/apb_regs_if.sv` — adapter that produces the scalar equivalents
- `src/hdl_top/integration/mac_top.sv` — where the scalar wires are distributed
