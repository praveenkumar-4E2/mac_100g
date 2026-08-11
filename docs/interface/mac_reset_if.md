# mac_reset_if — Reset Domain Interface

## 1. Scope

This document defines the `mac_reset_if` interface contract — the mechanism by
which the UVM reset agent controls and monitors reset signals in the testbench.
One interface instance represents one reset domain.

Defined in: `src/hdl_top/interfaces/mac_reset_if.sv`

## 2. How, Where, Why, When

### How does it work?

`mac_reset_if` is the simplest interface in the design. It wraps a single reset
signal (`rst`) with clocking blocks so a UVM reset agent can drive and monitor
it through the standard clocking-block mechanism.

- The **driver modport** (`driver`) owns `rst` — it drives assertion and
  deassertion.
- The **monitor modport** (`monitor`) samples `rst` — it observes transitions
  for the UVM reset scoreboards and coverage.

```
  UVM Reset Agent                     DUT
  ┌─────────────┐
  │  driver      │──rst──► mac_rst wire ──► mac_top (all flops in mac_clk domain)
  │  monitor     │◄──rst── sampling
  └─────────────┘
```

### Where is it instantiated?

| Instance | Location | Connected to |
|---|---|---|
| `mac_reset_if_h` | `mac_tb_top.sv:27` | `mac_rst` — MAC-domain reset for the entire DUT |
| `apb_reset_if_h` | `mac_tb_top.sv:28` | `apb_rst` — APB-domain reset for register subsystem |

Both instances are in the testbench top (`mac_tb_top.sv`), owned by UVM reset
agents.

### Why does it exist?

Reset is a sideband signal — it doesn't belong to any data bus. Without this
interface, the reset agent would have to reach into scalar wires and drive them
directly, which is fragile and prevents proper clocking-block sampling. The
interface gives the reset agent a clean, typed handle with:
- **`#1step` input skew** in clocking blocks — prevents race conditions between
  the agent's driver and the DUT's flip-flops
- **Modport enforcement** — the monitor can never accidentally drive `rst`
- **Consistent pattern** — matches the clocking-block convention of all other
  interfaces

### When is it used?

1. **Test start**: The reset agent asserts `rst` (the interface initializes to
   `INITIAL_RESET_VALUE = 1'b1`, so the DUT starts in reset).
2. **Reset sequence**: The agent holds `rst` high for the configured number of
   clock cycles, then deasserts it.
3. **During test**: The agent monitors `rst` — if anything else in the
   environment asserts reset unexpectedly, the agent detects it and notifies
   the UVM sequence library.

## 3. Signal reference

| Signal | Width | Direction (driver) | Meaning |
|---|---|---|---|
| `rst` | 1 | output | Reset signal — active high. Driven by the reset agent driver. |

### Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `INITIAL_RESET_VALUE` | `1'b1` | Value of `rst` at interface construction time. Typically `1` so the DUT starts in reset. |

### Clocking blocks

| Block | Skew | Used by | Samples/Drives |
|---|---|---|---|
| `drv_cb` | `#1step input, #0 output` | Reset agent driver | Drives `rst` through modport |
| `mon_cb` | `#1step input, #0 output` | Reset agent monitor | Samples `rst` |

### Modports

| Modport | Drives | Samples |
|---|---|---|
| `driver` | `rst` | `clk` |
| `monitor` | (nothing) | `clk`, `rst` |

## 4. In the testbench

`mac_reset_if` is **actively used in the testbench** — it is the primary
mechanism for reset control. Two instances cover the two reset domains:

### Instance 1: `mac_reset_if_h` (MAC domain reset)

```
mac_tb_top.sv:
  mac_reset_if #(.INITIAL_RESET_VALUE(1'b1)) mac_reset_if_h (.clk(mac_clk));

  // Scalar bridging:
  assign mac_rst = mac_reset_if_h.rst;
```

- `mac_rst` feeds into `mac_top` and drives **all** flip-flops in the
  `mac_clk` domain: TX pipeline, RX pipeline, PAUSE subsystem, MAC control,
  and all `mac_if` / `axi4_stream_if` instances.
- The UVM reset agent uses `mac_reset_if_h` to perform full-chip resets in the
  MAC clock domain.

### Instance 2: `apb_reset_if_h` (APB domain reset)

```
mac_tb_top.sv:
  apb_reset_if #(.INITIAL_RESET_VALUE(1'b1)) apb_reset_if_h (.clk(apb_clk));

  // Scalar bridging:
  assign apb_rst = apb_reset_if_h.rst;
```

- `apb_rst` feeds into `mac_top` and drives the APB register subsystem
  (`apb_regs_if`, `apb_regs`) and any other logic in the `apb_clk` domain.
- The UVM reset agent uses `apb_reset_if_h` to independently reset the APB
  domain — this is important for testing register reset values and CDC
  behavior.

### Why two separate reset domains?

The MAC datapath (`mac_clk`) and APB register bus (`apb_clk`) are
asynchronous. If they shared a single reset, a reset in one domain could cause
metastability in the other. Two independent reset domains let the testbench:
- Reset the MAC without disturbing APB registers (test MAC cold-start)
- Reset APB without disrupting an in-flight MAC frame (test register R/W
  during operation)
- Verify CDC reset behavior

## 5. DUT-side bridging pattern

The testbench uses a scalar-bridge pattern:

```
[UVM Agent] --mac_reset_if--> .rst wire --> scalar mac_rst --> DUT port
```

This bridges the SystemVerilog interface (which cannot be a top-level port in
some synthesis flows) to a plain wire that enters the DUT. The same pattern is
used for all interfaces in this testbench (`apb_if`, `axi4_stream_if`,
`mac_if`).

## 6. Clocking block timing

The `#1step` input skew is critical:

```
                    ┌─────────────────────────────────────┐
  driver output ──► │  drv_cb (output #0)                 │──► rst wire
                    └─────────────────────────────────────┘
                    ┌─────────────────────────────────────┐
  monitor input  ◄─ │  mon_cb (input #1step)              │◄── rst wire
                    └─────────────────────────────────────┘
```

- `output #0`: The driver writes `rst` at the clock edge (zero delay after the
  active edge).
- `input #1step`: The monitor samples `rst` one time-step *before* the next
  clock edge — this is the exact value the DUT's flip-flops will capture, so
  the monitor sees exactly what the DUT sees, not a race-resolved value.

## Reference

- `src/hdl_top/interfaces/mac_reset_if.sv` — interface definition
- `src/hdl_top/tb_top/mac_tb_top.sv:27-28` — testbench instantiation
- `src/hdl_top/tb/mac_hvl_config.svh:33-34` — VIF storage in TB config
- `src/hvl_top/agents/reset_agent/mac_rst_drv.sv` — reset driver
- `src/hvl_top/agents/reset_agent/mac_rst_mon.sv` — reset monitor
