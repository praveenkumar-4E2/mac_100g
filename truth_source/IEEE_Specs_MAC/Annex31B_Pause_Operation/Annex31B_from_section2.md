# Annex 31B (normative) — MAC Control PAUSE operation

Source: IEEE Std 802.3-2008, section 2, pages 741–751 (PDF pages 741–752)

---

## 31B.1 PAUSE description

The PAUSE operation is used to inhibit transmission of data frames for a specified period of time. A MAC Control client wishing to inhibit transmission of data frames from another station on the network generates a MA_CONTROL.request primitive specifying:

a) The globally assigned 48-bit multicast address 01-80-C2-00-00-01,
b) The PAUSE opcode,
c) A request_operand indicating the length of time for which it wishes to inhibit data frame transmission. (See 31B.2.)

The PAUSE operation cannot be used to inhibit transmission of MAC Control frames.

PAUSE frames shall only be sent by DTEs configured to the full duplex mode of operation.

The globally assigned 48-bit multicast address 01-80-C2-00-00-01 has been reserved for use in MAC Control PAUSE frames for inhibiting transmission of data frames from a DTE in a full duplex mode IEEE 802.3 LAN. IEEE 802.1D-conformant bridges will not forward frames sent to this multicast destination address, regardless of the state of the bridge's ports, or whether or not the bridge implements the MAC Control sublayer. To allow generic full duplex flow control, stations implementing the PAUSE operation shall instruct the MAC (e.g., through layer management) to enable reception of frames with destination address equal to this multicast address.

NOTE—By definition, an IEEE 802.3 LAN operating in full duplex mode comprises exactly two stations, thus there is no ambiguity regarding the destination DTE's identity. The use of a well-known multicast address relieves the MAC Control sublayer and its client from having to know, and maintain knowledge of, the individual 48-bit address of the other DTE in a full duplex environment.

## 31B.2 Parameter semantics

The PAUSE opcode takes the following request_operand:

**pause_time**
A 2-octet, unsigned integer containing the length of time for which the receiving station is requested to inhibit data frame transmission. The field is transmitted most-significant octet first, and least-significant octet second. The pause_time is measured in units of pause_quanta, equal to 512 bit times of the particular implementation (See 4.4). The range of possible pause_time is 0 to 65535 pause_quanta.

## 31B.3 Detailed specification of PAUSE operation

### 31B.3.1 Transmit operation

Upon receipt of a MA_CONTROL.request primitive containing the PAUSE opcode from a MAC client, the MAC Control sublayer calls the MAC sublayer MAC:MA_DATA.request service primitive with the following parameters:

a) The destination_address is set equal to the destination_address parameter of the MA_CONTROL.request primitive. This parameter is currently restricted to the value specified in 31B.1.
b) The source_address is set equal to the 48-bit individual address of the station.
c) The length/type field (i.e., the first two octets) within the mac_service_data_unit parameter is set to the IEEE 802.3 MAC Control type value assigned in 31.4.1.3.
d) The remainder of the mac_service_data_unit is set equal to the concatenation of the PAUSE opcode encoding (see Annex 31A), the pause_time request_operand specified in the MA_CONTROL.request primitive, and a field containing zeros of the length specified in 31.4.1.6.
e) The frame_check_sequence is omitted.

Upon receipt of a data transmission request from the MAC client through the MCF:MA_DATA.request primitive, if the transmission of data frames has not been inhibited due to reception of a valid MAC Control frame specifying the PAUSE operation and a non-zero pause_time, the MAC Control sublayer calls the MAC sublayer MAC:MA_DATA.request service primitive with its parameters identical to the MCF:MA_DATA.indication primitive.

### 31B.3.2 Transmit state diagram for PAUSE operation

It is not required that an implementation be able to transmit PAUSE frames. MAC Control sublayer entities that transmit PAUSE frames shall implement the Transmit state diagram specified in this subclause.

#### 31B.3.2.1 Constants

- **pause_command**: The 2-octet encoding of the PAUSE command, as specified in Annex 31A.
- **reserved_multicast_address**: The 48-bit address specified in 31B.1 (a).
- **802.3_MAC_Control**: The 16 bit type field assignment for 802.3 MAC Control specified in 31.4.1.3.
- **phys_Address**: A 48-bit value, equal to the unicast address of the station implementing the MAC Control sublayer.

#### 31B.3.2.2 Variables

- **transmitEnabled**: A Boolean set by network management to indicate that the station is permitted to transmit on the network.
  - Values: true; Transmitter is enabled by management; false; Transmitter is disabled by management
- **transmission_in_progress**: A Boolean used to indicate to the Receive state diagram that a MAC:MA_DATA.request service primitive call is pending.
  - Values: true; transmission is in progress; false; transmission is not in progress
- **n_quanta_tx**: An integer indicating the number of pause_quanta that the transmitter of a PAUSE frame is requesting that the receiver pause.
- **pause_timer_Done**: A Boolean set by the MAC Control PAUSE Operation Receive state diagram to indicate the expiration of a pause_timer initiated by reception of a MAC Control frame with a PAUSE opcode.
  - Values: true; The pause_timer has expired; false; The pause_timer has not expired.
- **pause_mac_service_data_unit**: The concatenation of IEEE 802.3_MAC_Control, pause_command, n_quanta_tx, zeros.

#### 31B.3.2.3 Functions

None

#### 31B.3.2.4 Timers

- **pause_timer**: The timer governing the inhibition of transmission of data frames (see 31.5.1) from a MAC Client by the PAUSE function.

#### 31B.3.2.5 Messages

- **MA_CONTROL.request**: The service primitive used by a client to request a MAC Control sublayer function with the specified request_operands.
- **MCF:MA_DATA.request**: The service primitive used by a client to request MAC data transmission with the specified parameters.
- **MAC:MA_DATA.request**: The service primitive issued by the MAC Control sublayer to transmit a MAC frame with the specified parameters.

#### 31B.3.2.6 Transmit state diagram for PAUSE operation

Figure 31B-1 depicts the Transmit state diagram for a MAC Control sublayer entity implementing the PAUSE operation.

> **Figure 31B-1 — PAUSE Operation Transmit state diagram**
>
> **Figure type**: State diagram (normative)
>
> **Visual content**: A state machine with 5 states and multiple conditional transitions governing PAUSE frame transmission.
>
> **States**:
> - **BEGIN** (entry point)
> - **INITIALIZE TX**: Sets `pause_timerDone ← true`, `transmission_in_progress ← false`
> - **HALT TX**: Sets `transmission_in_progress ← false`; entered when `transmitEnabled = false`
> - **PAUSED**: Sets `transmission_in_progress ← false`; central idle state
> - **TRANSMIT READY**: Intermediate state between PAUSED and sending
> - **SEND CONTROL FRAME**: Sets `transmission_in_progress ← true`; issues `MAC:MA_DATA.request(reserved_multicast_address, phys_Address, pause_mac_service_data_unit, frame_check_sequence)`
> - **SEND DATA FRAME**: Sets `transmission_in_progress ← true`; issues `MAC:MA_DATA.request(destination_address, source_address, mac_service_data_unit, frame_check_sequence)`
>
> **Key transitions**:
> - From INITIALIZE TX: `transmitEnabled = true` → PAUSED; `transmitEnabled = false` → HALT TX
> - From HALT TX: `transmitEnabled = true` → PAUSED
> - From PAUSED: `pause_timerDone = true` → TRANSMIT READY
> - From TRANSMIT READY: `pause_timerDone = false` → PAUSED (loop back)
> - From TRANSMIT READY (PAUSE request): `pause_timerDone = true` AND `MA_CONTROL.request(pause_command, n_quanta_tx)` AND `reserved_multicast_address` → SEND CONTROL FRAME
> - From TRANSMIT READY (data request): `pause_timerDone = true` AND `MCF:MA_DATA.request(...)` AND NOT `MA_CONTROL.request(reserved_multicast_address, pause_command, n_quanta_tx)` → SEND DATA FRAME
> - From TRANSMIT READY (PAUSE request while paused): `pause_timerDone = FALSE` AND `MA_CONTROL.request(pause_command, n_quanta_tx)` AND `reserved_multicast_address` → SEND CONTROL FRAME
> - Both SEND CONTROL FRAME and SEND DATA FRAME return via UCT (Unconditional Transition) to PAUSED
>
> **Relationships**: The diagram shows that PAUSE frame transmission can occur even when the station is in a paused state (pause_timerDone = FALSE), but data frame transmission is only allowed when pause_timerDone = true. New PAUSE operations override earlier ones.

### 31B.3.4 Receive state diagram for PAUSE operation

#### 31B.3.4.1 Constants

- **pause_quantum**: The unit of measurement for pause time specified in 31B.2
- **pause_command**: The 2-octet encoding of the PAUSE command, as specified in Annex 31A.
- **reserved_multicast_address**: The 48-bit address specified in 31B.1 (a).
- **phys_Address**: A 48-bit value, equal to the unicast address of the station implementing the MAC Control sublayer.

#### 31B.3.4.2 Variables

- **n_quanta_rx**: An integer used to extract the number of pause quanta to set the pause_timer from the dataParam of the received MAC frame.
- **opcode**: The opcode parsed from the received MAC frame.
- **DA**: The destination address from the MAC:MA_DATA.indication service primitive.
- **data**: The data payload parsed from the received MAC frame.
- **transmission_in_progress**: A Boolean used by the Transmit state diagram to indicate that a MAC:MA_DATA.request service primitive call is pending.
  - Values: true; transmission is in progress; false; transmission is not in progress

#### 31B.3.4.3 Timers

- **pause_timer**: The timer governing the inhibition of transmission of data frames.

#### 31B.3.4.4 Receive state diagram (INITIATE MAC CONTROL FUNCTION) for PAUSE operation

Figure 31B-2 depicts the INITIATE MAC CONTROL FUNCTION for the PAUSE operation. (See 31.5.3.)

> **Figure 31B-2 — PAUSE Operation Receive state diagram**
>
> **Figure type**: State diagram (normative)
>
> **Visual content**: A state machine with 3 states governing PAUSE frame reception and timer management.
>
> **States**:
> - Entry via `opcode = pause_command`
> - **WAIT FOR TRANSMISSION COMPLETION**: Waits for any in-progress transmission to finish
> - **PAUSE FUNCTION**: Extracts `n_quanta_rx = data[17:32]` and starts `pause_timer(n_quanta_rx * pause_quantum)`
> - **END PAUSE**: Terminal state
>
> **Key transitions**:
> - Entry: `opcode = pause_command` → WAIT FOR TRANSMISSION COMPLETION
> - From WAIT FOR TRANSMISSION COMPLETION: `transmission_in_progress = false` AND `((DA = reserved_multicast_address) + (DA = phys_Address))` → PAUSE FUNCTION
> - From WAIT FOR TRANSMISSION COMPLETION: `(DA ≠ reserved_multicast_address)` AND `(DA ≠ phys_Address)` → END PAUSE (destination address mismatch, abort)
> - From PAUSE FUNCTION: UCT (unconditional transition) → END PAUSE
>
> **Relationships**: The receive state diagram validates the destination address against both the reserved multicast address (01-80-C2-00-00-01) and the station's physical address. Only if one matches does it proceed to set the pause timer. The timer value is extracted from bits 17-32 of the received data payload.

### 31B.3.5 Status indication operation

MAC Control sublayer entities that implement the PAUSE operation shall implement the Indication state diagram specified in this subclause.

The PAUSE function sets the pause_status variable to one of two values: paused or not_paused, and indicates this to its client through the MA_CONTROL.indication primitive.

### 31B.3.6 Indication state diagram for pause operation

#### 31B.3.6.1 Constants

- **pause_command**: The 2-octet encoding of the PAUSE command, as specified in Annex 31A.

#### 31B.3.6.2 Variables

- **pause_status**: Used to indicate the state of the MAC Control sublayer for the PAUSE operation. It takes one of two values: paused or not_paused.
- **pause_timer_Done**: A Boolean set by the MAC Control PAUSE Operation Receive state diagram to indicate the expiration of a pause_timer initiated by reception of a MAC Control frame with a PAUSE opcode.
  - Values: true; The pause_timer has expired; false; The pause_timer has not expired.

#### 31B.3.6.3 Messages

- **MA_CONTROL.indication**: The service primitive used to indicate the state of the MAC Control sublayer to its client.

#### 31B.3.6.4 Indication state diagram for PAUSE operation

Figure 31B-3 depicts the Indication State Diagram for a MAC Control sublayer implementing the PAUSE operation.

> **Figure 31B-3 — PAUSE Operation Indication state diagram**
>
> **Figure type**: State diagram (normative)
>
> **Visual content**: A simple two-state machine indicating PAUSE status to the MAC client.
>
> **States**:
> - **BEGIN** (entry point)
> - **NOT PAUSED**: Sets `pause_status = not_paused`; issues `MA_CONTROL.indication(pause_command, pause_status)`
> - **PAUSED**: Sets `pause_status = paused`; issues `MA_CONTROL.indication(pause_command, pause_status)`
>
> **Key transitions**:
> - From BEGIN → NOT PAUSED
> - From NOT PAUSED: `pause_timer_Done = false` → PAUSED (pause timer started, entering paused state)
> - From PAUSED: `pause_timer_Done = true` → NOT PAUSED (pause timer expired, returning to normal)
>
> **Relationships**: This diagram provides the client-visible interface to the PAUSE state. The client is notified via MA_CONTROL.indication whenever the pause status changes. The state machine oscillates between NOT PAUSED and PAUSED based on the pause_timer_Done variable set by the Receive state diagram.

### 31B.3.7 Timing considerations for PAUSE operation

In a full duplex mode DTE, it is possible to receive PAUSE frames asynchronously with respect to the transmission of MAC frames. For effective flow control, it is necessary to place an upper bound on the length of time that a DTE can transmit data frames after receiving a valid PAUSE frame with a non-zero pause_time request_operand.

Reception of a PAUSE frame shall not affect the transmission of a MAC frame that has been submitted by the MAC Control sublayer to the underlying MAC (i.e., the MAC:MA_DATA.request service primitive is synchronous, and is never interrupted).

At operating speeds of 100 Mb/s or less, a station that implements an exposed MII, shall not begin to transmit a (new) frame (assertion of TX_EN at the MII, see 22.2.2.3) more than pause_quantum bit times after the reception of a valid PAUSE frame (de-assertion of RX_DV at the MII, see 22.2.2.6) that contains a non-zero value of pause_time. Stations that do not implement an exposed MII, shall measure this time at the MDI, with the timing specification increased to (pause_quantum + 64) bit times.

At an operating speed of 1000 Mb/s, a station shall not begin to transmit a (new) frame more than two pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI.

At operating speeds of 10 Gb/s and above, a station shall not begin to transmit a (new) frame more than sixty pause_quantum bit times after the reception of a valid PAUSE frame that contains a non-zero value of pause_time, as measured at the MDI.

In addition to DTE and MAC Control delays, system designers should take into account the delay of the link segment when designing devices that implement the PAUSE operation.

## 31B.4 Protocol implementation conformance statement (PICS) proforma for MAC Control PAUSE operation

### 31B.4.1 Introduction

The supplier of a protocol implementation that is claimed to conform to Annex 31B, MAC Control PAUSE operation, shall complete the following PICS proforma in addition to the PICS of Clause 31.

A detailed description of the symbols used in the PICS proforma, along with instructions for completing the PICS proforma, can be found in Clause 21.

### 31B.4.2 Identification

#### 31B.4.2.1 Implementation identification

> **Table: Implementation identification (31B.4.2.1)**
>
> **Table type**: PICS proforma form
>
> **Visual content**: A two-column table with fields for supplier information.
>
> | Field | Value |
> |-------|-------|
> | Supplier | (blank) |
> | Contact point for queries about the PICS | (blank) |
> | Implementation Name(s) and Version(s) | (blank) |
> | Other information necessary for full identification | (blank) |
>
> NOTE 1—Only the first three items are required for all implementations.
> NOTE 2—The terms Name and Version should be interpreted appropriately.

#### 31B.4.2.2 Protocol summary

> **Table: Protocol summary (31B.4.2.2)**
>
> **Table type**: PICS proforma form
>
> **Visual content**: A two-column identification table.
>
> | Field | Value |
> |-------|-------|
> | Identification of protocol specification | IEEE Std 802.3-2008, Annex 31B, MAC Control PAUSE operation |
> | Identification of amendments and corrigenda | (blank) |
> | Have any Exception items been required? | No [ ] Yes [ ] |
> | Date of Statement | (blank) |

### 31B.4.3 Major capabilities/options

> **Table 31B-1: Major capabilities/options (31B.4.3)**
>
> **Table type**: PICS capabilities/options table
>
> **Visual content**: A 6-column table (Item, Feature, Subclause, Value/Comment, Status, Support) listing optional capabilities.
>
> | Item | Feature | Subclause | Value/Comment | Status | Support |
> |------|---------|-----------|---------------|--------|---------|
> | *PST | Support for transmit of PAUSE frames | 31B.3.2 | N/A | O | Yes [ ] / No [ ] |
> | *MIIa | At operating speeds of 100 Mb/s or less, MII connection exists and is accessible for test. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIb | At operating speeds of 100 Mb/s or less, MII connection does not exist or is not accessible for test. | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |
> | *MIIc | At operating speeds above 100 Mb/s | 31B.3.7 | N/A | O | Yes [ ] / No [ ] |

### 31B.4.4 PAUSE command requirements

> **Table: PAUSE command requirements (31B.4.4)**
>
> **Table type**: PICS mandatory requirements table
>
> **Visual content**: A 6-column table listing mandatory PAUSE command features.
>
> | Item | Feature | Subclause | Value/Comment | Status | Support |
> |------|---------|-----------|---------------|--------|---------|
> | PCR1 | Duplex mode of DTE | 31B.1 | Full duplex | M | Yes [ ] |
> | PCR2 | Reception of frames with destination address equal to the multicast address 01-80-C2-00-00-01 | 31B.1 | Enabled | M | Yes [ ] |

### 31B.4.5 PAUSE command state diagram requirements

> **Table: PAUSE command state diagram requirements (31B.4.5)**
>
> **Table type**: PICS state diagram conformance table
>
> **Visual content**: A 6-column table listing state diagram conformance items.
>
> | Item | Feature | Subclause | Value/Comment | Status | Support |
> |------|---------|-----------|---------------|--------|---------|
> | PSD1 | Transmit state diagram for PAUSE operation | 31B.3.2 | Meets requirements of Figure — | PST: M | N/A [ ] / M: Yes [ ] |
> | PSD2 | Receive state diagram for PAUSE operation | 31B.3.4 | Meets requirements of Figure 31B-1 | M | Yes [ ] |
> | PSD3 | Indication state diagram for PAUSE operation | 31B.3.6 | Meets requirements of Figure 31B-2 | M | Yes [ ] |

### 31B.4.6 PAUSE command MAC timing considerations

> **Table: PAUSE command MAC timing considerations (31B.4.6)**
>
> **Table type**: PICS timing requirements table
>
> **Visual content**: A 6-column table listing timing measurement points and delay bounds.
>
> | Item | Feature | Subclause | Value/Comment | Status | Support |
> |------|---------|-----------|---------------|--------|---------|
> | TIM1 | Effect of PAUSE frame on a frame already submitted to underlying MAC | 31B.3.7 | Has no effect | M | Yes [ ] |
> | TIM2 | Measurement point for station with MII | 31B.3.7 | Delay at MII ≤ pause_quantum bits | MIIa: M | N/A [ ] / M: Yes [ ] |
> | TIM3 | Measurement point for station without MII at 100 Mb/s or less | 31B.3.7 | Delay at MDI ≤ (pause_quantum + 64) bits | MIIb: M | N/A [ ] / M: Yes [ ] |
> | TIM4 | Measurement point for station at 1000 Mb/s | 31B.3.7 | Delay at MDI ≤ (2 × pause_quantum) bits | MIIc: M | N/A [ ] / M: Yes [ ] |
> | TIM5 | Measurement point for station at 10 Gb/s or greater | 31B.3.7 | Delay at MDI ≤ (60 × pause_quantum) bits | MIId: M | N/A [ ] / M: Yes [ ] |

---

## Rendered page image descriptions

Detailed page-image descriptions for this annex are available in [IMAGE_DESCRIPTIONS.md](IMAGE_DESCRIPTIONS.md). The key visual content is:

- Figure 31B-1: PAUSE operation transmit state diagram.
- Figure 31B-2: PAUSE operation receive state diagram.
- Figure 31B-3: PAUSE operation indication state diagram.
- Table 31B-1: major capabilities/options.
- Table 31B-2: PAUSE command requirements.
- Table 31B-3: PAUSE command state diagram requirements.
- Table 31B-4: PAUSE command MAC timing considerations.
