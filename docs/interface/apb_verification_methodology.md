# APB Verification Methodology — Verifying Unused Interfaces Through Registers

## 1. Purpose

The three interfaces `ctrl_if`, `pause_if`, and `stats_if` are defined but not
instantiated — their signals travel as scalar wires. APB is the external control
plane that reads and writes registers mapped to those signals. Every signal in
those interfaces has a corresponding APB register, so the APB agent can verify
them **indirectly** through register read/write operations without instantiating
the interfaces.

The approach:
- **Write** config registers → stimulus enters the MAC through `ctrl_if` /
  `pause_if` signal paths
- **Read** status/count registers → observation exits the MAC through
  `stats_if` / `pause_if` signal paths
- **Assert** write-read consistency → confirms CDC handshake and signal
  propagation

## 2. Complete Register Map

### 2.1 Configuration Registers (RW)

| Address | Name | Width | Reset Value | Purpose |
|---|---|---|---|---|
| `0x0004` | `REG_GLOBAL_CONTROL` | 32 | `0x00000040` | Global MAC control (TX/RX enable, PAUSE, promiscuous, oversize) |
| `0x0008` | `REG_MAC_ADDR_LOW` | 32 | `0x00000000` | Station address bits [31:0] |
| `0x000C` | `REG_MAC_ADDR_HIGH` | 16 of 32 | `0x0000` | Station address bits [47:32] |
| `0x0010` | `REG_MAX_CLIENT_DATA` | 16 of 32 | `1500` (`0x05DC`) | Maximum client data octets per frame |
| `0x0028` | `REG_INTERRUPT_ENABLE` | 32 | `0x00000000` | Per-event interrupt enable mask |
| `0x003C` | `REG_PAUSE_TX_CONFIG` | 16 of 32 | `0x0000` | PAUSE TX enable, soft-request, quanta |
| `0x0040` | `REG_MAC_SPEED_CONFIG` | 32 | `0x00000004` | MAC speed select and override |
| `0x0044` | `REG_MAX_FRAME_SIZE` | 16 of 32 | `1518` (`0x0600`) | Maximum frame size |
| `0x0048` | `REG_MIN_FRAME_SIZE` | 16 of 32 | `64` (`0x0040`) | Minimum frame size |
| `0x0050+8i` | `REG_GROUP{i}_LOW` | 32 | `0x00000000` | Group address [31:0] for entry `i` |
| `0x0054+8i` | `REG_GROUP{i}_HIGH` | 17 of 32 | `0x0000` | Group address [47:32] + valid bit (bit 16) |

### 2.2 Status / Read-Only Registers

| Address | Name | Width | Source | Purpose |
|---|---|---|---|---|
| `0x0000` | `REG_VERSION` | 32 | hardcoded | Hardware ID: `0x41504231` ("APB1") |
| `0x0014` | `REG_OVERSIZE_CONTROL` | 32 | `cfg_control & 0x40` | Readback of oversize enable bit |
| `0x0018` | `REG_PAUSE_CONTROL` | 32 | `cfg_control & 0x30` | Readback of PAUSE/collision bits |
| `0x001C` | `REG_PAUSE_STATUS` | 32 | `status_snapshot[5]` | `pause_expired` (volatile) |
| `0x0020` | `REG_RX_STATUS` | 32 | `status_snapshot[4]` | `pause_active` (volatile) |
| `0x0024` | `REG_TX_STATUS` | 32 | `status_snapshot[6]` | `tx_error_event` (volatile) |
| `0x004C` | `REG_FRAME_SIZE_STATUS` | 32 | reserved | Frame size status (reserved, reads 0) |

### 2.3 Interrupt and Counter Registers

| Address | Name | R/W | Width | Source | Purpose |
|---|---|---|---|---|---|
| `0x002C` | `REG_INTERRUPT_STATUS` | **W1C** | 32 | `status_snapshot[3]` | Sticky interrupt causes (write 1 to clear) |
| `0x0030` | `REG_RX_INVALID_COUNT` | RO | 32 | `status_snapshot[0]` | Invalid frame counter (write bit 0 to clear) |
| `0x0034` | `REG_RX_OVERSIZE_COUNT` | RO | 32 | `status_snapshot[1]` | Oversize frame counter (write bit 0 to clear) |
| `0x0038` | `REG_RX_UNSUPPORTED_COUNT` | RO | 32 | `status_snapshot[2]` | Unsupported control frame counter (write bit 0 to clear) |

## 3. Bit-Field Breakdowns

### 3.1 `REG_GLOBAL_CONTROL` (0x0004)

| Bit | Name | Default | Description |
|---|---|---|---|
| 0 | `CTRL_RX_BIT` | 0 | Enable MAC RX path |
| 1 | reserved | 0 | — |
| 2 | `CTRL_TX_BIT` | 0 | Enable MAC TX path |
| 3 | `CTRL_CARRIER_BIT` | 0 | Carrier sense enable |
| 4 | `CTRL_PAUSE_BIT` | 0 | Enable PAUSE frame reception |
| 5 | `CTRL_COLLISION_BIT` | 0 | Collision detection enable |
| 6 | `CTRL_OVERSIZE_BIT` | **1** | Oversize frame handling enable (set by reset) |
| 7 | `CTRL_PROMISCUOUS_BIT` | 0 | Promiscuous mode enable |
| 31:8 | reserved | 0 | — |

### 3.2 `REG_PAUSE_TX_CONFIG` (0x003C)

| Bit | Name | Default | Description |
|---|---|---|---|
| 0 | `PAUSE_TX_ENABLE_BIT` | 0 | Enable PAUSE frame generation (TX) |
| 1 | `PAUSE_TX_SOFT_REQ_BIT` | 0 | Level-sensitive: triggers DUT to emit a PAUSE frame |
| 15:2 | `pause_quanta` | 0 | PAUSE quanta value (units of 512 bit-times) |

### 3.3 `REG_MAC_SPEED_CONFIG` (0x0040)

| Bit | Name | Default | Description |
|---|---|---|---|
| 2:0 | `mac_speed` | `3'b100` (100G) | Speed: 000=10G, 001=25G, 010=40G, 011=50G, 100=100G |
| 3 | `SPEED_OVERRIDE_BIT` | 0 | Apply programmed speed to active logic |
| 6:4 | `effective_mac_speed` | RO | Speed currently applied (CDC-synced, read-only) |
| 31:7 | reserved | 0 | — |

### 3.4 `REG_INTERRUPT_STATUS` (0x002C) — W1C

| Bit | Name | Description |
|---|---|---|
| 0 | `INT_RX_INVALID_BIT` | RX invalid frame event |
| 1 | `INT_RX_CRC_BIT` | RX CRC error event |
| 2 | `INT_RX_OVERSIZE_BIT` | RX oversize frame event |
| 3 | `INT_RX_UNSUPPORTED_BIT` | RX unsupported control frame event |
| 4 | `INT_PAUSE_ACTIVE_BIT` | PAUSE active event |
| 5 | `INT_PAUSE_EXPIRED_BIT` | PAUSE expired event |
| 6 | `INT_TX_ERROR_BIT` | TX error event |
| 31:7 | reserved | — |

### 3.5 Status Snapshot Array Layout

| Index | Content | Readable at |
|---|---|---|
| `[0]` | `invalid_count` | `REG_RX_INVALID_COUNT` (0x0030) |
| `[1]` | `oversize_count` | `REG_RX_OVERSIZE_COUNT` (0x0034) |
| `[2]` | `unsupported_count` | `REG_RX_UNSUPPORTED_COUNT` (0x0038) |
| `[3]` | `{25'b0, interrupt_status[6:0]}` | `REG_INTERRUPT_STATUS` (0x002C) |
| `[4]` | `{31'b0, pause_active}` | `REG_RX_STATUS` (0x0020) |
| `[5]` | `{31'b0, pause_expired}` | `REG_PAUSE_STATUS` (0x001C) |
| `[6]` | `{31'b0, tx_error_event}` | `REG_TX_STATUS` (0x0024) |
| `[7..11]` | reserved (zero) | — |

## 4. Register-to-Interface Mapping

### 4.1 `ctrl_if` — Configuration Boundary

| Register | `ctrl_if` Signal | Direction | What it controls |
|---|---|---|---|
| `REG_GLOBAL_CONTROL` | `ctrl[31:0]` | APB → MAC | TX/RX enable, PAUSE, promiscuous, oversize, carrier, collision |
| `REG_MAC_ADDR_LOW` | `mac_addr[31:0]` | APB → MAC | Station address low word |
| `REG_MAC_ADDR_HIGH` | `mac_addr[47:32]` | APB → MAC | Station address high word |
| `REG_MAX_CLIENT_DATA` | `max_client_data[15:0]` | APB → MAC | Max client data size |
| `REG_GROUP{i}_LOW` | `group_addr[i][31:0]` | APB → MAC | Group filter address low |
| `REG_GROUP{i}_HIGH` | `group_addr[i][47:32]`, `group_valid[i]` | APB → MAC | Group filter address high + valid |
| `REG_MAC_SPEED_CONFIG` | `ctrl` (bits 2:0) | APB → MAC | MAC speed select |
| All config registers | `update` | APB → MAC | CDC pulse after any config write |

### 4.2 `pause_if` — PAUSE Event and Admission Boundary

| Register | `pause_if` Signal | Direction | Relationship |
|---|---|---|---|
| `REG_PAUSE_TX_CONFIG` | `data_admit`, `control_admit` | APB → MAC (indirect) | TX PAUSE config gates admission |
| `REG_PAUSE_STATUS` | `timer_done`, `paused` | MAC → APB | PAUSE timer status via snapshot |
| `REG_RX_STATUS` | `pause_active` | MAC → APB | PAUSE active flag via snapshot |
| `REG_GLOBAL_CONTROL` bit 4 | `pause_event_valid` (enable) | APB → MAC (indirect) | Controls whether PAUSE frames are accepted |

### 4.3 `stats_if` — Statistics Event and Snapshot Boundary

| Register | `stats_if` Signal | Direction | Relationship |
|---|---|---|---|
| `REG_RX_INVALID_COUNT` | `rx_invalid_event` (counter) | MAC → APB | Counter incremented by event pulses |
| `REG_RX_OVERSIZE_COUNT` | `rx_oversize_event` (counter) | MAC → APB | Counter incremented by event pulses |
| `REG_RX_UNSUPPORTED_COUNT` | `rx_unsupported_control_event` (counter) | MAC → APB | Counter incremented by event pulses |
| `REG_TX_STATUS` | `tx_error_event` | MAC → APB | Event flag via snapshot |
| `REG_INTERRUPT_STATUS` | all 7 event bits | MAC → APB | Sticky interrupt causes via snapshot |
| `REG_RX_STATUS` | `pause_active` | MAC → APB | Event flag via snapshot |
| `REG_PAUSE_STATUS` | `pause_expired` | MAC → APB | Event flag via snapshot |
| (any status read) | `snapshot_request`, `snapshot_acknowledge` | APB → MAC → APB | Snapshot handshake triggered on every status register read |

### 4.4 Registers Not Mapped to Any Unused Interface

| Register | Used by | Notes |
|---|---|---|
| `REG_VERSION` | none | Read-only ID, no interface signal |
| `REG_OVERSIZE_CONTROL` | `ctrl_if` (readback) | Read-only mirror of `ctrl` bit 6 |
| `REG_PAUSE_CONTROL` | `ctrl_if` (readback) | Read-only mirror of `ctrl` bits 5:4 |
| `REG_FRAME_SIZE_STATUS` | none | Reserved, reads 0 |
| `REG_INTERRUPT_ENABLE` | none (scalar wire) | Interrupt mask, not part of any interface |

## 5. Verifying `ctrl_if` via APB

### 5.1 What is being tested

The `ctrl_if` carries configuration from APB to MAC. Every config register
write crosses a CDC boundary (`apb_clk` → `mac_clk`) via `apb_cfg_bridge`
before the MAC sees it. Verification confirms:
- CDC handshake completes (write → readback consistency)
- Configuration propagates to the MAC domain (effect observable)
- `cfg_update` pulse fires after each write

### 5.2 Verification approach

**Write stimulus:**
1. Write `REG_GLOBAL_CONTROL` with known pattern → verify `cfg_control` updates
2. Write `REG_MAC_ADDR_LOW/HIGH` → verify `cfg_mac_addr` updates
3. Write `REG_MAX_CLIENT_DATA` → verify `cfg_max_client_data` updates
4. Write all 4 group address pairs → verify `cfg_group_addr` / `cfg_group_valid`
5. Write `REG_MAC_SPEED_CONFIG` → verify `cfg_mac_speed` updates

**Read verification:**
1. Read back every config register → must return last written value
2. Read `REG_OVERSIZE_CONTROL` → must match `cfg_control[6]`
3. Read `REG_PAUSE_CONTROL` → must match `cfg_control[5:4]`

**Effect verification:**
1. Write `REG_GLOBAL_CONTROL` with TX+RX enable → send frames → verify
   DUT responds (config took effect)
2. Write MAC address → send unicast frame to that address → verify
   address filter accepts it
3. Write group address + valid → send multicast to that address → verify
   group filter accepts it

### 5.3 CDC latency note

After a config write, the CDC handshake adds 2-3 `apb_clk` cycles of latency
before the MAC domain sees the new value. A read immediately after a write
may return the old value. The verification methodology must either:
- Wait sufficient CDC cycles between write and read, or
- Use the `REG_GLOBAL_CONTROL` readback bits as a proxy for CDC completion

## 6. Verifying `pause_if` via APB

### 6.1 What is being tested

The `pause_if` connects three sub-blocks: event detection, timer, and admission
control. APB verifies two of the three paths:
- **Config path**: APB configures PAUSE enable and quanta
- **Observation path**: APB reads PAUSE status via snapshot registers

The event detection path is tested indirectly when the RS agent drives PAUSE
frames.

### 6.2 Verification approach

**Config path (APB writes):**
1. Write `REG_GLOBAL_CONTROL` bit 4 = 1 → enables PAUSE RX
2. Write `REG_PAUSE_TX_CONFIG` bit 0 = 1 → enables PAUSE TX generation
3. Write `REG_PAUSE_TX_CONFIG` bit 1 = 1 → triggers soft PAUSE request
4. Write `REG_PAUSE_TX_CONFIG` bits 15:2 → sets PAUSE quanta value

**Observation path (APB reads):**
1. Read `REG_RX_STATUS` bit 0 → checks `pause_active` (from snapshot)
2. Read `REG_PAUSE_STATUS` bit 0 → checks `pause_expired` (from snapshot)
3. Read `REG_INTERRUPT_STATUS` bits 4:5 → checks PAUSE interrupt causes

**Full PAUSE cycle test:**
1. APB enables RX PAUSE (`REG_GLOBAL_CONTROL` bit 4)
2. RS agent sends PAUSE frame with time = N
3. APB reads `REG_RX_STATUS` → `pause_active` = 1
4. APB waits (N × 512 bit-times)
5. APB reads `REG_PAUSE_STATUS` → `pause_expired` = 1
6. APB reads `REG_RX_STATUS` → `pause_active` = 0

**TX admission test:**
1. APB enables TX PAUSE (`REG_PAUSE_TX_CONFIG` bit 0)
2. APB sets soft request (`REG_PAUSE_TX_CONFIG` bit 1)
3. AXI TX agent attempts to send frame → `tready` should be low (admission
   gated)
4. APB clears soft request → admission re-opens

### 6.3 Snapshot timing

Every status register read triggers `status_request`, which initiates the
snapshot CDC handshake. `pready` is held low until `snapshot_acknowledge`
returns (1-2 `mac_clk` cycles). The APB driver handles this automatically
through wait states.

## 7. Verifying `stats_if` via APB

### 7.1 What is being tested

The `stats_if` carries event pulses from the MAC datapath and a frozen snapshot
back to APB. Verification confirms:
- Event pulses increment counters (event path)
- Snapshot captures all counters atomically (snapshot path)
- Counter clear writes reset counters (clear path)

### 7.2 Verification approach

**Event path (APB observes, RS agent stimulates):**
1. RS agent sends frame with bad CRC → `rx_crc_event` fires
2. APB reads `REG_RX_INVALID_COUNT` → counter should be 1
3. RS agent sends 10 more bad-CRC frames → counter should be 11
4. APB reads `REG_INTERRUPT_STATUS` bit 1 → CRC error bit set

**Oversize event:**
1. RS agent sends frame exceeding `REG_MAX_FRAME_SIZE` → `rx_oversize_event`
2. APB reads `REG_RX_OVERSIZE_COUNT` → counter should increment

**Unsupported control event:**
1. RS agent sends unsupported control frame → `rx_unsupported_control_event`
2. APB reads `REG_RX_UNSUPPORTED_COUNT` → counter should increment

**Counter clear path:**
1. APB writes `0x00000001` to `REG_RX_INVALID_COUNT` → clears invalid counter
2. APB reads `REG_RX_INVALID_COUNT` → should return 0
3. Repeat for oversize and unsupported counters

**TX error event:**
1. Inject TX error condition → `tx_error_event` fires
2. APB reads `REG_TX_STATUS` bit 0 → should be 1

**Interrupt path:**
1. APB writes `REG_INTERRUPT_ENABLE` with mask (e.g., `0x00000002` for CRC)
2. RS agent sends bad-CRC frame
3. APB reads `REG_INTERRUPT_STATUS` → bit 1 set (sticky)
4. APB writes `0x00000002` to `REG_INTERRUPT_STATUS` → bit clears (W1C)

### 7.3 Snapshot atomicity

When multiple events fire between two APB reads, the snapshot captures all of
them atomically. Example:
1. RS agent sends 3 bad-CRC frames + 2 oversize frames
2. APB reads `REG_RX_INVALID_COUNT` → returns 3 (not partial)
3. APB reads `REG_RX_OVERSIZE_COUNT` → returns 2 (not partial)

The snapshot is frozen at the moment `snapshot_request` toggles — it does not
change during the APB read sequence.

## 8. Coverage Points

### 8.1 Config register coverage

- Every config register written and read back at least once
- Every bit-field in `REG_GLOBAL_CONTROL` exercised individually
- Group address registers: all 4 entries written with different values
- Write-read consistency: every write followed by a read returning the same
  value (after CDC latency)

### 8.2 PAUSE state coverage

- `pause_active` transitions: 0→1 (PAUSE received), 1→0 (timer expired)
- `pause_expired` pulse observed on read
- TX admission gate: `data_admit` deasserted during PAUSE, reasserted after
- Soft PAUSE request: triggered and cleared

### 8.3 Statistics counter coverage

- Each counter incremented from 0 to at least 1
- Counter clear verified for each counter
- Multiple events between reads (snapshot atomicity)
- Counter overflow (optional: 32-bit wrap-around)

### 8.4 Interrupt coverage

- Each interrupt bit set by its corresponding event
- W1C clear verified for each bit
- Multiple bits set simultaneously
- Interrupt enable mask: event with mask disabled does not set status bit

## Reference

- `src/hdl_top/registers/reg_map_pkg.sv` — address and bit-field constants
- `src/hdl_top/registers/apb_regs.sv` — readback mux
- `src/hdl_top/registers/reg_file.sv` — write decode
- `src/hdl_top/registers/apb_cfg_bridge.sv` — CDC bundle composition
- `src/hdl_top/statistics/mac_stats.sv` — status snapshot array
- `src/hdl_top/interfaces/ctrl_if.sv` — configuration interface
- `src/hdl_top/interfaces/pause_if.sv` — PAUSE interface
- `src/hdl_top/interfaces/stats_if.sv` — statistics interface
- `docs/interface/apb_agent_contract.md` — APB agent protocol contract
