# UVM RAL — Beginner Notes

## 1. What is RAL?

**RAL = Register Abstraction Layer.** It is a UVM methodology for modeling
hardware registers in software. Instead of manually crafting APB transactions
with raw addresses and data, you work with named register objects.

Think of it as a **remote control for your DUT's registers**. You say
"write 0x85 to global_control" and RAL handles the APB protocol, timing,
and address lookup for you.

### Why not just use raw APB sequences?

You can, and some tests do. But RAL gives you:

| Benefit | What it means |
|---|---|
| **Named registers** | `global_control` instead of `0x0004` |
| **Automatic mirror** | RAL remembers what you wrote without you storing it |
| **Type safety** | Write 32-bit to a 32-bit register; mismatch is an error |
| **Coverage** | RAL auto-collects which registers were accessed |
| **Reuse** | Same model works across tests and projects |

## 2. The Three Pieces of RAL

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR TEST CODE                          │
│                                                             │
│  ral_h.global_control.write(status, 32'h00000085);         │
│  ral_h.rx_status.read(status, data);                        │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────┐                   │
│  │         UVM RAL MODEL                │                   │
│  │  (mac_ral_block_c in mac_ral.svh)    │                   │
│  │                                      │                   │
│  │  • knows all register addresses      │                   │
│  │  • knows access types (RW/RO/W1C)    │                   │
│  │  • tracks mirrored values            │                   │
│  │  • calls the adapter                 │                   │
│  └──────────────┬───────────────────────┘                   │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                   │
│  │         ADAPTER                       │                   │
│  │  (mac_apb_reg_adapter_c)             │                   │
│  │                                      │                   │
│  │  Converts: uvm_reg_bus_op            │                   │
│  │       ↔  apb_transfer_t              │                   │
│  └──────────────┬───────────────────────┘                   │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                   │
│  │       APB DRIVER                     │                   │
│  │  (apb_driver_c)                      │                   │
│  │                                      │                   │
│  │  Drives: psel, penable, pwrite,      │                   │
│  │          paddr, pwdata               │                   │
│  └──────────────┬───────────────────────┘                   │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                   │
│  │         DUT (mac_top)                │                   │
│  │  apb_regs → reg_file → CDC → MAC     │                   │
│  └──────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### Piece 1: The RAL Model

Located in `src/hvl_top/tb/mac_ral.svh`. It is a software mirror of the
hardware register file.

```systemverilog
class mac_ral_block_c extends uvm_reg_block;
  mac_ral_reg_c registers[string];  // associative array: name → register

  function void build();
    default_map = create_map("apb_map", '0, 4, UVM_LITTLE_ENDIAN, 1);

    // Each line below creates one register:
    void'(add_register("version",         16'h0000, "RO",  32'h41504231));
    void'(add_register("global_control",  16'h0004, "RW",  32'h00000040));
    void'(add_register("mac_addr_low",    16'h0008, "RW"));
    void'(add_register("pause_status",    16'h001C, "RO",  '0, 1));  // volatile
    void'(add_register("interrupt_status",16'h002C, "W1C", '0, 1));
    // ... all registers defined here

    lock_model();  // freeze the model — no more changes allowed
  endfunction
endclass
```

Each `add_register()` call takes:
- **name** — how you refer to it in code
- **address** — the APB address (from `reg_map_pkg`)
- **access** — `"RW"`, `"RO"`, or `"W1C"` (write-1-to-clear)
- **reset value** — what the register holds after reset
- **volatile** — 1 if the value can change without a bus write (status registers)

### Piece 2: The Adapter

Located in `src/hvl_top/tb/mac_ral.svh` (same file, top). It converts between
RAL's generic format and APB transfers.

```systemverilog
class mac_apb_reg_adapter_c extends uvm_reg_adapter;

  // RAL → APB: convert a write/read request into an APB transfer
  function uvm_reg_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_transfer_t request_h;
    request_h.pwrite = (rw.kind == UVM_WRITE);
    request_h.addr   = rw.addr;
    request_h.wdata  = rw.data;
    return request_h;
  endfunction

  // APB → RAL: convert an APB response back into RAL format
  function void bus2reg(uvm_sequence_item bus_item,
                         ref uvm_reg_bus_op rw);
    apb_transfer_t response_h;
    $cast(response_h, bus_item);
    rw.kind   = response_h.pwrite ? UVM_WRITE : UVM_READ;
    rw.addr   = response_h.addr;
    rw.data   = response_h.pwrite ? response_h.wdata : response_h.rdata;
    rw.status = (response_h.status == APB_OK) ? UVM_IS_OK : UVM_NOT_OK;
  endfunction
endclass
```

### Piece 3: Your Test Code

```systemverilog
class my_test extends uvm_test;
  mac_ral_block_c ral_h;

  task run_phase(uvm_phase phase);
    uvm_status_e status;
    uvm_reg_data_t data;

    // === WRITE ===
    // This single line does everything:
    // 1. RAL looks up "global_control" → address 0x0004
    // 2. Adapter converts to apb_transfer_t
    // 3. APB driver drives psel/penable/pwrite/paddr/pwdata
    // 4. DUT captures the write
    // 5. RAL updates its mirror
    ral_h.global_control.write(status, 32'h00000085);
    `uvm_info("TEST", $sformatf("Write status: %s", status.name()), UVM_LOW)

    // === READ ===
    // Same flow in reverse:
    // 1. RAL looks up "rx_status" → address 0x0020
    // 2. Adapter converts to APB read
    // 3. APB driver drives the read
    // 4. DUT returns prdata
    // 5. RAL stores result in 'data'
    ral_h.rx_status.read(status, data);
    `uvm_info("TEST", $sformatf("rx_status = 0x%08h", data), UVM_LOW)

    // === MIRROR CHECK ===
    // RAL remembers what you wrote. You can compare:
    ral_h.global_control.write(status, 32'h00000095);
    ral_h.global_control.read(status, data);
    if (data == ral_h.global_control.get_mirrored_value())
      `uvm_info("TEST", "Mirror matches!", UVM_LOW)
    else
      `uvm_error("TEST", "Mirror mismatch!")
  endtask
endclass
```

## 3. Key Concepts

### Mirror vs Desired

```
┌─────────────────────────────────────────────────┐
│  RAL has two copies of each register:           │
│                                                 │
│  MIRROR = what the hardware currently holds     │
│           (updated after read/write)            │
│                                                 │
│  DESIRED = what you WANT it to be               │
│            (applied on next update())            │
│                                                 │
│  Most of the time you only use write() and      │
│  read(), which update both automatically.       │
└─────────────────────────────────────────────────┘
```

| Method | What it does | When to use |
|---|---|---|
| `write(status, data)` | Sends APB write, updates mirror | Normal register writes |
| `read(status, data)` | Sends APB read, updates mirror | Normal register reads |
| `get_mirrored_value()` | Returns last known value (no bus transaction) | Check what RAL thinks the register holds |
| `get()` | Same as `get_mirrored_value()` | Alias |
| `set(data)` | Sets DESIRED value (no bus transaction) | Queue up a value, apply later with `update()` |
| `update(status)` | Writes DESIRED to hardware if it differs from MIRROR | Batch updates |
| `predict(data)` | Update mirror without a bus transaction | After you know the value from other means |

### Access Types

| Type | RAL string | Behavior |
|---|---|---|
| Read-Write | `"RW"` | Normal register — read and write |
| Read-Only | `"RO"` | Writes are ignored by hardware; RAL warns |
| Write-1-to-Clear | `"W1C"` | Writing 1 clears the bit; RAL models as `"RW"` in map (field-level policy handles W1C) |
| Volatile | flag = 1 | Value may change without a bus write (status registers, counters) |

### Volatile Registers

In `mac_ral.svh`, status registers are marked volatile:

```systemverilog
void'(add_register("pause_status",  16'h001C, "RO", '0, 1));  // volatile = 1
void'(add_register("rx_status",     16'h0020, "RO", '0, 1));  // volatile = 1
void'(add_register("rx_invalid_count", 16'h0030, "RO", '0, 1)); // volatile = 1
```

This tells RAL: "don't complain if the value changes between reads — the
hardware can update this register without a bus write."

## 4. How RAL Connects to the APB Agent

### Binding in the Environment

In `mac_env` or `mac_tb_top`, the RAL model is connected to the APB sequencer
through the adapter:

```systemverilog
// In end_of_elaboration_phase:
ral_h.default_map.set_sequencer(apb_seqr_h, apb_adapter_h);
```

This tells RAL: "when you need to do a bus transaction, send it to
`apb_seqr_h` using `apb_adapter_h` to convert the format."

### The Flow

```
Your test                    RAL                     Adapter              APB Agent
   │                          │                        │                    │
   │  ral.write(0x0004, val)  │                        │                    │
   │─────────────────────────>│                        │                    │
   │                          │  reg2bus(0x0004, val)  │                    │
   │                          │───────────────────────>│                    │
   │                          │                        │  create transfer   │
   │                          │                        │───────────────────>│
   │                          │                        │                    │
   │                          │                        │                    │  drive APB
   │                          │                        │                    │  (setup + access)
   │                          │                        │                    │
   │                          │                        │  bus2reg(response) │
   │                          │<───────────────────────│                    │
   │                          │                        │                    │
   │<── status = UVM_IS_OK ──│                        │                    │
```

## 5. Practical Examples with This Design

### Example 1: Boot the MAC

```systemverilog
task boot_mac();
  uvm_status_e status;

  // Enable TX + RX + oversize handling
  // REG_GLOBAL_CONTROL = bit 0 (RX) + bit 2 (TX) + bit 6 (oversize)
  ral_h.global_control.write(status, 32'h00000045);

  // Set station address
  ral_h.mac_addr_low.write(status, 32'h0403_0201);   // DA[31:0]
  ral_h.mac_addr_high.write(status, 32'h0000_0806);  // DA[47:32] = 0x0806

  // Set max frame size
  ral_h.max_frame_size.write(status, 32'd1518);

  // Set MAC speed to 100G
  ral_h.mac_speed_config.write(status, 32'h00000004);
endtask
```

### Example 2: Check PAUSE Status

```systemverilog
task check_pause();
  uvm_status_e status;
  uvm_reg_data_t data;

  // Read PAUSE status (triggers snapshot CDC)
  ral_h.pause_status.read(status, data);
  if (data[0])
    `uvm_info("TEST", "PAUSE timer expired", UVM_LOW)

  ral_h.rx_status.read(status, data);
  if (data[0])
    `uvm_info("TEST", "PAUSE is active", UVM_LOW)
endtask
```

### Example 3: Clear Interrupts

```systemverilog
task clear_interrupts();
  uvm_status_e status;

  // W1C: write 1 to clear each bit
  // Clear all 7 interrupt bits
  ral_h.interrupt_status.write(status, 32'h0000007F);
endtask
```

### Example 4: Read Statistics Counters

```systemverilog
task read_stats();
  uvm_status_e status;
  uvm_reg_data_t data;

  // Each read triggers a snapshot CDC handshake
  ral_h.rx_invalid_count.read(status, data);
  `uvm_info("STATS", $sformatf("Invalid frames: %0d", data), UVM_LOW)

  ral_h.rx_oversize_count.read(status, data);
  `uvm_info("STATS", $sformatf("Oversize frames: %0d", data), UVM_LOW)

  ral_h.rx_unsupported_count.read(status, data);
  `uvm_info("STATS", $sformatf("Unsupported control: %0d", data), UVM_LOW)
endtask
```

### Example 5: Configure Group Address Filter

```systemverilog
task set_group_addr(int index, logic [47:0] addr);
  uvm_status_e status;

  ral_h.registers[$sformatf("group%0d_low", index)].write(status, addr[31:0]);
  // Bit 16 = valid, bits 15:0 = addr[47:32]
  ral_h.registers[$sformatf("group%0d_high", index)].write(status,
    {15'b0, 1'b1, addr[47:32]});
endtask
```

## 6. Direct APB vs RAL — When to Use Which

| Method | Code example | When to use |
|---|---|---|
| **RAL** | `ral_h.global_control.write(status, val)` | Normal test code, self-documenting, uses mirror |
| **Direct APB** | `apb_write_sequence_c::do_write(16'h0004, val)` | Raw protocol testing, edge cases, when RAL model doesn't exist yet |

Both go through the same APB driver. RAL is just a friendlier layer on top.

In this design:
- `mac_register_access_test_c` uses RAL frontdoor
- `mac_pause_rx_test_c` uses direct APB sequences
- Both are valid approaches

## 7. Common Gotchas

### Mirror drift

If you write via direct APB (bypassing RAL), the RAL mirror won't know.
The mirror only updates when you use `ral_h.write()` or `ral_h.read()`.

```systemverilog
// BAD: RAL mirror is now out of sync
apb_write_sequence_c::do_write(16'h0004, 32'h00000095);

// FIX: update mirror without a bus transaction
ral_h.global_control.predict(32'h00000095);
```

### Volatile registers

Status registers change on their own. If you `read()` twice, the value may
differ — that's correct, not a bug.

```systemverilog
// This is fine — rx_invalid_count can change between reads
ral_h.rx_invalid_count.read(status, data1);
// ... some frames arrive ...
ral_h.rx_invalid_count.read(status, data2);
// data1 != data2 is expected
```

### W1C registers

`interrupt_status` is write-1-to-clear. RAL models this as RW at the map level,
but the field-level policy handles the clear behavior.

```systemverilog
// To clear bit 1 (CRC error):
ral_h.interrupt_status.write(status, 32'h00000002);

// To clear ALL bits:
ral_h.interrupt_status.write(status, 32'h0000007F);
```

### Lock model

After `build()` calls `lock_model()`, you cannot add more registers. The model
is frozen. If you need to modify it, you must rebuild.

## 8. Quick Reference Card

```
WRITE:    ral_h.<name>.write(status, value);
READ:     ral_h.<name>.read(status, data_variable);
MIRROR:   ral_h.<name>.get_mirrored_value();
PREDICT:  ral_h.<name>.predict(value);  // update mirror, no bus
SET:      ral_h.<name>.set(value);      // set desired, no bus
UPDATE:   ral_h.<name>.update(status);  // write desired if differs
CHECK:    ral_h.<name>.mirror(status);  // read and compare to mirror

BY NAME:  ral_h.registers["name"].write(status, value);  // dynamic lookup
```

## Reference

- `src/hvl_top/tb/mac_ral.svh` — this design's RAL model + adapter
- `src/hdl_top/registers/reg_map_pkg.sv` — address constants
- `src/hvl_top/test/mac_register_access_test.svh` — example using RAL frontdoor
- UVM 1.2 User Guide, Chapter 9 — Register Abstraction Layer
