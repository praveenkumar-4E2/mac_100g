# Annex 31B Amendment — MAC Control PAUSE operation (802.3ba-2010)

Source: IEEE Std 802.3ba-2010, pages 357–359 (PDF pages 381–384)

This amendment modifies Annex 31B of IEEE Std 802.3-2008 to add timing specifications for 40 Gb/s and 100 Gb/s operation, and to split the 10 Gb/s timing into separate entries for 10GBASE-T and other 10 Gb/s PHY types.

---

## 31B.3.7 Timing considerations for PAUSE operation

*Change subclause 31B.3.7 (IEEE Std 802.3-2008/Cor 1-2009) as follows:*

In a full duplex mode DTE, it is possible to receive PAUSE frames asynchronously with respect to the transmission of MAC frames. For effective flow control, it is necessary to place an upper bound on the length of time that a DTE can transmit data frames after receiving a valid PAUSE frame with a non-zero pause_time request_operand.

Reception of a PAUSE frame shall not affect the transmission of a MAC frame that has been submitted by the MAC Control sublayer to the underlying MAC (i.e., the MAC:MA_DATA.request service primitive is synchronous, and is never interrupted).

At operating speeds of 100 Mb/s or less, a station that implements an exposed MII, shall not begin to transmit a (new) frame (assertion of TX_EN at the MII, see 22.2.2.3) more than pause_quantum bit times after the reception of a valid PAUSE frame (de-assertion of RX_DV at the MII, see 22.2.2.6) that contains a non-zero value of pause_time. Stations that do not implement an exposed MII, shall measure this time at the MDI, with the timing specification increased to (pause_quantum + 64) bit times.

At an operating speed of 1000 Mb/s, a station shall not begin to transmit a (new) frame more than two pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI.

At operating speeds of 10 Gb/s, a station with a 10GBASE-T PHY shall not begin to transmit a (new) frame more than 74 pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI. A station using any other 10 Gb/s PHY shall not begin to transmit a (new) frame more than 60 pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI.

At operating speeds of 40 Gb/s, a station shall not begin to transmit a (new) frame more than 118 pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI.

At operating speeds of 100 Gb/s, a station shall not begin to transmit a (new) frame more than 394 pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI.

In addition to DTE and MAC Control delays, system designers should take into account the delay of the link segment when designing devices that implement the PAUSE operation.

## 31B.4 Protocol implementation conformance statement (PICS) proforma for MAC Control PAUSE operation

### 31B.4.3 Major capabilities/options

*Change the table in 31B.4.3 as follows:*

> **Table: Major capabilities/options — Amended (31B.4.3)**
>
> **Table type**: PICS capabilities/options table (amended by 802.3ba-2010)
>
> **Visual content**: An expanded 6-column table adding entries for 10 Gb/s (split into two PHY types), 40 Gb/s, and 100 Gb/s. The *MIIc entry text is changed from "above 100 Mb/s" to "above 100 of 1000 Mb/s" (strikethrough on "above 100", underline on "of 1000").
>
> | Item | Feature | Subclause | Value/Comment | Status | Support |
> |------|---------|-----------|---------------|--------|---------|
> | *PST | Support for transmit of PAUSE frames | 31B.3.2 | N/A | O | Yes [ ] / No [ ] |
> | *MIIa | At operating speeds of 100 Mb/s or less, MII connection exists and is accessible for test. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIb | At operating speeds of 100 Mb/s or less, MII connection does not exist or is not accessible for test. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIc | At operating speeds ~~above 100~~ **of 1000** Mb/s. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIId | At operating speeds of 10 Gb/s with PHY types other than 10GBASE-T. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIe | At operating speeds of 10 Gb/s with PHY types of 10GBASE-T. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIf | At operating speeds of 40 Gb/s. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIg | At operating speeds of 100 Gb/s. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
>
> **Key changes from base**: Added *MIId through *MIIg entries for 10/40/100 Gb/s. Modified *MIIc text.

### 31B.4.6 PAUSE command MAC timing considerations

*Change subclause 31B.4.6 (IEEE Std 802.3-2008/Cor 1-2009) as follows:*

> **Table: PAUSE command MAC timing considerations — Amended (31B.4.6)**
>
> **Table type**: PICS timing requirements table (amended by 802.3ba-2010)
>
> **Visual content**: An expanded timing table adding TIM6, TIM7, and TIM8 for 10GBASE-T, 40 Gb/s, and 100 Gb/s respectively. TIM5 description updated to specify "PHY types other than 10GBASE-T".
>
> | Item | Feature | Subclause | Value/Comment | Status | Support |
> |------|---------|-----------|---------------|--------|---------|
> | TIM1 | Effect of PAUSE frame on a frame already submitted to underlying MAC | 31B.3.7 | Has no effect | M | Yes [ ] |
> | TIM2 | Measurement point for station with MII | 31B.3.7 | Delay at MII ≤ pause_quantum bits | MIIa: M | N/A [ ] / M: Yes [ ] |
> | TIM3 | Measurement point for station without MII at 100 Mb/s or less | 31B.3.7 | Delay at MDI ≤ (pause_quantum + 64) bits | MIIb: M | N/A [ ] / M: Yes [ ] |
> | TIM4 | Measurement point for station at 1000 Mb/s | 31B.3.7 | Delay at MDI ≤ (2 × pause_quantum) bits | MIIc: M | N/A [ ] / M: Yes [ ] |
> | TIM5 | Measurement point for station at 10 Gb/s with PHY types other than 10GBASE-T | 31B.3.7 | Delay at MDI ≤ (60 × pause_quantum) bits | MIId: M | N/A [ ] / M: Yes [ ] |
> | TIM6 | Measurement point for station at 10Gb/s with PHY type of 10GBASE-T. | 31B.3.7 | Delay at MDI ≤ (74 × pause_quantum) bits | MIIe: M | N/A [ ] / M: Yes [ ] |
> | TIM7 | Measurement point for station at 40 Gb/s | 31B.3.7 | Delay at MDI ≤ (118 × pause_quantum) bits | MIIf: M | N/A [ ] / M: Yes [ ] |
> | TIM8 | Measurement point for station at 100 Gb/s | 31B.3.7 | Delay at MDI ≤ (394 × pause_quantum) bits | MIIg: M | N/A [ ] / M: Yes [ ] |
>
> **Key changes from base**: TIM5 description refined to exclude 10GBASE-T. Added TIM6 (74 pause_quantum for 10GBASE-T), TIM7 (118 pause_quantum for 40 Gb/s), TIM8 (394 pause_quantum for 100 Gb/s).

---

## Rendered page image descriptions

Detailed page-image descriptions for this amendment are available in [IMAGE_DESCRIPTIONS.md](IMAGE_DESCRIPTIONS.md). The key visual content is:

- The amended 31B.3.7 timing text on page 381.
- The amended Table 31B-1 major capabilities/options on page 382.
- The amended Table 31B-4 timing considerations on page 383.
- The trailing amendment page content on page 384.
