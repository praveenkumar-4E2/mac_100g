# P0: Repair TX AXI SOP and Admission

## Problem

`src/hdl_top/tx/tx_axi4_stream_adapter.sv` drives `mac_sop` from `mac_sop_r`, while `mac_sop_r` is set in `always_ff` only after `s_tvalid && mac_ready`. The first accepted AXI beat therefore is not marked SOP. A single-beat frame has no SOP; a multi-beat frame can mark the second beat as SOP.

`src/hvl_top/tb/mac_tb_top.sv` generates `tx_start` sequentially from `axi_tx_if.tvalid`. The scheduler admission signal is consequently not a well-defined request handshake independent of stream-beat acceptance.

## Proposal

1. Make adapter SOP combinational from the pre-transfer frame state.
2. Update `frame_active` only on AXI handshake.
3. Define a single transaction admission contract: either buffer the complete AXI frame until the scheduler accepts it, or expose an explicit request-ready channel before the first beat. Do not derive a control request after accepting the first data beat.
4. Remove `mac_tb_top` procedural `tx_start` synthesis from the functional stimulus contract once the RTL exposes/owns the correct admission boundary.

## Candidate Adapter Change

```systemverilog
assign mac_sop = s_tvalid && !frame_active;

always_ff @(posedge clk) begin
  if (rst)
    frame_active <= 1'b0;
  else if (s_tvalid && s_tready)
    frame_active <= !s_tlast;
end
```

The exact final implementation must preserve SOP while a first beat is stalled; if `s_tvalid && !s_tready`, the presented SOP must remain asserted and stable.

## Assertions

Add assertions for first-beat SOP, no SOP inside a frame, no EOP before SOP, and stable `tdata/tkeep/tlast/tuser` while stalled.

## Acceptance Criteria

- One-beat and multi-beat AXI frames both show SOP on the first accepted internal beat.
- A random `tready` stall before first-beat acceptance keeps SOP and payload stable.
- TX wire monitor observes exactly one correctly framed output per admitted AXI request.
- No testbench `#` delay is used to infer TX acceptance.
