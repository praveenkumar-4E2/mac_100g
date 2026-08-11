# 100G MAC — Feature Test Ownership by RTL Block

> Source: IEEE 802.3-2008 + IEEE 802.3ba-2010

---

## 1. TX Path Owner

| # | Feature | Clause | RTL Modules | Owner | Status |
|---|---------|--------|-------------|-------|--------|
| 1 | Preamble + SFD generation | 3.2.1, 3.2.2 | frame_formatter | TBD | Pending |
| 2 | Frame encapsulation (DA+SA+Type+Data) | Clause 3 | tx_frame_builder, tx_client_capture | TBD | Pending |
| 3 | CRC32 FCS insertion | 3.2.9 | tx_crc_insert | TBD | Pending |
| 4 | Min frame padding (64B enforcement) | 4.4.2 | tx_pad_calc | TBD | Pending |
| 5 | Inter-Packet Gap enforcement | 4.4.2 | tx_ipg_timer | TBD | Pending |
| 6 | TX pipeline timing (100G) | 802.3ba | tx_pipeline | TBD | Pending |
| 7 | AXI4-Stream TX adapter | — | tx_axi4_stream_adapter, tx_axi_admission | TBD | Pending |
| 8 | TX arbiter (data vs control frames) | — | tx_arbiter | TBD | Pending |

---

## 2. RX Path Owner

| # | Feature | Clause | RTL Modules | Owner | Status |
|---|---------|--------|-------------|-------|--------|
| 1 | Preamble + SFD detection | 3.2.1, 3.2.2 | rx_preamble_detect | TBD | Pending |
| 2 | MAC header extraction (DA/SA/Type) | 3.2.4–3.2.6 | rx_header_extract | TBD | Pending |
| 3 | CRC32 FCS verification | 3.2.9 | rx_crc_check | TBD | Pending |
| 4 | Frame length validation | 4.4.2 | rx_length_check | TBD | Pending |
| 5 | Invalid frame detection (CRC/align/length) | 3.4 | rx_crc_check, rx_length_check | TBD | Pending |
| 6 | RX pipeline timing (100G) | 802.3ba | rx_pipeline | TBD | Pending |
| 7 | AXI4-Stream RX adapter | — | rx_axi4_stream_adapter | TBD | Pending |
| 8 | Frame emission to client | — | rx_frame_emit | TBD | Pending |

---

## 3. MAC Control + PAUSE Owner

| # | Feature | Clause | RTL Modules | Owner | Status |
|---|---------|--------|-------------|-------|--------|
| 1 | MAC Control frame detection (Type 88-08) | 31.4.1.3 | control_classifier | TBD | Pending |
| 2 | Opcode decode and dispatch | 31.5.3.4 | mac_control_top | TBD | Pending |
| 3 | MAC Control frame generation | 31.4.1 | control_frame_builder | TBD | Pending |
| 4 | PAUSE RX (decode, timer start) | Annex 31B | pause_rx | TBD | Pending |
| 5 | PAUSE TX (generate PAUSE frame) | 31B.3.2 | pause_tx | TBD | Pending |
| 6 | PAUSE timer engine (512 BT quanta) | 31B.2 | pause_timer_engine | TBD | Pending |
| 7 | PAUSE admission gate (block TX during PAUSE) | 31B.3.7 | pause_admission_gate | TBD | Pending |
| 8 | PAUSE timing compliance (394×512 BT at 100G) | 802.3ba | pause_timer_engine | TBD | Pending |

---

## 4. Registers + Management Owner

| # | Feature | Clause | RTL Modules | Owner | Status |
|---|---------|--------|-------------|-------|--------|
| 1 | APB register read/write | — | apb_regs, reg_file, apb_decode | TBD | Pending |
| 2 | Register interface bridging | — | apb_regs_if, apb_cfg_bridge | TBD | Pending |
| 3 | Interrupt controller | — | apb_interrupt | TBD | Pending |
| 4 | Statistics counters (TX/RX/error) | Clause 30 | stats_counters, stats_aggregator, mac_stats | TBD | Pending |
| 5 | Stats CDC bridge (MAC→APB domain) | — | stats_cdc_bridge | TBD | Pending |
| 6 | MDIO management registers | Clause 45 | apb_regs | TBD | Pending |

---

## 5. Integration + System Owner

| # | Feature | Clause | RTL Modules | Owner | Status |
|---|---------|--------|-------------|-------|--------|
| 1 | Full duplex operation | 4.1.1, Annex 4A | mac_top | TBD | Pending |
| 2 | TX/RX path independence | 4A.1.2 | mac_tx_path, mac_rx_path | TBD | Pending |
| 3 | MAC Control sublayer integration | Clause 31 | mac_top | TBD | Pending |
| 4 | CDC across clock domains | — | cdc_2ff, cdc_dpram, cdc_handshake, cdc_pulse | TBD | Pending |
| 5 | Address filter (unicast/multicast/broadcast) | 3.2.3 | address_filter | TBD | Pending |
| 6 | Event collector (status aggregation) | — | mac_event_collector | TBD | Pending |
| 7 | Reset behavior | — | mac_reset_if | TBD | Pending |
| 8 | 100G PHY type support (CR10/SR10/LR4/ER4) | 802.3ba | mac_top | TBD | Pending |

---

## Ownership Summary

| Owner | Domain | Features | Count |
|-------|--------|----------|-------|
| TBD | TX Path | 1.1–1.8 | 8 |
| TBD | RX Path | 2.1–2.8 | 8 |
| TBD | MAC Control + PAUSE | 3.1–3.8 | 8 |
| TBD | Registers + Management | 4.1–4.6 | 6 |
| TBD | Integration + System | 5.1–5.8 | 8 |

**Total: 38 feature tests across 5 owners**

---

## Regression Grouping

| Group | Features | Environment |
|-------|----------|-------------|
| TX Core | 1.1–1.6 | TX path only |
| RX Core | 2.1–2.6 | RX path only |
| MAC Control | 3.1–3.3 | Control sublayer |
| PAUSE | 3.4–3.8 | Flow control |
| Registers | 4.1–4.6 | APB/Management |
| System | 5.1–5.8 | Full integration |
