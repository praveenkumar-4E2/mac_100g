# Annex 4A Page Image Descriptions

Source pages: IEEE Std 802.3-2008 section1, Annex 4A pages 647-671, plus the 802.3ba-2010 note update.

This file summarizes the figures and tables visible in the rendered page images so the annex markdown can be read without repeatedly opening the images.

## Key figures

- Figure 4A-1, "Relationship among MAC procedures": a process-architecture diagram showing the MAC client layer, MAC sublayer, and physical layer. On the transmit side it shows FrameTransmitter → TransmitFrame → TransmitDataEncap → ComputePad / CRC32 → TransmitLinkMgmt → StartTransmit → BitTransmitter → TransmitBit. On the receive side it shows FrameReceiver → ReceiveFrame → ReceiveDataDecap → CRC32 / LayerMgmt RecognizeAddress / RemovePad → ReceiveLinkMgmt → StartReceive → BitReceiver → ReceiveBit. The diagram separates framing, medium access management, and physical layer responsibilities.

- Figure 4A-2a, "Control flow summary": a transmit flowchart for TransmitFrame. It covers transmit enable checks, frame assembly, deferral handling, start of transmission, collision handling for half duplex, jam/backoff behavior, and exit states for transmit success or failure.

- Figure 4A-2b, "Control flow summary": a receive flowchart for ReceiveFrame. It covers receive enable checks, frame arrival, collision/too-small detection, address recognition, length checks, FCS validation, and receive success or error exits.

- Figure 4A-2c, "Control flow": a set of supporting flowcharts for BitTransmitter, BitReceiver, and Deference. It shows the continuous bit-level transmit/receive processes and the deferral logic tied to carrier sense.

- Figure 4A-3, "MAC client transmit interface state diagram": a client-facing state machine for transmission requests. It shows how client requests are accepted, deferred, or passed to the lower MAC procedures depending on transmit enable and deferral conditions.

- Figure 4A-4, "MAC client receive interface state diagram": a client-facing state machine for reception. It shows how received frames are accepted, filtered, and delivered upward, including the status handling for valid and invalid receptions.

## Key tables

- Table 4A-1, "Full duplex MAC functions, procedures and variables": the implementation inventory for the annex. It lists the procedures and shared state used by the full duplex MAC model.

- Table 4A-2, "Full duplex MAC parameter values": the normative parameter table. It sets interPacketGap to 96 bits, maxBasicFrameSize to 1518 octets, maxEnvelopeFrameSize to 2000 octets, and minFrameSize to 512 bits (64 octets). The notes below the table describe the 10 Mb/s, 1 Gb/s, and 10 Gb/s interPacketGap shrinkage behavior.

## Practical RTL relevance

This annex is useful as a behavioral reference for a full duplex MAC implementation, but the implementation choice of pipelines, FIFOs, reset handling, and APB register plumbing remains outside the standard.
