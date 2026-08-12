# RTL Coding Guidelines

## Scope

Code under `src/rtl_verilog` is synthesizable Verilog. Do not use classes,
interfaces, packages, `logic`, `always_ff`, or `always_comb` in this tree.

## Style

- Use 2-space indentation and target 100 columns.
- Use `wire` for nets and `reg` for procedural state.
- Use `always @(*)` for combinational logic and `always @(posedge clk)` for
  sequential logic.
- Give every sequential register a deterministic reset value.
- Use sized constants such as `32'd0`, `16'h0004`, and `1'b0`.
- Keep one module per file where practical.

## Naming and comments

Boundary names use `ingress_*`, `egress_*`, and the interface type. Internal
names use `<block>_<function>_<signal>`, for example `tx_fsm_state`.

Comment non-obvious state transitions, CDC ownership, byte order, FCS policy,
or packet transformation. Do not comment syntax that the identifier already
explains.

## Before commit

Check directions, handshake/stall behavior, final-beat `keep` and
`frame_end_byte_index`, resets, and CDC. Run `make compile` and a relevant
test.
