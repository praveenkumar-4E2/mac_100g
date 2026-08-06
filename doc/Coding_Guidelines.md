# UVM / SystemVerilog Coding Guidelines

**Purpose:** This document defines coding standards for SystemVerilog/UVM verification environments. It is written so that both experienced verification engineers and fresh graduates can follow it without ambiguity, and so that all testbench code across the project looks and behaves consistently.

---

## Table of Contents

1. Naming Conventions
   1.1 Signal & Variable Naming
   1.2 Class Member Variable Naming
   1.3 Function/Task/Method Naming
   1.4 Class Naming (`_c` suffix convention)
   1.5 Constants and Parameters
   1.6 File Naming
2. Code Formatting and Style
   2.1 Indentation
   2.2 Line Breaks and Operator Spacing
   2.3 Begin/End (Brace) Style
   2.4 Maximum Line Length
   2.5 Whitespace and Blank Lines
   2.6 Signal and Port Declaration Alignment
   2.7 Class Member Ordering
   2.8 Quick Formatting Tips
3. Commenting
   3.1 When to Comment
   3.2 Comment Style (Block vs Inline)
   3.3 Class/Method Header Documentation
   3.4 TODO / FIXME Comments
4. Error Handling
   4.1 Consistent Reporting via `uvm_*` Macros
   4.2 Handling Specific Error/Failure Types
   4.3 Logging and Verbosity Best Practices
5. Code Readability and Simplicity
   5.1 Avoiding Overly Complex Logic
   5.2 Keeping Tasks/Functions Short and Focused
   5.3 Meaningful Names Everywhere
   5.4 DRY Principle in UVM
6. SystemVerilog Assertions (SVA) Style Guide
   6.1 Assertion & Property Naming
   6.2 Immediate vs. Concurrent Assertions
   6.3 Assertion Severity and Messages
   6.4 Assertion Placement and Reuse
7. Interface & Clocking Block Conventions
   7.1 Interface Naming and Structure
   7.2 Modport Usage
   7.3 Clocking Block Naming and Skew
   7.4 Virtual Interface Handling in Classes
8. Method Declaration Style (`extern`)
   8.1 Declaring Methods with `extern` for Readability

---

# 1. Naming Conventions

## 1.1 Signal & Variable Naming (snake_case)

**Rule:** All local variables, signals, ports, and task/function arguments shall use `snake_case` — all lowercase, words separated by underscores.

**Steps to Follow:**
1. Use only lowercase letters, digits, and underscores.
2. Start with a letter, never a digit or underscore.
3. Separate each logical word with a single underscore.
4. Use full words over cryptic abbreviations (`frame_length` not `frm_len`), except for well-known industry terms (`crc`, `fifo`, `addr`).
5. For active-low signals, append `_n` (e.g., `reset_n`, `cs_n`).

**Correct Example:**
```systemverilog
bit [7:0]  frame_length;
logic      tx_valid;
logic      reset_n;

task automatic drive_frame(input eth_frame_t frame, input int inter_frame_gap);
  // ...
endtask
```

**Incorrect Example:**
```systemverilog
bit [7:0]  FrameLength;   // PascalCase used for a variable
logic      TXvalid;       // inconsistent casing
logic      RSTN;          // ALL CAPS, no underscore separation
```

---

## 1.2 Class Member Variable Naming (`m_` prefix)

**Rule:** Class member (property) variables shall be prefixed with `m_` to distinguish them from local variables and method arguments at a glance. Config/handle references to other components use descriptive suffixes (`_cfg`, `_h`).

**Steps to Follow:**
1. Prefix every class-scope variable with `m_`.
2. Keep the remainder of the name in `snake_case`.
3. Use `_cfg` suffix for configuration object handles and `_h` suffix for other component/object handles where the type isn't already obvious from the name.
4. Never reuse a member name for a local variable inside a method of the same class.

**Correct Example:**
```systemverilog
class axi_driver_c extends uvm_driver #(axi_seq_item_c);
  axi_agent_cfg_c   m_cfg;
  int                  m_frames_sent;
  virtual mac_if       m_vif;

  task run_phase(uvm_phase phase);
    axi_seq_item_c local_item; // local variable, no m_ prefix
    // ...
  endtask
endclass
```

**Incorrect Example:**
```systemverilog
class axi_driver_c extends uvm_driver #(axi_seq_item_c);
  axi_agent_cfg_c   cfg;         // ambiguous - looks like a local var
  int                  framesSent;  // camelCase, no m_ prefix
endclass
```

---

## 1.3 Function/Task/Method Naming (verb_noun, snake_case)

**Rule:** Methods, tasks, and functions shall be named `verb_noun` in `snake_case`, clearly describing the action performed.

**Steps to Follow:**
1. Begin the name with an action verb (`get`, `set`, `drive`, `check`, `build`, `wait_for`).
2. Follow the verb with the noun/object it acts on.
3. Boolean-returning functions should read like a question: `is_`, `has_`, `should_`.
4. Avoid vague verbs like `do_stuff`, `process`, `handle` without qualifying what is being processed.

**Correct Example:**
```systemverilog
function bit is_frame_valid(eth_frame_t frame);
  return (frame.crc == compute_crc(frame));
endfunction

task automatic wait_for_reset_deassertion();
  @(posedge m_vif.reset_n);
endtask
```

**Incorrect Example:**
```systemverilog
function bit check(eth_frame_t frame);      // vague, no object
  return (frame.crc == compute_crc(frame));
endfunction

task automatic Reset();                      // PascalCase task, no verb_noun clarity
endtask
```

---

## 1.4 Class Naming (`_c` suffix convention)

**Rule:** Class names shall be `lower_snake_case`, identify the UVM role via a role segment (`_agent`, `_driver`, `_monitor`, `_sequencer`, `_sequence`, `_seq_item`, `_scoreboard`, `_env`, `_test`, `_cfg`), and always end with a final `_c` suffix marking the identifier as a **class type**. This makes it instantly obvious, anywhere in the code, whether an identifier refers to a class type versus a handle/instance/macro of the same base name.

> Note: The `_c` suffix is a project-specific convention layered on top of the general SystemVerilog/UVM `snake_case` class-naming style. It is especially useful in mixed RTL/testbench codebases and code reviews, where `axi_driver_c` unambiguously reads as "the class", while a handle can safely be named `axi_driver` or `m_tx_drv` without any naming collision.

**Steps to Follow:**
1. Prefix the class with the block/protocol name (`mac_`, `pcie_`, `axi_`).
2. Add a descriptive middle segment if needed (`tx`, `rx`).
3. Add the UVM role suffix (`_driver`, `_monitor`, `_env`, etc.).
4. Terminate the name with `_c` as the final suffix, after the role segment.
5. Match the file name exactly to the class name, including the `_c` (see 1.6).
6. Name the class handle/instance without the `_c` (e.g., a variable of type `axi_driver_c` can be named `m_tx_drv`), so type and instance are never confused.

**Correct Example:**
```systemverilog
class axi_driver_c     extends uvm_driver #(axi_seq_item_c);
class axi_seq_item_c   extends uvm_sequence_item;
class mac_env_c           extends uvm_env;
class mac_base_test_c     extends uvm_test;

// instance/handle - no _c suffix, so it reads distinctly from the type name
axi_driver_c m_tx_drv;
```

**Incorrect Example:**
```systemverilog
class MacTxDriver extends uvm_driver #(MacTxSeqItem); // PascalCase, inconsistent with uvm_driver
class axi_driver extends uvm_driver #(axi_seq_item); // missing _c, ambiguous vs. a handle of the same name
class Driver1_c     extends uvm_driver #(Item1_c);        // no protocol/role context at all
```

---

## 1.5 Constants and Parameters (SCREAMING_SNAKE_CASE)

**Rule:** `parameter`, `localparam`, and `` `define `` macros representing fixed values shall use `SCREAMING_SNAKE_CASE`.

**Steps to Follow:**
1. Use all uppercase letters and digits.
2. Separate words with underscores.
3. Group related constants with a common prefix (`MAC_MIN_FRAME_SIZE`, `MAC_MAX_FRAME_SIZE`).
4. Never hardcode magic numbers directly in code — always route through a named constant/parameter.

**Correct Example:**
```systemverilog
parameter int MAC_MIN_FRAME_SIZE = 64;
parameter int MAC_MAX_FRAME_SIZE = 1518;
`define MAC_PAUSE_ETHERTYPE 16'h8808

if (frame.length < MAC_MIN_FRAME_SIZE) begin
  `uvm_error("RUNT_FRAME", "Frame below minimum size")
end
```

**Incorrect Example:**
```systemverilog
if (frame.length < 64) begin   // magic number, unclear intent, hard to maintain
  `uvm_error("ERR", "bad frame")
end
```

---

## 1.6 File Naming

**Rule:** One class per file. The file name shall exactly match the class name it contains, with a `.sv` extension. Package files are named `<block>_pkg.sv`; interfaces are named `<block>_if.sv`.

**Steps to Follow:**
1. Name the file identically to the primary class inside it (case-sensitive match).
2. Do not bundle unrelated classes into a single file.
3. Group files into directories by role: `agents/`, `env/`, `seq/`, `tests/`.
4. List files inside the package's `` `include `` block in dependency order (base classes before derived classes).

**Correct Example:**
```
mac_agents/axi_driver_c.sv        -> class axi_driver_c
mac_agents/axi_monitor_c.sv       -> class axi_monitor_c
mac_env/mac_scoreboard_c.sv          -> class mac_scoreboard_c
mac_pkg.sv                           -> package mac_pkg;
```

**Incorrect Example:**
```
tb_stuff.sv   // contains driver, monitor, and scoreboard classes all mixed together
```

---

# 2. Code Formatting and Style

## 2.1 Indentation (2 spaces, no tabs)

**Rule:** Use 2 spaces per indentation level. Tabs are prohibited, since tab width renders inconsistently across editors and diff/review tools.

**Steps to Follow:**
1. Configure your editor to insert spaces when the Tab key is pressed.
2. Indent one level (2 spaces) for every nested block: `begin/end`, `if/else`, `class`, `task`, `function`, `always`.
3. Align `end`, `endclass`, `endtask`, `endfunction` with the opening keyword's indentation level.
4. Run a lint/formatting check before every commit to catch mixed tabs/spaces.

**Correct Example:**
```systemverilog
task automatic run_phase(uvm_phase phase);
  phase.raise_objection(this);
  if (m_cfg.enable_pause) begin
    send_pause_frame();
  end
  phase.drop_objection(this);
endtask
```

**Incorrect Example:**
```systemverilog
task automatic run_phase(uvm_phase phase);
    phase.raise_objection(this);
        if (m_cfg.enable_pause) begin
    send_pause_frame();
        end
  phase.drop_objection(this);
endtask
```

---

## 2.2 Line Breaks and Spacing Around Operators

**Rule:** Always place a single space around binary operators (`=`, `==`, `&&`, `+`, `<<`, etc.) and after commas. Break long expressions at logical operators, with the operator at the start of the continuation line.

**Steps to Follow:**
1. Add one space before and after `=`, `==`, `!=`, `&&`, `||`, `+`, `-`, `<`, `>`, etc.
2. Add one space after every comma in argument/port lists.
3. When a condition or expression exceeds the line-length limit (see 2.4), break it before an operator and indent the continuation by one extra level.
4. Do not add space immediately inside parentheses: `foo(a, b)`, not `foo( a, b )`.

**Correct Example:**
```systemverilog
if (frame.dest_addr == BROADCAST_ADDR ||
    frame.dest_addr == m_cfg.local_addr) begin
  accept_frame(frame);
end

sum = a + b - (c * 2);
```

**Incorrect Example:**
```systemverilog
if(frame.dest_addr==BROADCAST_ADDR||frame.dest_addr==m_cfg.local_addr)begin
accept_frame(frame);
end

sum=a+b-(c*2);
```

---

## 2.3 Begin/End Style (Always Explicit)

**Rule:** Always use explicit `begin ... end` for any block containing more than one statement, and prefer explicit `begin/end` even for single-statement blocks in sequential/procedural code for consistency and safer future edits.

**Steps to Follow:**
1. Place `begin` on the same line as the `if`, `else`, `for`, `foreach`, or `always` keyword (K&R-style, not Allman).
2. Place the matching `end` aligned with the start of the opening keyword's line.
3. Never omit `begin/end` "to save space" — a future added line without it is a common source of bugs.
4. For `if/else if/else` chains, place `else` on the same line as the preceding `end`.

**Correct Example:**
```systemverilog
if (crc_error) begin
  `uvm_error("CRC_ERR", "CRC mismatch detected")
  discard_frame();
end else if (length_error) begin
  `uvm_error("LEN_ERR", "Invalid length field")
end else begin
  forward_frame();
end
```

**Incorrect Example:**
```systemverilog
if (crc_error)
  `uvm_error("CRC_ERR", "CRC mismatch detected")
  discard_frame();   // BUG: this always executes, indentation is misleading
```

---

## 2.4 Maximum Line Length (100 Characters)

**Rule:** No line of code shall exceed 100 characters, including comments.

**Steps to Follow:**
1. Configure your editor with a ruler/guide at column 100.
2. Break long argument lists or conditions across multiple lines, one argument or condition term per line if needed.
3. Prefer descriptive but concise names to avoid needing extremely long lines in the first place.
4. Run a line-length lint check as part of the pre-commit/CI pipeline.

**Correct Example:**
```systemverilog
`uvm_info(get_type_name(),
          $sformatf("Frame sent: len=%0d dest=%0h", frame.length, frame.dest_addr),
          UVM_MEDIUM)
```

**Incorrect Example:**
```systemverilog
`uvm_info(get_type_name(), $sformatf("Frame sent: len=%0d dest=%0h src=%0h vlan=%0d pcp=%0d dei=%0d", frame.length, frame.dest_addr, frame.src_addr, frame.vlan_id, frame.pcp, frame.dei), UVM_MEDIUM)
```

---

## 2.5 Whitespace and Blank Lines

**Rule:** Use exactly one blank line to separate logical groups of statements within a method, and exactly one blank line between methods/classes. Never use two or more consecutive blank lines, and never leave trailing whitespace at the end of a line.

**Steps to Follow:**
1. Group related statements (e.g., all randomization-related lines, then all driving-related lines) and separate groups with a single blank line.
2. Leave exactly one blank line between the `endfunction`/`endtask` of one method and the next declaration.
3. Configure your editor to strip trailing whitespace on save.
4. Run `git diff` before committing — stray whitespace-only changes are a common source of noisy, unreadable diffs.

**Correct Example:**
```systemverilog
task automatic send_frame(axi_seq_item_c item);
  // Step 1: randomize the frame
  if (!item.randomize()) begin
    `uvm_error("RAND_FAIL", "Failed to randomize axi_seq_item_c")
  end

  // Step 2: drive it onto the interface
  vif.tx_valid <= 1'b1;
  vif.tx_data  <= item.payload;
  @(posedge vif.clk);
  vif.tx_valid <= 1'b0;
endtask

task automatic send_pause_frame(int unsigned quanta);
  // ...
endtask
```

**Incorrect Example:**
```systemverilog
task automatic send_frame(axi_seq_item_c item);
   if (!item.randomize()) begin      
    `uvm_error("RAND_FAIL", "Failed to randomize axi_seq_item_c")
   end     


   vif.tx_valid <= 1'b1;
  vif.tx_data <= item.payload;
endtask
                              // multiple blank lines and trailing spaces above
task automatic send_pause_frame(int unsigned quanta);
endtask
```

---

## 2.6 Signal and Port Declaration Alignment

**Rule:** When declaring a block of related signals, ports, or class members together, align the types and names in columns so the block reads like a table, not a ragged list.

**Steps to Follow:**
1. Identify the widest type/name in the block first.
2. Pad shorter types/names with spaces so all identifiers start at the same column.
3. Re-align the whole block if a new, longer identifier is added later — don't leave it as the one ragged outlier.
4. Most editors support "align" plugins/macros; use one rather than aligning by hand every time.

**Correct Example:**
```systemverilog
interface mac_if (input logic clk);
  logic        reset_n;
  logic        tx_valid;
  logic [63:0] tx_data;
  logic        tx_ready;
  logic        rx_valid;
  logic [63:0] rx_data;
endinterface
```

**Incorrect Example:**
```systemverilog
interface mac_if (input logic clk);
  logic reset_n;
  logic tx_valid;
  logic [63:0] tx_data;
  logic tx_ready;
  logic rx_valid;
  logic [63:0] rx_data;
endinterface
```

---

## 2.7 Class Member Ordering

**Rule:** Within every class, declare members in a consistent order: (1) `uvm_component_utils`/`uvm_object_utils` macro, (2) member variables, (3) `new()` constructor, (4) standard UVM phase methods in phase order (`build_phase`, `connect_phase`, `run_phase`, ...), (5) other public methods, (6) `extern`-declared method prototypes if used (see Section 8).

**Steps to Follow:**
1. Always put the factory registration macro as the first line inside the class body.
2. Group all member variables together immediately after it — don't scatter variable declarations between methods.
3. Place `new()` next, followed by phases in their natural execution order.
4. Add any custom/helper methods after the phases, in the order they are logically used.
5. Keep this order identical across every class in the codebase so any engineer can jump to the right place instinctively.

**Correct Example:**
```systemverilog
class axi_driver_c extends uvm_driver #(axi_seq_item_c);
  `uvm_component_utils(axi_driver_c)

  virtual mac_if m_vif;
  int            m_frames_sent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // ...
  endfunction

  task run_phase(uvm_phase phase);
    // ...
  endtask

  extern task drive_frame(axi_seq_item_c item);
endclass
```

---

## 2.8 Quick Formatting Tips

- Always end every file with a single trailing newline (most editors do this automatically — confirm yours does).
- Never mix `assign`-style continuous assignments and procedural (`always`/`initial`) drives to the same signal.
- Use `` `timescale `` only at the top of the file it applies to, never mid-file.
- Prefer named port connections (`.clk(clk)`) over positional connections in module/interface instantiations — positional connections silently break if the port order ever changes.
- Use parentheses to make operator precedence explicit in non-trivial expressions, even when not strictly required — `(a & b) | c` reads faster than `a & b | c`.
- Keep one statement per line; never chain multiple statements with semicolons on a single line.

---

# 3. Commenting

## 3.1 When to Comment

**Rule:** Comment *why* something is done, not *what* the code already makes obvious. Mandatory comments are required for: non-obvious protocol/spec-driven logic, workarounds, timing-sensitive code, and any deviation from a straightforward implementation.

**Steps to Follow:**
1. Before writing a comment, ask: "would a competent engineer be confused without this?" If no, skip it.
2. For spec-driven logic, cite the clause/requirement (e.g., `// IEEE 802.3 96-bit IFG requirement`).
3. For workarounds, explain the reason and reference a bug/ticket ID if one exists.
4. Do not comment self-explanatory code line by line.

**Correct Example:**
```systemverilog
// IEEE 802.3 clause 4.2.3.2: minimum 96 bit-time IFG must be enforced
// even when back-to-back minimum-size frames are transmitted.
repeat (IFG_BIT_TIMES / 8) @(posedge clk);

// Workaround: DUT drops the first PAUSE frame after reset (see VIP-201).
// Re-send once if no pause effect is observed within 2 clock cycles.
if (!pause_took_effect) begin
  resend_pause_frame();
end
```

**Incorrect Example:**
```systemverilog
i = i + 1;                       // increment i
frame_valid = 1;                 // set frame_valid to 1
repeat (12) @(posedge clk);       // wait 12 cycles (why 12? no context given)
```

**More Good Examples (context that isn't obvious from the code alone):**
```systemverilog
// Reference model intentionally lags the DUT by one clock to match
// the DUT's registered output stage - do not remove this delay.
#1step;

// Constrained to avoid EtherType values that collide with the
// PAUSE EtherType (0x8808), which would misclassify the frame.
constraint c_valid_ethertype { ethertype != `MAC_PAUSE_ETHERTYPE; }
```

---

## 3.2 Comment Style (Block vs Inline)

**Rule:** Use `//` for single-line and short inline comments. Use `/* ... */` block comments only for multi-line explanations placed above a block of code — never mid-line.

**Steps to Follow:**
1. Use `//` for anything that fits on one line, placed either above the line or briefly trailing it.
2. Use `/* */` for a paragraph-length explanation preceding a complex function or algorithm.
3. Never nest `/* */` comments.
4. Keep inline trailing comments short (under ~10 words); move longer explanations above the line.

**Correct Example:**
```systemverilog
/*
 * Pause-time reload logic: per IEEE 802.3 Annex 31B, a newly received
 * PAUSE frame always reloads the timer with the new quanta value,
 * even if a pause is already in progress.
 */
function void reload_pause_timer(int unsigned new_quanta);
  m_pause_timer = new_quanta; // overwrite, do not accumulate
endfunction

// Single-line rationale directly above the line it explains
// Skip padding check for control frames - padding only applies to data frames.
if (!frame.is_control_frame) begin
  check_padding(frame);
end
```

**Incorrect Example:**
```systemverilog
function void reload_pause_timer(int unsigned new_quanta);
  m_pause_timer /* overwrite */ = new_quanta; // block comment used mid-line
endfunction

/* this
   function
   checks
   padding */             // multi-line explanation crammed into a mid-code block
   // comment split awkwardly instead of one clear block above the code
if (!frame.is_control_frame) begin
  check_padding(frame);
end
```

---

## 3.3 Class/Method Header Documentation

**Rule:** Every class and every public task/function shall have a header comment block describing its purpose, arguments, and return value, using a consistent Doxygen-style tag format.

**Steps to Follow:**
1. Place a header block immediately above the `class` or `task/function` declaration.
2. Include `@brief` (one-line summary), `@param` for each argument, and `@return` if applicable.
3. Keep the description updated whenever the signature changes — stale docs are worse than none.
4. Class-level headers should also note which UVM phase(s) the class is most active in, if relevant.

**Correct Example:**
```systemverilog
/**
 * @brief Drives TX-side MAC frames onto the DUT interface.
 *        Active primarily during the run_phase.
 */
class axi_driver extends uvm_driver #(axi_seq_item);

  /**
   * @brief Waits until the DUT reset has been deasserted.
   * @param timeout_cycles Maximum cycles to wait before timing out.
   * @return 1 if reset deasserted within timeout, 0 otherwise.
   */
  function bit wait_for_reset(int timeout_cycles);
    // ...
  endfunction
endclass
```

---

## 3.4 TODO / FIXME Comments

**Rule:** Use `// TODO:` for planned-but-not-yet-implemented work and `// FIXME:` for known-broken code that compiles/runs but is incorrect. Every TODO/FIXME must include an owner and, if one exists, a ticket reference.

**Steps to Follow:**
1. Format as `// TODO (owner, TICKET-ID): description`.
2. Never merge a `FIXME` into the main regression-passing branch without an accompanying open ticket.
3. Periodically grep the codebase for `TODO`/`FIXME` during milestone reviews to ensure none are forgotten.
4. Do not use vague TODOs like `// TODO: fix this` without saying what "this" is.

**Correct Example:**
```systemverilog
// TODO (haritha, VIP-142): add jumbo frame support once RTL enables it.
// TODO (sudha, VIP-165): parameterize VLAN PCP randomization range once
// the spec team confirms whether all 8 priority levels are in scope.
// FIXME (praveen, VIP-158): pause timer reload does not yet handle
// back-to-back zero-quanta frames correctly.
// FIXME (haritha, VIP-171): scoreboard leaks a queue entry when a frame
// is discarded mid-comparison - needs a cleanup path in the compare task.
```

**Incorrect Example:**
```systemverilog
// TODO: fix this                     // no owner, no ticket, no detail
// FIXME later                        // vague, unattributed, easy to lose track of
// TODO: cleanup                      // cleanup what, and by whom?
```

**Additional Guidance:**
- A `TODO` describes *planned* work that hasn't been started — the surrounding code should still function correctly without it.
- A `FIXME` marks code that is *currently wrong* but was merged anyway (e.g., to unblock a dependency) — it must always be paired with an open ticket, since it represents a known-bad state.
- During sprint/milestone reviews, run `grep -rn "TODO\|FIXME" <tb_dir>` and reconcile each hit against the open ticket list; remove stale TODOs that were already completed.

---

# 4. Error Handling

## 4.1 Consistent Reporting via `uvm_*` Macros

**Rule:** All errors, warnings, and informational messages shall be reported using `` `uvm_error ``, `` `uvm_warning ``, `` `uvm_fatal ``, and `` `uvm_info `` — never `$display`, `$write`, or raw `$error`. Every message must use a short, consistent, UPPERCASE ID string as its first argument.

**Steps to Follow:**
1. Choose the correct severity: `uvm_fatal` for unrecoverable environment errors, `uvm_error` for checker/protocol failures that should fail the test but allow it to continue, `uvm_warning` for suspicious-but-non-fatal conditions, `uvm_info` for trace/debug visibility.
2. Use a consistent, greppable ID per message category (e.g., `"CRC_ERR"`, `"RUNT_FRAME"`) — reuse the same ID everywhere that error type is reported.
3. Include enough context in the message to debug without re-running (frame ID, expected vs. actual values).
4. Never use `$display` for anything that should show up in regression triage — it bypasses UVM's verbosity/filtering/report-count mechanisms.

**Correct Example:**
```systemverilog
if (actual_crc !== expected_crc) begin
  `uvm_error("CRC_ERR",
             $sformatf("CRC mismatch: expected=0x%0h actual=0x%0h frame_id=%0d",
                       expected_crc, actual_crc, frame.id))
end
```

**Incorrect Example:**
```systemverilog
if (actual_crc !== expected_crc) begin
  $display("crc bad");   // not filterable, not counted by UVM, no context
end
```

---

## 4.2 Handling Specific Error/Failure Types

**Rule:** Distinguish between expected protocol errors (which the DUT should detect and the testbench should merely check for) and unexpected testbench/environment errors (which indicate a bug in the verification environment itself). Never let the two use the same reporting path.

**Steps to Follow:**
1. For DUT-expected error scenarios (e.g., injected CRC error, runt frame), use the scoreboard/checker to confirm the DUT's response — report a `uvm_error` only if the DUT fails to detect it, not for the injected condition itself.
2. For environment-internal failures (e.g., a `null` handle, an out-of-range array access, a config object not set), use `uvm_fatal` — these should stop the test immediately since further execution is meaningless.
3. Wrap external/foreign calls (DPI, file I/O) in explicit status checks; never assume success.
4. Always check `get_config_object`/`get_config_int` etc. return values before dereferencing.

**Correct Example:**
```systemverilog
if (!uvm_config_db#(mac_env_cfg)::get(this, "", "cfg", m_cfg)) begin
  `uvm_fatal("NO_CFG", "mac_env_cfg not found in config_db - check top-level test")
end

// Expected DUT-detected error scenario - only flag if DUT misses it
if (injected_crc_error && !dut_reported_crc_error) begin
  `uvm_error("MISSED_CRC_DETECT", "DUT failed to flag an injected CRC error")
end
```

---

## 4.3 Logging and Verbosity Best Practices

**Rule:** Use UVM verbosity levels deliberately (`UVM_NONE`, `UVM_LOW`, `UVM_MEDIUM`, `UVM_HIGH`, `UVM_FULL`) so that default regression logs stay readable, while detailed debug traces remain available on demand.

**Steps to Follow:**
1. Reserve `UVM_LOW` for messages that should appear in every regression run (test start/end, major checkpoints, errors).
2. Use `UVM_MEDIUM` for per-transaction summaries useful during triage.
3. Use `UVM_HIGH`/`UVM_FULL` for detailed field-by-field dumps only needed during active debugging.
4. Never hardcode verbosity-gated behavior with `if` statements — let `uvm_info`'s built-in verbosity filtering do the job.
5. Set the default verbosity centrally in the test/base test, not scattered per component.

**Correct Example:**
```systemverilog
`uvm_info(get_type_name(), "Test started", UVM_LOW)
`uvm_info(get_type_name(), $sformatf("Sent frame id=%0d", frame.id), UVM_MEDIUM)
`uvm_info(get_type_name(), frame.sprint(), UVM_HIGH)
```

---

# 5. Code Readability and Simplicity

## 5.1 Avoiding Overly Complex Logic

**Rule:** Avoid deeply nested conditionals (more than 3 levels) and complex boolean expressions with more than 3 conditions combined inline. Extract complex conditions into a well-named function.

**Steps to Follow:**
1. Count nesting depth as you write; if you exceed 3 levels of `if/for/begin`, refactor.
2. Replace multi-term boolean conditions with a named function that returns a single bit.
3. Prefer early `return`/`continue` to flatten nested `if/else` chains.
4. Use `case` statements instead of long `if/else if` chains when checking one variable against multiple values.

**Correct Example:**
```systemverilog
function bit is_valid_unicast_frame(eth_frame_t frame);
  return (!frame.dest_addr[40] &&                 // unicast bit clear
          frame.dest_addr == m_cfg.local_addr &&
          frame.length inside {[MAC_MIN_FRAME_SIZE:MAC_MAX_FRAME_SIZE]});
endfunction

if (is_valid_unicast_frame(frame)) begin
  accept_frame(frame);
end
```

**Incorrect Example:**
```systemverilog
if (!frame.dest_addr[40]) begin
  if (frame.dest_addr == m_cfg.local_addr) begin
    if (frame.length >= MAC_MIN_FRAME_SIZE) begin
      if (frame.length <= MAC_MAX_FRAME_SIZE) begin
        accept_frame(frame); // 4 levels deep, hard to scan
      end
    end
  end
end
```

---

## 5.2 Keeping Tasks/Functions Short and Focused

**Rule:** Each task/function should do exactly one thing and fit on one screen (roughly 40–50 lines). If a task grows beyond that, split it into smaller, named helper tasks/functions.

**Steps to Follow:**
1. Before writing a task, state its single responsibility in one sentence; if you need "and" to describe it, split it.
2. Extract repeated multi-line blocks into their own helper method, even if used only twice.
3. Keep `run_phase` implementations as a short orchestration of calls to smaller named tasks (`send_reset_sequence()`, `send_traffic()`, `wait_for_drain()`), not one long monolithic body.
4. Review function length as part of code review — flag anything over ~50 lines for refactoring.

**Correct Example:**
```systemverilog
task automatic run_phase(uvm_phase phase);
  phase.raise_objection(this);
  apply_reset();
  send_directed_tests();
  send_random_traffic();
  wait_for_scoreboard_drain();
  phase.drop_objection(this);
endtask
```

**Incorrect Example:**
```systemverilog
task automatic run_phase(uvm_phase phase);
  phase.raise_objection(this);
  // 150 lines of reset logic, directed tests, random traffic,
  // and drain-checking all inlined in one giant task
  // ...
  phase.drop_objection(this);
endtask
```

---

## 5.3 Meaningful Names Everywhere

**Rule:** Every identifier — variable, function, class, parameter — must convey its purpose without needing to read its implementation. Single-letter names are only acceptable for trivial loop counters (`i`, `j`) in short loops.

**Steps to Follow:**
1. Ask "what does this represent?" and use that as the name, not "what type is it?"
2. Avoid generic names like `data`, `temp`, `val`, `flag` — qualify them (`frame_data`, `temp_crc`, `pause_quanta_val`, `is_reset_active`).
3. Boolean variables should read naturally in an `if` (`is_valid`, `has_error`, `should_retry`).
4. Rename as understanding evolves — an outdated name is actively misleading, not neutral.

**Correct Example:**
```systemverilog
bit is_broadcast_frame;
int unsigned pause_quanta_remaining;

foreach (m_pending_frames[i]) begin
  check_frame(m_pending_frames[i]);
end
```

**Incorrect Example:**
```systemverilog
bit flag1;
int cnt2;

foreach (arr[x]) begin
  chk(arr[x]);
end
```

---

## 5.4 DRY Principle in UVM

**Rule:** Do not duplicate logic across sequences, drivers, or checkers. Factor shared behavior into base classes, reusable sequence libraries, parameterized components, or utility functions.

**Steps to Follow:**
1. Before copy-pasting a block of testbench code, check whether it belongs in a common base class or utility package instead.
2. Create a common base sequence (`mac_base_seq`) for shared setup (randomization constraints, config access) and derive specific sequences from it.
3. Centralize protocol constants (frame size limits, EtherType values) in one shared package, never redefined per file.
4. Use `` `uvm_object_utils ``/`` `uvm_component_utils `` macros and factory overrides instead of copy-pasted variants of the same component for minor behavior differences.

**Correct Example:**
```systemverilog
class mac_base_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(mac_base_seq)
  mac_env_cfg m_cfg;

  task pre_body();
    if (!uvm_config_db#(mac_env_cfg)::get(null, get_full_name(), "cfg", m_cfg))
      `uvm_fatal("NO_CFG", "mac_env_cfg not found")
  endtask
endclass

class mac_jumbo_frame_seq extends mac_base_seq;
  `uvm_object_utils(mac_jumbo_frame_seq)
  // only jumbo-specific randomization added here - setup reused from base
endclass
```

**Incorrect Example:**
```systemverilog
class mac_jumbo_frame_seq extends uvm_sequence #(axi_seq_item);
  // entire pre_body(), config lookup, and constraints copy-pasted
  // from three other sequences with only minor edits
endclass
```

---

# 6. SystemVerilog Assertions (SVA) Style Guide

## 6.1 Assertion & Property Naming

**Rule:** Named properties end in `_p`, the assertions that use them end in `_a`, and both are prefixed with the block/signal they check.

**Steps to Follow:**
1. Write the reusable behavior as a `property ... _p`.
2. Instantiate it as `assert property (...) ... _a`.
3. Prefix both with the block name so failures are traceable to their source at a glance.

**Correct Example:**
```systemverilog
property axi_ifg_p;
  @(posedge clk) disable iff (!reset_n)
  $fell(tx_valid) |-> ##[96:$] 1;
endproperty

axi_ifg_a: assert property (axi_ifg_p)
  else `uvm_error("IFG_VIOLATION", "Inter-frame gap below 96 bit-times")
```

## 6.2 Immediate vs. Concurrent Assertions

**Rule:** Use immediate assertions (`assert (...)`) only for simple, same-cycle combinational checks inside procedural code. Use concurrent assertions (`assert property (...)`) for anything involving clocked timing or sequences.

**Steps to Follow:**
1. If the check spans more than one clock cycle or needs `##` delays, it must be a concurrent assertion.
2. If the check is a same-cycle sanity check inside a `function`/`task` (e.g., a null-handle check), an immediate assertion is sufficient.

**Correct Example:**
```systemverilog
// Immediate - same-cycle sanity check
assert (m_cfg != null) else `uvm_fatal("NULL_CFG", "m_cfg not set")

// Concurrent - spans multiple cycles
assert property (@(posedge clk) tx_valid |-> ##1 tx_data != 'x)
  else `uvm_error("TX_DATA_X", "tx_data went unknown one cycle after tx_valid")
```

## 6.3 Assertion Severity and Messages

**Rule:** Every assertion's `else` clause must report through `` `uvm_error `` (or `` `uvm_warning `` for advisory-only checks) with a specific, greppable ID — never a bare `$error`.

**Correct Example:**
```systemverilog
mac_crc_valid_a: assert property (@(posedge clk) eof |-> crc_ok)
  else `uvm_error("CRC_ASSERT_FAIL", $sformatf("CRC check failed, frame_id=%0d", frame_id))
```

## 6.4 Assertion Placement and Reuse

**Rule:** Protocol-level assertions live in the interface (or a bound assertion module), not scattered inside driver/monitor class code, so they apply regardless of which testbench component is active.

**Steps to Follow:**
1. Place reusable protocol checks in `mac_if` or a dedicated `mac_assertions_m` module bound to the DUT.
2. Do not duplicate a check both as an assertion and as a scoreboard check unless they intentionally verify different things (e.g., protocol timing vs. data correctness).

---

# 7. Interface & Clocking Block Conventions

## 7.1 Interface Naming and Structure

**Rule:** Interfaces are named `<block>_if` and contain only signals, modports, and clocking blocks — no procedural driving logic belongs in the interface itself.

**Correct Example:**
```systemverilog
interface mac_if (input logic clk);
  logic        reset_n;
  logic        tx_valid;
  logic [63:0] tx_data;
  logic        rx_valid;
  logic [63:0] rx_data;
endinterface
```

## 7.2 Modport Usage

**Rule:** Every interface used by both a driver and a monitor shall define at least a `driver` modport (directional, for driving) and a `monitor` modport (all-input, for observing only).

**Steps to Follow:**
1. Define `modport driver` with outputs for signals the driver drives and inputs for anything it must sample.
2. Define `modport monitor` with every signal as `input` — a monitor must never be able to drive.
3. Connect each class to the interface through its modport, not the raw interface, so accidental driving from a monitor is a compile error, not a runtime bug.

**Correct Example:**
```systemverilog
interface mac_if (input logic clk);
  logic        reset_n;
  logic        tx_valid;
  logic [63:0] tx_data;

  modport driver  (input clk, reset_n, output tx_valid, tx_data);
  modport monitor (input clk, reset_n, tx_valid, tx_data);
endinterface
```

```systemverilog
class axi_monitor_c extends uvm_monitor;
  virtual mac_if.monitor m_vif;   // monitor modport - cannot accidentally drive
endclass
```

## 7.3 Clocking Block Naming and Skew

**Rule:** Clocking blocks are named `cb_<role>` (e.g., `cb_driver`, `cb_monitor`) and always specify explicit input/output skew — never rely on default skew.

**Steps to Follow:**
1. Use `#1step` input skew for monitor sampling (to catch the value as of the end of the previous cycle).
2. Use a small, explicit output skew (e.g., `#1`) for driver clocking blocks.
3. Access signals only through the clocking block from testbench code, never the raw interface signal, to avoid race conditions with the DUT.

**Correct Example:**
```systemverilog
interface mac_if (input logic clk);
  clocking cb_driver @(posedge clk);
    output #1 tx_valid, tx_data;
  endclocking

  clocking cb_monitor @(posedge clk);
    input #1step tx_valid, tx_data;
  endclocking
endinterface
```

## 7.4 Virtual Interface Handling in Classes

**Rule:** Every class member holding a virtual interface is named `m_vif` (per the `m_` convention in 1.2) and is always retrieved via `uvm_config_db` in `build_phase` — never hardwired or passed through a constructor.

**Correct Example:**
```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual mac_if)::get(this, "", "vif", m_vif))
    `uvm_fatal("NO_VIF", "virtual mac_if not set in config_db")
endfunction
```

---

# 8. Method Declaration Style (`extern`)

## 8.1 Declaring Methods with `extern` for Readability

**Rule:** For any class with more than roughly 4–5 methods, declare method **prototypes** inside the class body using `extern`, and implement the method **bodies** outside the class using the `class_name_c::method_name` scope operator. This lets any engineer scan the class declaration alone and immediately see every method it offers, without scrolling through full implementations.

**Steps to Follow:**
1. Inside the class body, list each method as a one-line `extern` prototype, keeping the class member ordering from Section 2.7 (utils macro → variables → `new()` → phases → other methods).
2. Below the class (in the same file), implement each method as `return_type class_name_c::method_name(args);` ... `endfunction`/`endtask`.
3. Keep the `extern` prototypes and their out-of-class implementations in the **same order** so the file reads top-to-bottom consistently.
4. Do not mix styles within one class — either every non-trivial method is `extern`-declared, or none are; a half-and-half class is harder to scan, not easier.
5. Very short, one-line accessor methods (e.g., simple getters) may still be implemented inline in the class body even in an otherwise `extern`-style class, since pulling them out adds no readability benefit.

**Correct Example:**
```systemverilog
// axi_driver_c.sv
class axi_driver_c extends uvm_driver #(axi_seq_item_c);
  `uvm_component_utils(axi_driver_c)

  virtual mac_if.driver m_vif;
  int                   m_frames_sent;

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern task          run_phase(uvm_phase phase);
  extern task          drive_frame(axi_seq_item_c item);
  extern task          wait_for_reset_deassertion();
endclass


function axi_driver_c::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction


function void axi_driver_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual mac_if.driver)::get(this, "", "vif", m_vif))
    `uvm_fatal("NO_VIF", "virtual mac_if not set in config_db")
endfunction


task axi_driver_c::run_phase(uvm_phase phase);
  wait_for_reset_deassertion();
  forever begin
    axi_seq_item_c item;
    seq_item_port.get_next_item(item);
    drive_frame(item);
    seq_item_port.item_done();
  end
endtask


task axi_driver_c::drive_frame(axi_seq_item_c item);
  m_vif.cb_driver.tx_valid <= 1'b1;
  m_vif.cb_driver.tx_data  <= item.payload;
  @(m_vif.cb_driver);
  m_vif.cb_driver.tx_valid <= 1'b0;
  m_frames_sent++;
endtask


task axi_driver_c::wait_for_reset_deassertion();
  @(posedge m_vif.reset_n);
endtask
```

**Why this helps a new engineer:** opening `axi_driver_c.sv` and reading just the first ~10 lines (the class body) tells you *everything this driver can do* — `build_phase`, `run_phase`, `drive_frame`, `wait_for_reset_deassertion` — without needing to scroll past 80 lines of implementation to find out what methods exist.

**Incorrect Example (methods buried inline, hard to scan):**
```systemverilog
class axi_driver_c extends uvm_driver #(axi_seq_item_c);
  `uvm_component_utils(axi_driver_c)
  virtual mac_if.driver m_vif;
  int m_frames_sent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mac_if.driver)::get(this, "", "vif", m_vif))
      `uvm_fatal("NO_VIF", "virtual mac_if not set in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // 40 more lines here before you even see what drive_frame does...
  endtask

  task drive_frame(axi_seq_item_c item);
    // ...
  endtask
  // by the time you reach here, you've lost track of the class's full API
endclass
```

---

## Summary Checklist for Code Review

- [ ] Signals/variables in `snake_case`; class members prefixed `m_`
- [ ] Methods named `verb_noun` in `snake_case`
- [ ] Classes suffixed by UVM role (`_driver`, `_monitor`, `_env`, etc.), end in `_c`, and file name matches class name
- [ ] Constants in `SCREAMING_SNAKE_CASE`, no magic numbers
- [ ] 2-space indentation, no tabs; explicit `begin/end`; ≤100 char lines
- [ ] No stray blank lines/trailing whitespace; related signal blocks column-aligned
- [ ] Class members ordered consistently: utils macro → variables → `new()` → phases → other methods
- [ ] Comments explain *why*, not *what*; class/method headers present
- [ ] TODO/FIXME entries include an owner and ticket ID
- [ ] All reporting via `` `uvm_info/warning/error/fatal `` with consistent IDs
- [ ] Verbosity levels used deliberately
- [ ] No nesting deeper than 3 levels; functions ≤ ~50 lines
- [ ] No duplicated logic — shared behavior factored into base classes/utilities
- [ ] SVA properties/assertions named `_p`/`_a`; concurrent vs. immediate used correctly
- [ ] Interfaces expose `driver`/`monitor` modports; clocking blocks used for all TB-side signal access
- [ ] Classes with several methods use `extern` prototypes for a scannable class-body API
