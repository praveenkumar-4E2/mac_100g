# P0: Define Monitor Transactions and Status Events

## Problem

The existing AXI and RS monitors can reconstruct basic frames, but their objects lack transaction time, source/direction, configuration context, drop reason, and RX status. `axi_item_c` also mixes request controls with observed results. `rs_monitor_c` does not clear partial state on reset and its protocol checker rereads raw VIF signals after sampling `mon_cb`.

## Proposal

Keep `axi_item_c` as a TX request item and `frame_xtn_c` as a wire-frame stimulus item. Add a monitor-only normalized type, for example `mac_frame_obs_c`, with:

```systemverilog
typedef enum { MAC_AXI_TX, MAC_RS_RX, MAC_RS_TX, MAC_AXI_RX } mac_boundary_e;
typedef enum { MAC_ACCEPTED, MAC_DROPPED, MAC_ABORTED_RESET, MAC_MALFORMED } mac_outcome_e;
mac_boundary_e boundary;
mac_outcome_e  outcome;
longint unsigned first_cycle, last_cycle;
int unsigned stream_id, byte_count;
byte unsigned bytes[$];
bit [47:0] dst_addr, src_addr;
bit [15:0] length_type;
bit fcs_present, crc_error, length_error, alignment_error, filter_hit;
bit [31:0] received_fcs;
```

Add a separate `mac_rx_status_obs_c` or status analysis port for frame-valid/drop and error pulses. Snapshot relevant configuration per observed frame or pass a configuration-version number.

## Required Monitor Repairs

1. In `rs_monitor_c`, on reset delete `frame_q`, clear `in_frame`, beat/IPG counters and latched final fields.
2. Store sampled `mon_cb.keep`, `error`, `eop`, and `eop_pos` locally; make all checks use those saved values, never raw VIF reads.
3. Add AXI checks for nonzero/contiguous keep, missing/early `tlast`, consistent sideband policy, incomplete-frame timeout, and reset abort.
4. Publish a new object for every frame/event and never modify it after `analysis_port.write`.

## Acceptance Criteria

- A reset between first and final beats produces no hybrid transaction.
- Monitored timing/status distinguishes accepted, dropped, malformed, and reset-aborted input.
- A deliberate malformed keep/SOP/EOP waveform causes a monitor error/event rather than a silently normalized frame.
- Both scoreboard directions receive sufficient data to compare bytes and outcome.
