# Testbench Interface Usage — Which Interfaces Are Used and How

## 1. Scope

This document maps every SystemVerilog interface in the MAC 100G design to its
role in the UVM testbench. It answers: **which interfaces does the testbench
actually use**, how they connect to the DUT, and what UVM agents drive/monitor
them.

## 2. Interface classification

| Interface | Defined in | TB status | DUT status |
|---|---|---|---|
| `apb_if` | `interfaces/apb_if.sv` | **Active** — UVM APB agent | Instantiated in `mac_top` |
| `axi4_stream_if` | `interfaces/axi4_stream_if.sv` | **Active** — UVM AXI agent | **TB only** — RTL uses scalar ports |
| `mac_if` | `interfaces/mac_if.sv` | **Active** — UVM RS agent (line side) | Instantiated in `mac_top` (internal) |
| `mac_reset_if` | `interfaces/mac_reset_if.sv` | **Active** — UVM reset agent | **TB only** — drives scalar `mac_rst` / `apb_rst` |
| `ctrl_if` | `interfaces/ctrl_if.sv` | **Not used** | Not instantiated |
| `pause_if` | `interfaces/pause_if.sv` | **Not used** | Not instantiated |
| `stats_if` | `interfaces/stats_if.sv` | **Not used** | Not instantiated |

**4 interfaces are actively used in the testbench. 3 are defined but not instantiated.**

## 3. Active interfaces — how they connect

### 3.1 `apb_if` — Register access

```
UVM APB Agent                    mac_tb_top.sv                   mac_top.sv
─────────────                    ─────────────                   ──────────
apb_driver.sv                    apb_bus (apb_if)                apb_bus (apb_if)
  │ drives psel/penable/            │ scalar bridge                │ scalar bridge
  │ pwrite/paddr/pwdata            ▼                              ▼
  │                            psel/penable/...              apb_regs_if (apb)
  │                                │                             │
apb_monitor.sv                     ▼                             ▼
  │ samples prdata/pready/    psel/penable/...              apb_regs (register file)
  │ pslverr                       │
  ▼                           [DUT scalar ports]
```

**What the TB does**: The APB agent writes MAC configuration registers (TX
enable, MAC address, PAUSE settings, max frame size) and reads back status
(statistics counters, PAUSE status). The agent driver drives through `apb_if`,
and the scalar bridge in `mac_tb_top.sv` converts to the DUT's port list.

**When**: Every test that configures the MAC before sending frames — which is
nearly every test.

### 3.2 `axi4_stream_if` — Data-plane TX/RX

```
UVM AXI TX Agent                 mac_tb_top.sv                   mac_top.sv
────────────────                  ─────────────                   ──────────
axi_drv.sv                        axi_tx_if (axi4_stream_if)      s_axis_tx_* (scalar)
  │ drives tdata/tkeep/            │ scalar bridge                 │ tx_axi4_stream_adapter
  │ tvalid/tlast/tuser             ▼                              ▼
  │                           s_axis_tx_*                    mac_if (tx_client_if)
  │                                │                             │
axi_mon.sv (RX)                    ▼                             ▼
  │ samples m_axis_rx_*       m_axis_rx_* (scalar)          mac_rx_path output
  │                           axi_rx_if (axi4_stream_if)
  ▼                                │
                            [DUT scalar ports]
```

**What the TB does**:
- **TX agent** (`axi_drv.sv`): Constructs Ethernet frames (DA/SA/LT + payload),
  drives them beat-by-beat on `axi_tx_if` following the AXI4-Stream handshake.
  The first beat waits for `tready` (admission controller).
- **RX monitor** (`axi_mon.sv`): Passively samples `axi_rx_if` to capture
  frames exiting the DUT for scoreboard comparison.

**Key point**: `axi4_stream_if` does NOT exist inside the RTL. The RTL uses
scalar AXI4-Stream ports (`s_axis_tx_tdata`, etc.) and internal adapters convert
to `mac_if`. The SystemVerilog interface exists only in the testbench.

**When**: Every test that sends or receives frame data through the client port.

### 3.3 `mac_if` — Line-side (RS agent)

```
UVM RS Agent                      mac_tb_top.sv                   mac_top.sv
─────────────                     ─────────────                   ──────────
rs_drv.sv                         mac_rx_if (mac_if)              rx_in_* (scalar)
  │ drives data/keep/sop/          │ scalar bridge                 │ MAC RX input
  │ eop/eop_pos/error              ▼                              ▼
  │                           rx_in_*                        mac_rx_path
  │                                │
rs_mon.sv (TX)                     ▼
  │ samples tx_out_*           mac_tx_out_if (mac_if)          tx_out_* (scalar)
  │                           tx_out_* (scalar bridge)        mac_tx_path output
  ▼                                │
                            [DUT scalar ports]
```

**What the TB does**:
- **RS driver** (`rs_drv.sv`): Drives raw Ethernet frames (with preamble/SFD or
  without) into the DUT's RX input. Used to test the MAC's RX path (preamble
  detection, header extraction, CRC check, frame acceptance/rejection).
- **RS monitor** (`rs_mon.sv`): Passively observes the DUT's TX output to
  verify transmitted frames match expectations.

**When**: Tests that exercise the MAC's internal datapath (RX validation,
TX frame building, CRC, address filtering, PAUSE handling). The RS agent
operates at the MAC-native boundary, bypassing the AXI adapter layer.

### 3.4 `mac_reset_if` — Reset control

```
UVM Reset Agent (MAC)             mac_tb_top.sv                   mac_top.sv
───────────────────                ─────────────                   ──────────
mac_rst_drv.sv                    mac_reset_if_h (mac_reset_if)   mac_rst (scalar)
  │ drives rst                     │ .rst assigned to              │ all mac_clk flops
  ▼                                ▼                               ▼
                              mac_rst                        TX pipeline, RX pipeline
                                                              PAUSE, MAC control

UVM Reset Agent (APB)             mac_tb_top.sv                   mac_top.sv
───────────────────                ─────────────                   ──────────
  ... same pattern ...           apb_reset_if_h                  apb_rst (scalar)
                                 (mac_reset_if)                  │ all apb_clk flops
                                                                 ▼
                                                              apb_regs_if, apb_regs
```

**What the TB does**:
- **MAC reset agent**: Asserts `mac_rst` to reset the entire MAC datapath, then
  deasserts it. The monitor watches for unexpected resets during tests.
- **APB reset agent**: Independently controls `apb_rst` for the register
  subsystem.

**When**: Every test — the DUT starts in reset (`INITIAL_RESET_VALUE = 1'b1`).
Reset agents handle the reset sequence before stimulus begins.

## 4. Inactive interfaces — why they exist

| Interface | Why it exists | Why it's not used yet |
|---|---|---|
| `ctrl_if` | Clean boundary between APB register file and MAC configuration | APB register file currently outputs scalar wires directly |
| `pause_if` | Modular PAUSE subsystem with typed ports between sub-blocks | PAUSE blocks currently use scalar wires |
| `stats_if` | Typed CDC boundary for statistics events and snapshot | Statistics events use scalar wires through `mac_event_collector` |

These three interfaces are **planned modular decomposition points**. They
represent the intended direction for future refactoring — replacing flat wires
with typed, checkable interface ports.

## 5. Data flow summary

```
                         TESTBENCH                              DUT
                         =========                              ===

  ┌─────────────────────────────────────────────────────────────────────┐
  │                                                                     │
  │  [APB Agent] ──apb_if──► scalar ──► mac_top ──apb_if──► apb_regs   │
  │                                                                     │
  │  [AXI TX Agent] ──axi4_stream_if──► scalar ──► tx_adapter          │
  │                                          │                          │
  │                                    mac_if(client_mp)                │
  │                                          │                          │
  │                                    mac_tx_path ──► tx_out_*        │
  │                                                                     │
  │  [RS Agent RX] ──mac_if──► scalar ──► mac_top RX ──► mac_rx_path   │
  │                                                                     │
  │                                    mac_rx_path ──► rx_adapter      │
  │                                          │                          │
  │                                    mac_if(client_mp)                │
  │                                          │                          │
  │  [AXI RX Agent] ◄──axi4_stream_if── scalar ◄── rx_adapter         │
  │                                                                     │
  │  [Reset Agent] ──mac_reset_if──► .rst ──► mac_rst ──► all flops   │
  │                                                                     │
  └─────────────────────────────────────────────────────────────────────┘
```

## 6. Key architectural observations

1. **Three interfaces serve three distinct purposes**:
   - `apb_if`: register read/write (control plane)
   - `axi4_stream_if`: data-plane TX/RX (client boundary)
   - `mac_if`: data-plane TX/RX (MAC-native boundary)

2. **`axi4_stream_if` is TB-only**: The RTL never instantiates it. The RTL uses
   scalar AXI4-Stream ports and internal adapters. The SystemVerilog interface
   exists only at the testbench boundary for UVM agent connectivity.

3. **`mac_if` serves two roles**: Internal (client adapters ↔ MAC pipeline) and
   external (RS agent ↔ DUT line side). The same interface definition is used
   in both contexts.

4. **All interfaces use scalar bridges**: Every interface instance in
   `mac_tb_top.sv` is bridged to scalar wires that enter the DUT. This is the
   standard pattern for testbench-to-DUT connection.

5. **Clocking blocks prevent races**: All interfaces use `#1step` input skew in
   their clocking blocks, ensuring the UVM agents see the exact values the DUT's
   flip-flops will capture.

## Reference

- `src/hdl_top/interfaces/apb_if.sv` — APB bus definition
- `src/hdl_top/interfaces/axi4_stream_if.sv` — AXI4-Stream bus definition
- `src/hdl_top/interfaces/mac_if.sv` — MAC stream bus definition
- `src/hdl_top/interfaces/mac_reset_if.sv` — Reset domain definition
- `src/hdl_top/interfaces/ctrl_if.sv` — Configuration boundary (unused)
- `src/hdl_top/interfaces/pause_if.sv` — PAUSE boundary (unused)
- `src/hdl_top/interfaces/stats_if.sv` — Statistics boundary (unused)
- `src/hdl_top/tb_top/mac_tb_top.sv` — testbench top (all scalar bridges)
- `src/hdl_top/integration/mac_top.sv` — DUT top (internal interface instances)
