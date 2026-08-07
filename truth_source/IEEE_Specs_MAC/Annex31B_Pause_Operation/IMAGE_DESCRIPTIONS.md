# Annex 31B Page Image Descriptions

Source pages:
- IEEE Std 802.3-2008 section2, Annex 31B pages 741-752
- IEEE Std 802.3ba-2010 amendment pages 381-384

This file summarizes the rendered page images for the PAUSE annex and its amendment so the state machines and PICS tables can be reviewed without reopening the images.

## Base annex image summary

- `section2_p0741.png`: intro text for 31B.1 PAUSE description and 31B.2 parameter semantics. It defines the reserved multicast destination address `01-80-C2-00-00-01` and the `pause_time` request operand.

- `section2_p0745.png`: 31B.3.4 receive-state input definitions. It lists the constants `pause_quantum`, `pause_command`, `reserved_multicast_address`, and `phys_Address`, plus the receive-side variables and timer.

- `section2_p0746.png`: Figure 31B-2, PAUSE Operation Receive state diagram. The diagram has WAIT FOR TRANSMISSION COMPLETION, PAUSE FUNCTION, and END PAUSE states. It gates PAUSE processing on the destination address and starts the pause timer from `n_quanta_rx * pause_quantum`.

- `section2_p0749.png`: 31B.4.1 introduction and 31B.4.2 identification tables for the PICS proforma.

- `section2_p0751.png`: Table 31B-4, PAUSE command MAC timing considerations. The table lists TIM1 through TIM5 in the base annex, including the 100 Mb/s, 1000 Mb/s, and 10 Gb/s timing limits.

- `section2_p0752.png`: continuation of the base PICS material and trailing page content.

## Amendment image summary

- `802.3ba_p0381.png`: amended 31B.3.7 timing text. It adds 40 Gb/s and 100 Gb/s transmit timing limits and refines the 10 Gb/s timing cases.

- `802.3ba_p0382.png`: amended Table 31B-1, Major capabilities/options. The table expands the MII capability entries so the 10 Gb/s, 40 Gb/s, and 100 Gb/s cases are explicit.

- `802.3ba_p0383.png`: amended Table 31B-4 / PAUSE command MAC timing considerations. It expands the timing table with the 10GBASE-T split and the 40/100 Gb/s timing rows.

- `802.3ba_p0384.png`: trailing amendment page / continuation space.

## Key figures

- Figure 31B-1, PAUSE Operation Transmit state diagram: a transmit-side state machine with pause-aware gating, send-control-frame behavior, and data-frame forwarding behavior.

- Figure 31B-2, PAUSE Operation Receive state diagram: a receive-side state machine that validates destination address, waits for any in-progress transmission to complete, loads the pause timer, and exits cleanly.

- Figure 31B-3, PAUSE Operation Indication state diagram: a client-visible state machine that alternates between `paused` and `not_paused` and drives `MA_CONTROL.indication`.

## Key tables

- Table 31B-1: PICS major capabilities/options.
- Table 31B-2: PAUSE command requirements.
- Table 31B-3: PAUSE command state diagram requirements.
- Table 31B-4: PAUSE command MAC timing considerations.

## Practical RTL relevance

This annex is directly useful for implementing PAUSE flow control in MAC RTL. The timing limits and the state-machine behavior are the most relevant parts for synthesis-friendly interpretation.
