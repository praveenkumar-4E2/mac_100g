# Interface Guide

## Handshake rule

A stream beat transfers on a rising clock edge only when `valid` and `ready`
are both `1`. While `valid=1` and `ready=0`, the source must hold every field
stable. Each signal has exactly one owner.

## AXI4-Stream

| Field | Meaning |
|---|---|
| `tdata[511:0]` | 64 byte lanes; first byte is `tdata[7:0]`. |
| `tkeep[63:0]` | Valid lanes; final beat uses contiguous lanes from 0. |
| `tvalid`, `tready` | Handshake. |
| `tlast` | Final beat. |
| `tuser` | Frame sideband status/control. |

TX client traffic is `ingress_tx_axis_*`; RX client traffic is
`egress_rx_axis_*`.

## Native MAC/RS stream

| Field | Meaning |
|---|---|
| `sop` | Start of packet; first beat only. |
| `eop` | End of packet; final beat only. |
| `frame_end_byte_index` | Valid byte count on final beat, not a zero-based index. |
| `error` | Error marker. |
| `fcs_present` | FCS is included at this boundary. |

A one-beat frame has both `sop=1` and `eop=1`. For a final 20-byte beat,
`frame_end_byte_index=20` and `keep[19:0]=1`.

## APB3

APB setup has `apb_psel=1`, `apb_penable=0`; access has both signals high.
The transfer finishes when `apb_pready=1`. Use `reg_map_pkg` constants instead
of raw addresses.
