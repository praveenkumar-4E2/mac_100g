4. Media Access Control
4.4.2 MAC parameters
Insert a new column to Table 4-2 for 40 Gb/s and 100 Gb/s MAC data rates as follows:
Table 4–2—MAC parameters  
Insert the following note below Table 4-2 (above th e warning box) for 40 Gb/s and 100 Gb/s MAC data
rates, and renumber notes as appropriate:
NOTE 7—For 40 Gb/s and 100 Gb/s operation, the received interPacketGap (the spacing be tween two packets, from the
last bit of the FCS field of the first packet to the first bit of the Preamble of the second packet) can have a minimum value
of 8 BT (bit times), as measured at the XLGMII or CGMII receive signals at the DTE due to clock tolerance and lane
alignment requirements.
Parameters
MAC data rate
Up to and
including
100 Mb/s
1 Gb/s 10 Gb/s 40 Gb/s and 
100 Gb/s
slotTime 512 bit times 4096 bit tim es not applicable not applicable
interPacketGapa
aReferences to interFrameGap or interFrameSpacing in other clauses (e.g., 13, 35, and 42) shall be interpreted as 
interPacketGap.
96 bits 96 bits 96 bits 96 bits
attemptLimit 16 16 not applicable not applicable
backoffLimit 10 10 not applicable not applicable
jamSize 32 bits 32 bits not applicable not applicable
maxBasicFrameSize 1518 octets 1518 octets 1518 octets 1518 octets
maxEnvelopeFrameSize 2000 octets 2000 octets 2000 octets 2000 octets
minFrameSize 512 bits (64 octets) 512 bits (64 octets) 512 bits (6 4 octets) 512 bits  (64 octets)
burstLimit not applicable 65 536 bi ts not applicable not applicable
ipgStretchRatio not applicable not applicable 104 bi ts not applicable

---
<!-- Page 32 -->
---



---
<!-- Page 33 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 9
30. Management 
Insert two new objects into Table 31-1e, before aIdleErrorCount, as follows: 
Insert new PHY types in alphanumeric order into “APPROPRIATE SYNTAX” of 30.3.2.1.2:
30.3.2.1.2 aPhyType
APPROPRIATE SYNTAX:
...
40GBASE-R Clause 82 40 Gb/s multi-PCS lane 64B/66B
100GBASE-R Clause 82 100 Gb/s multi-PCS lane 64B/66B
Insert new PHY types in alphanumeric order into “APPROPRIATE SYNTAX” of 30.3.2.1.3:
30.3.2.1.3 aPhyTypeList
APPROPRIATE SYNTAX:
...
40GBASE-R Clause 82 40 Gb/s multi-PCS lane 64B/66B
100GBASE-R Clause 82 100 Gb/s multi-PCS lane 64B/66B
Table 30–1e—Capabilities
DTE Repeater MAU
Basic Package (mandatory)
Mandatory Package (mandatory)
Recommended Package (optional)
Optional Package (optional)
Array Package (optional)
Excessive Deferral Package (optional)
Multiple PHY Package (optional)
PHY Error Monitor Capability (optional)
Basic Control Capability (mandatory)
Performance Monitor Capability (optional)
Address Tracking Capability (optional)
100/1000 Mb/s Monitor Capability (optional)
1000 Mb/s Burst Monitor Capability (optional)
Basic Package (mandatory)
MAU Control Package (optional)
Media Loss Tracking Package (conditional)
Broadband DTE MAU Package (conditional)
MII Capability (conditional)
PHY Error Monitor Capability (optional)
10GBASE-T Operating Margin package (conditional)
Forward Error Correction Package (conditional)
Auto-Negotiation Package (mandatory)
oMAU managed object class (30.5.1)
aBIPErrorCount ATTRIBUTE GET X
aLaneMapping ATTRIBUTE GET X

---
<!-- Page 34 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
10 Copyright © 2010 IEEE. All rights reserved.
Change 30.3.2.1.5 as follows:
30.3.2.1.5 aSymbolErrorDuringCarrier
ATTRIBUTE
APPROPRIATE SYNTAX:
Generalized nonresetable counter. This counter has a maximum increment rate of 160 000 counts
per second for 100 Mb/s implementations
BEHAVIOUR DEFINED AS:
For 100 Mb/s operation it is a count of the number of times when valid carrier was present and there
was at least one occurrence of an invalid data symbol (see 23.2.1.4, 24.2.2.1.6, and 32.3.4.1). 
For half duplex operation at 1000 Mb/s, it is a count of the number of times the receiving media is
non-idle (a carrier event) for a pe riod of time equal to or greater  than slotTime (see 4.2.4), and
during which there was at least one occurrence of an event that causes the PHY to indicate “Data
reception error” or “Carrier Extend Error” on the GMII (see Table 35–2). 
For full duplex operation at 1000 Mb/s, it is a count of the number of times the receiving media is
non-idle (a carrier event) for a pe riod of time equal to or greater than minFrameSize, and during
which there was at least one occurrence of an event that causes the PHY to indicate “Data reception
error” on the GMII (see Table 35–2). 
For operation at 10 Gb/s, 40 Gb/s, and 100 Gb/s, it is a count of the number of times the receiving
media is non-idle (the time between the Start of Packet Delimiter and the End of Packet Delimiter
as defined by 46.2.5 and 81.2.5) for a period of time equal to or greater than minFrameSize, and
during which there was at least one occurrence of an event that causes the PHY to indicate
“Receive Error” on the XGMII (see Table 46-4), the XLGMII or the CGMII (see Table 81–3). 
At all speeds this counter shall be incremented only once per valid CarrierEvent and if a collision
is present this counter shall not increment.;
Insert new PHY types into “APPROPRIATE SYNTAX” before 802.9a (as modified by IEEE Std 802.3av)
and change “BEHAVIOUR DEFINED AS” of 30.5.1.1.2 as follows:
30.5.1.1.2 aMAUType
APPROPRIATE SYNTAX:
...
40GBASE-R
Multi-lane PCS as specified in Clause 82 over undefined PMA/PMD
40GBASE-KR4 40GBASE-R PCS/PMA over an electrical backplane PMD as specified in
Clause 84
40GBASE-CR4 40GBASE-R PCS/PMA over 4 lane shielded copper balanced cable PMD as 
specified in Clause 85
40GBASE-SR4 40GBASE-R PCS/PMA over 4 lane multimode fiber PMD as specified in
 Clause 86
40GBASE-LR4 40GBASE-R PCS/PMA over 4 WDM lane single mode fiber PMD, with long
reach, as specified in Clause 87
100GBASE-R Multi-lane PCS as specified in Clause 82 over undefined PMA/PMD
100GBASE-CR10 100GBASE-R PCS/PMA over 10 lane shielded copper balanced cable PMD
as specified in Clause 85
100GBASE-SR10 100GBASE-R PCS/PMA over 10 lane multimode fiber PMD as specified in
 Clause 86
100GBASE-LR4 100GBASE-R PCS/PMA over 4 WDM lane single mode fiber PMD, with
long reach, as specified in Clause 88
100GBASE-ER4 100GBASE-R PCS/PMA over 4 WDM lane single mode fiber PMD, with 
extended reach, as specified in Clause 88

---
<!-- Page 35 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 11
...
BEHAVIOUR DEFINED AS:
Returns a value that identifies the internal MAU t ype. If an AUI is to be identified to access an
external MAU, the type “AUI” is returned. A SET operation to one of the possible enumerations
indicated by aMAUTypeList will force the MAU into the new operating mode. If a Clause 22 MII
or Clause 35 GMII is present, then this will map to  the mode force bits speci fied in 22.2.4.1. If a
Clause 45 MDIO Interf ace is present, then this will map to the PCS type selection bit(s) in the
10G WIS Control 2 register specified in 45.2.2.6.6, the 10G PCS Control 2 register specified in
45.2.3.6.1, the PMA/PMD type selection bits in the 10G PMA/PMD Control 2 register specified
in 45.2.1.6.1, the PMA/PMD control 1 register specified in 45.2.1.1 and the PCS control 1 register
45.2.3.1. If Clause 28, Clause 37, or Clause 73 Auto-Negotiation is operational, then this will
change the advertised ability to the single enumeration specified in the SET operation, and cause
an immediate link renegotiation. A change in the MAU type will also be reflected in aPHYType.
The enumerations 1000BASE-X, 1000BASE-XHD, 1000BASE-XFD, 10GBASE-X, 
10GBASE-R, and 10GBASE-W, 40GBASE-R and 100GBASE-R shall only be returned if the
underlying PMD type is unknown.;
Change “BEHAVIOUR DEFINED AS” of 30.5.1.1.4 for high BER as follows:
30.5.1.1.4 aMediaAvailable
BEHAVIOUR DEFINED AS:
If the MAU is a 10M b/s link or fiber type (FOIRL, 10BASE-T, 10BASE-F), then this is equivalent
to the link test fail state/low light function.  For an AUI, 10BASE2, 10BASE5, or 10BROAD36
MAU, this indicates whether or not loopback is detected on the DI circuit. The value of this attribute
persists between packets for MAU types AUI, 10BASE5, 10BASE2, 10BROAD36, and 10BASE-
FP.
At power-up or following a reset, the value of this attribute will be “unknown” for AUI, 10BASE5,
10BASE2, 10BROAD36, and 10BASE-FP MAUs. For these MAUs loopback will be tested on
each transmission during which no collision is detected. If DI is receiving input when DO returns
to IDL after a transmission and there has been no collision during the transmission, then loopback
will be detected. The value of this attribute will only change during noncollided transmissions for
AUI, 10BASE2, 10BASE5, 10BROAD36, and 10BASE-FP MAUs.
For 100BASE-T2 and 100BASE-T4 PHYs the enumerations match the states within the respective
link integrity state diagrams, Figure 32–16 an d Figure 23–12. For 100BASE-TX, 100BASE-FX,
100BASE-LX10 and 100BASE-BX10 PHYs the enumerations match the states within the link
integrity state diagram Figure 24–15. Any MAU that implements management of Clause 28 or
Clause 73 Auto-Negotiation will map remote fault indica tion to MediaAvailable “remote fault.”
Any MAU that implements management of Clause 37 Auto-Negotiation will map the received
RF1 and RF2 bits as specified in Table 37–2, as follows. Offline maps to the enumeration
“offline,” Link_Failure maps to the enumeration “remote fault” and Auto-Negotiation Error maps
to the enumeration “auto neg error.”
The enumeration “remote fault” applies to 10BASE-FB remote fault indication, the 100BASE-X
far-end fault indication and nonspecified remote faults from a system running Clause 28 Auto-
Negotiation. The enumerations “r emote jabber”, “remote link loss”, or “remote test” should be
used instead of “remote fault” where the reason for remote faul t is identified in the remote
signaling protocol.
Where a Clause 22 MII or Clause 35 GMII is present, a logic
 one in the remote fault bit
(22.2.4.2.11) maps to the enum eration “remote fault,” a logic  zero in the link status bit
(22.2.4.2.13) maps to the enumeration “not av ailable.” The enumerati on “not available” takes
precedence over “remote fault.”
For 40 Gb/s and 100 Gb/s the enumerations map to value of the link_fault variable (see 
81.3.4) within

---
<!-- Page 36 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
12 Copyright © 2010 IEEE. All rights reserved.
the Link Fault Signaling state diagram (see 81.3.4.1 and Figure 46-9) as follows: the value OK maps
to the enumeration “available”, the value Local Fault maps to the enumeration “not available” and
the value Remote Fault maps to the enumeration “remote fault.”
For 2BASE-TL and 10PASS-TS PHYs, the enumeration “unknown” maps to the condition where
the PHY is initializing, the enumeration “ready” maps to the condition where at least one PME is
available and is ready for handshake, the enumeration “available” maps to the condition where, at
the PCS, at least one PME is operationally linked, the enumeration “not available” maps to the
condition where the PCS is not operationally linked, the enumeration “available reduced” maps to
the condition where a link fault is detected at the receive direction by one or more PMEs in the
aggregation group and the enumeration “PMD link fault” maps to the condition where a link fault
is detected at the receive direction by all of the PMA/PMDs in the aggregation group.
For 10 Gb/s the enumerations map to value of the link_fault variable within the Link Fault
Signaling state diagram (Figure 46–9) as follows: the value 
OK maps to the enumeration
“available”, the value Local Fault maps to th e enumeration “not available” and the value
Remote Fault maps to the enumeration “remote fault”. The enumeration “PMD link fault”, “WIS
frame loss”, “WIS signal loss”, “PCS link fault”, “excessive BER” or “DXS link fault” should be
used instead of the enumeration “not available” where the reason for the Local Fault state can be
identified through the us e of the Clause 45 MDIO Interface. Where multiple reasons for the
Local Fault state can be identified only the highest precedence error should be reported. This
precedence in descending order is as follows: “PXS link fault”, “PMD link fault”,
“WIS frame loss”, “WIS signal loss”, “PCS link f ault”, “excessive BER”, “DXS link fault”.
Where a Clause 45 MDIO interface is present a logic  zero in the PMA/PMD Receive link status
bit (45.2.1.2.2) maps to the e numeration “PMD link fault”, a logic  one in the LOF status bit
(45.2.2.10.4) maps to the enumeration “WIS frame loss”, a logic  one in the LOS status bit
(45.2.2.10.5) maps to the enumeration “WIS signal loss”, a logic  zero in the PCS Receive link
status bit (45.2.3.2.2) maps to the enumeration “PCS link fault”, a logic  one in the
10/40/100GBASE-R PCS Latched high BER status bit (45.2.3.12.2) maps to the enumeration
“excessive BER”, a logic  zero in the DTE XS receive link status bit (45.2.5.2.2) maps to the
enumeration “DXS link fault” and a logic zero in the PHY XS transmit link status bit (45.2.4.2.2)
maps to the enumeration “PXS link fault”.;
Insert a new subclause after 30.5.1.1.10 as follows:
30.5.1.1.10a aBIPErrorCount
ATTRIBUTE
APPROPRIATE SYNTAX:
A SEQUENCE of generalized nonresetable counters. Each counter has a maximum increment rate
of 10 000 counts per second for 40 Gb/s implementations and 5 000 counts per second for
100 Gb/s implementations.
BEHAVIOUR DEFINED AS:
For 40/100GBASE-R PHYs, an array of BIP error counters. The counters will not increment for other
PHY types. The indices of this array (0 to n 
– 1) denote the PCS lane number where n is the number
of PCS lanes in use. Each element of this array contains a count of BIP errors for that PCS lane.
Increment the counter by one for each BIP error detected during a lignment marker removal in the
PCS for the corresponding lane.
If a Clause 45 MDIO Interface to the PCS is presen t, then this attribute will map to the BIP error
counters (see 45.2.3.36 and 45.2.3.37).;

---
<!-- Page 37 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 13
30.5.1.1.10b aLaneMapping
ATTRIBUTE
APPROPRIATE SYNTAX:
A SEQUENCE of INTEGERs.
BEHAVIOUR DEFINED AS:
For 40/100GBASE-R PHYs, an array of PCS lane id entifiers. The indices of this array (0 to n – 1)
denote the service interface lane number where n is the number of PCS lanes in use. Each element of
this array contains the PCS lane number for the PCS lane that has been detected in the corresponding
service interface lane.
If a Clause 45 MDIO Interface to the PCS is present, then this attribute will map to the Lane mapping
registers (see 45.2.3.38 and 45.2.3.39).;
Change 30.5.1.1.14, 30.5.1.1.15, and 30.5.1.1.16 for FEC as follows:
30.5.1.1.14 aFECmode
ATTRIBUTE
APPROPRIATE SYNTAX:
A ENUMERATION that meets the requirement of the description below
unknown initializing, true state not yet known
disabled FEC disabled
enabled FEC enabled
BEHAVIOUR DEFINED AS:
A read-write value that indicates the mode of op eration of the optional FEC sublayer for forward
error correction (see 65.2 and Clause 74). 
A GET operation returns the current mode of operation of the PHY. A SET operation changes the
mode of operation of the PHY to the indicated value. When Clause 73 Auto-Negotiation is enabled
a SET operation is not allowed and a GET operation maps to the variable FEC enabled in
Clause 74.
If a Clause 45 MDIO Interface to the PCS is present, then this attribute will map to the FEC control
register (see 45.2.7.3) for 1000BASE-PX or FEC enable bit in 10G
BASE-R FEC control register
(see 45.2.1.86).;
30.5.1.1.15 aFECCorrectedBlocks
ATTRIBUTE
APPROPRIATE SYNTAX:
A SEQUENCE of generalized  Generalized  nonresetable counters . This Each counter has a
maximum increment rate of 1 200 000 counts per second for 1000 Mb/s implementations, and
5 000 000 counts per second for 10 Gb/s and 40 Gb/s  implementations, and 2 500 000 counts per
second for 100 Gb/s implementations.
BEHAVIOUR DEFINED AS:
For 1000BASE-PX PHYs or 10/40/100GBASE-R PHYs, a count an array of corrected FEC blocks
counters. The counters will not increm ent for other PHY types. The indices of this array (0 to
N – 1) denote the PCS lane number where N is the number of PCS lanes in use. The number of
PCS lanes in use is set to one for PHYs that do not use PCS lanes. Each element of this array
contains a count of corrected FEC blocks for that PCS lane.

---
<!-- Page 38 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
14 Copyright © 2010 IEEE. All rights reserved.
Increment the counter by one for each received block that is corrected by the FEC function in the
PHY for the corresponding lane.
If a Clause 45 MDIO Interface to the PCS is present, then this attribute will map to the FEC
corrected blocks counter(s) (see 45.2.8.5, and 45.2.1.87, and 45.2.1.89).;
30.5.1.1.16 aFECUncorrectableBlocks
ATTRIBUTE
APPROPRIATE SYNTAX:
A SEQUENCE of generalized  Generalized  nonresetable counters . This Each counter has a
maximum increment rate of 1 200 000 counts per second for 1000 Mb/s implementations, and
5 000 000 counts per second for 10 Gb/s and 40 Gb/s implementations, and 2 500 000 counts per
second for 100 Gb/s implementations.
BEHAVIOUR DEFINED AS:
For 1000BASE-PX PHYs or 10/40/100 GBASE-R PHYs, a count  an array of uncorrectable FEC
blocks counters. The counters will not increment for other PHY types. The indices of this array (0
to N – 1) denote the PCS lane number where N is the number of PCS lanes in use. The number of
PCS lanes in use is set to one for PHYs that do not use PCS lanes. Each element of this array
contains a count of uncorrectable FEC blocks for that PCS lane.
Increment the counter by one for each FEC block that is determined to be uncorrectable by the FEC
function in the PHY for the corresponding lane.
If a Clause 45 MDIO Interface to the PCS is present, then this attribute will map to the FEC
uncorrectable blocks counter(s)
 (see 45.2.8.6, and 45.2.1.88, and 45.2.1.90).;
Change 30.6.1.1.5 for autoneg ability and FEC request as follows:
30.6.1.1.5 aAutoNegLocalTechnologyAbility
ATTRIBUTE
APPROPRIATE SYNTAX:
A SEQUENCE that meets the requirements of the description below:
global Reserved for future use
other See 30.2.5
unknown Initializing, true state or type not yet known
10BASE-T 10BASE-T half duplex as defined in Clause 14
10BASE-TFD Full duplex 10BASE-T as defined in Clause 14 and Clause 31
100BASE-T4 100BASE-T4 half duplex as defined in Clause 23
100BASE-TX 100BASE-TX half duplex as defined in Clause 25
100BASE-TXFD Full duplex 100BASE-TX as defined in Clause 25 and Clause 31
FDX PAUSE PAUSE operation for full duplex links as defined in Annex 31B
FDX APAUSE Asymmetric PAUSE operation for full duplex links as defined in Clause 37,
Annex 28B, and Annex 31B
FDX SPAUSE Symmetric PAUSE operation for full duplex links as defined in Clause 37,
Annex 28B, and Annex 31B
FDX BPAUSE Asymmetric and Symmetric PAUSE operation for full duplex links as defined
in Clause 37, Annex 28B, and Annex 31B
100BASE-T2 100BASE-T2 half duplex as defined in Clause 32

---
<!-- Page 39 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 15
100BASE-T2FD Full duplex 100BASE-T2 as defined in Clause 31 and Clause 32
1000BASE-X 1000BASE-X half duplex as specified in Clause 36
1000BASE-XFD  Full duplex 1000BASE-X as specified in Clause 31 and Clause 36
1000BASE-T 1000BASE-T half duplex UTP
 PHY as specified in Clause 40
1000BASE-TFD Full duplex 1000BASE-T UTP  PHY as specified in Clause 31 and as specified
in Clause 40
Rem Fault1 Remote fault bit 1 (RF1) as specified in Clause 37
Rem Fault2 Remote fault bit 2 (RF2) as specified in Clause 37
10GBASE-T 10GBASE-T PHY as  specified in Clause 55
1000BASE-KXFD Full duplex 1000BASE-KX as specified in Clause 70
10GBASE-KX4FD Full duplex 10GBASE-KX4 as specified in Clause 71
10GBASE-KRFD Full duplex 10GBASE-KR as specified in Clause 72
40GBASE-KR4
40GBASE-KR4 as specified in Clause 84
40GBASE-CR4 40GBASE-CR4 as specified in Clause 85
100GBASE-CR10 100GBASE-CR10 as specified in Clause 85
Rem Fault Remote fault bit (RF) as specified in Clause 73
FEC Capable FEC ability as specified in Clause 73
 (see 73.6.5) and Clause 74
FEC Requested FEC requested as specified in Clause 73 (see 73.6.5) and Clause 74
isoethernet IEEE Std 802.9 ISLAN-16T
BEHAVIOUR DEFINED AS:
This indicates the technology ability of the local device, as defined in Clause 28, and Clause 37, 
and Clause 73.

---
<!-- Page 40 -->
---



---
<!-- Page 41 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 17
45. Management Data Input/Output (MDIO) Interface
Change the indicated rows of Table 45–1 and Table 45–2 for new MMDs as follows:
45.2 MDIO Interface Registers 
Change 45.2.1 for the general description of MMD 1, 8, 9, and 10 as follows:
45.2.1 PMA/PMD registers
For devices operating at 40 Gb/s or higher speeds, the PMA may be instantiated as multiple sublayers (see
83.1.4 for how MMD addresses are allocated to multiple PMA sublayers). A PMA sublayer that is packaged
with the PMD is addressed as MMD 1. More addressable instances of PMA sublayers, each one separated
Table 45–1—MDIO Manageable Device addresses
Device address MMD name
... ...
8 Separated PMA (1)
9 Separated PMA (2)
10 Separated PMA (3)
11 Separated PMA (4)
812 through 28 Reserved
... ...
Table 45–2—Devices in package registers bit definitions
Bit(s)a
am = Address of MMD accessed (see Table 45–1).
Name Description R/Wb
bRO = Read only.
...
m.5.15:812 Reserved Ignore on read RO
m.5.11 Separated PMA (4) 
present
1 = Separated PMAc (4) present in package
0 = Separated PMA (4) not present in package
cSeparated PMAs are defined in 45.2.1.
RO
m.5.10 Separated PMA (3) 
present
1 = Separated PMA (3) present in package
0 = Separated PMA (3) not present in package
RO
m.5.9 Separated PMA (2) 
present
1 = Separated PMA (2) present in package
0 = Separated PMA (2) not present in package
RO
m.5.8 Separated PMA (1) 
present
1 = Separated PMA (1) present in package
0 = Separated PMA (1) not present in package
RO
...

---
<!-- Page 42 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
18 Copyright © 2010 IEEE. All rights reserved.
from lower addressable instances, may be implemented and addressed as MMD 8, 9, 10, and 11 where
MMD 8 is the closest to the PMD and MMD 11 is the furthest from the PMD. The addresses and functions
of all registers in MMD 8, 9, 10 and 11 are defined identically to MMD 1, excep t registers m.5 and m.6 as
defined in Table 45–2.
The assignment of registers in the PMA/PMD is shown in Table 45–3.
Change the indicated rows of Table 45–3 (as modifi ed by IEEE Std 802.3av) for 40 Gb/s and 100 Gb/s
registers as follows:
Table 45–3—PMA/PMD registers
Register address Register name Clause
1.0 PMA/PMD control 1 45.2.1.1
1.1 PMA/PMD status 1 45.2.1.2
1.2, 1.3 PMA/PMD device identifier 45.2.1.3
1.4 PMA/PMD speed ability 45.2.1.4
1.5, 1.6 PMA/PMD devices in package 45.2.1.5
1.7 PMA/PMD control 2 45.2.1.6
1.8 10G PMA/PMD status 2 45.2.1.7
1.9 10G PMA/PMD transmit disable 45.2.1.8
1.10 10G PMD receive signal detect 45.2.1.9
1.11 10G PMA/PMD extended ability register 45.2.1.10
1.12 10G-EPON PMA/PMD P2MP ability register 45.2.1.11
1.13 40G/100G PMA/PMD extended ability register 45.2.1.11a
1.13 Reserved
1.14, 1.15 PMA/PMD package identifier 45.2.1.12
... ...
1.150 10GBASE-KR BASE-R PMD control 45.2.1.77
1.151 10GBASE-KR BASE-R PMD status 45.2.1.78
1.152 10GBASE-KR BASE-R LP coefficient update, lane 0 45.2.1.79
1.153 10GBASE-KR BASE-R LP status report, lane 0 45.2.1.80
1.154 10GBASE-KR BASE-R LD coefficient update, lane 0 45.2.1.81
1.155 10GBASE-KR BASE-R LD status report, lane 0 45.2.1.82
1.156 BASE-R PMD status 2 45.2.1.82a
1.157 BASE-R PMD status 3 45.2.1.82b
1.1568 through 1.159 Reserved
1.160 1000BASE-KX control 45.2.1.83
1.161 1000BASE-KX status 45.2.1.84
1.162 through 1.169 Reserved
1.170 10GBASE-R FEC ability 45.2.1.85
1.171 10GBASE-R FEC control 45.2.1.86
1.172 through 1.173 10GBASE-R FEC corrected blocks counter 45.2.1.87

---
<!-- Page 43 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 19
45.2.1.1 PMA/PMD control 1 register (Register 1.0)
Change Table 45–4 for 40 Gb/s and 100 Gb/s speed selection as follows:
Change 45.2.1.1.3 for 40 Gb/s and 100 Gb/s speed selection:
45.2.1.1.3 Speed selection (1.0.13,1.0.6, 1.0.5:2)
For devices operating at 10 Mb/s
, 100 Mb/s , or 1000 Mb/s the speed of the PMA/PMD may be selected
using bits 13 and 6. The speed abilities of the PMA/PMD are advertised in the PMA/PMD speed ability reg-
ister. These two bits use the same definition as the speed selection bits defined in Clause 22.
1.174 through 1.175 10GBASE-R FEC uncorrected blocks counter 45.2.1.88
1.176 through 1.299 Reserved
1.300 through 1.339 BASE-R FEC corrected blocks counter, lanes 0 through 19 45.2.1.89
1.340 through 1.699 Reserved
1.700 through 1.739 BASE-R FEC uncorrected blocks counter, lanes 0 through 19 45.2.1.90
1.740 through 1.1099 Reserved
1.1100 BASE-R LP coefficient update, lane 0 (copy) 45.2.1.79
1.1101 through 1.1109 BASE-R LP coefficient update, lanes 1 through 9 45.2.1.91
1.1110 through 1.1199 Reserved
1.1200 BASE-R LP status report, lane 0 (copy) 45.2.1.80
1.1201 through 1.1209 BASE-R LP status report, lanes 1 through 9 45.2.1.92
1.1210 through 1.1299 Reserved
1.1300 BASE-R LD coefficient update, lane 0 (copy) 45.2.1.81
1.1301 through 1.1309 BASE-R LD coefficient update, lanes 1 through 9 45.2.1.93
1.1310 through 1.1399 Reserved
1.1400 BASE-R LD status report, lane 0 (copy) 45.2.1.82
1.1401 through 1.1409 BASE-R LD status report, lanes 1 through 9 45.2.1.94
1.1410 through 1.1499 Reserved
1.1500 Test pattern ability 45.2.1.95
1.1501 PRBS pattern testing control 45.2.1.96
1.1502 through 1.1509 Reserved
1.1510 Square wave testing control 45.2.1.97
1.1511 through 1.1599 Reserved
1.1600 through 1.1609 PRBS Tx error counters, lane 0 through lane 9 45.2.1.98
1.1610 through 1.1699 Reserved
1.1700 through 1.1709 PRBS Rx error counters, lane 0 through lane 9 45.2.1.99
1.1761710 through 1.32 767 Reserved
Table 45–3—PMA/PMD registers  (continued)
Register address Register name Clause

---
<!-- Page 44 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
20 Copyright © 2010 IEEE. All rights reserved.
For devices not operating at 10 Mb/s, 100 Mb/s, or 1000 Mb/s, the speed of the PMA/PMD may be selected
using bits 5 through 2. When bits 5 through 2 are set to 0000 the use of a 10G PMA/PMD is selected. More
specific selection is performed using the PMA/PMD control 2 register (Register 1.7) (see 45.2.1.6). The
speed abilities of the PMA/PMD are advertised in the PMA/PMD speed ability register. A PMA/PMD may
ignore writes to the PMA/PMD speed selection bits that select speeds it has not advertised in the PMA/PMD
speed ability register. It is the responsibility of the STA entity to ensure that mu tually acceptable speeds are
applied consistently across all the MMDs on a particular PHY .
The PMA/PMD speed selection defaults to a supported ability.
When set to 0001, bits 5:2 select the use of the 10PASS-TS or 2BASE-TL PMA/PMD. More specific mode
selection is performed using the 10P/2B PMA control register (45.2.1.12).
Table 45–4—PMA/PMD control 1 register bit definitions
Bit(s) Name Description R/Wa
1.0.15 Reset 1 = PMA/PMD reset
0 = Normal operation
R/W
SC
1.0.14 Reserved Value always 0, writes ignored R/W
1.0.13 Speed selection (LSB) 1.0.6 1.0.13
1 1 = bits 5:2 select speed
1 0 = 1000 Mb/s
0 1 = 100 Mb/s
00 =  1 0  M b / s
R/W
1.0.12 Reserved Value always 0, writes ignored R/W
1.0.11 Low power 1 = Low-power mode
0 = Normal operation
R/W
1.0.10:7 Reserved Value always 0, writes ignored R/W
1.0.6 Speed selection (MSB) 1.0.6
1.0.13
1 1 = bits 5:2 select speed
1 0 = 1000 Mb/s
0 1 = 100 Mb/s
00 =  1 0  M b / s
R/W
1.0.5:2 Speed selection 5
 4 3 2
1xxx=  R e s e r v e d
x1xx=  R e s e r v e d
x x 1 x = Reserved
0 0 1 1 = 100 Gb/s
0 0 1 0 = 40 Gb/s
0001=  1 0 P A S S - T S / 2 B A S E - T L
0000=  1 0 G b / s
R/W
1.0.1 Reserved Value always 0, writes ignored R/W
1.0.1 PMA remote loopback 1 = Enable PMA remote loopback mode
0 = Disable PMA remote loopback mode
R/W
1.0.0 PMA local  loopback 1 = Enable PMA local  loopback mode
0 = Disable PMA local loopback mode
R/W
aR/W = Read/Write, SC = Self-clearing

---
<!-- Page 45 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 21
When bits 5 through 2 are set to 0010 the use of a 40G PMA/PMD is selected; when set to 0011 the use of a
100G PMA/PMD is selected. More sp ecific selection is performed using the PMA/PMD control 2 register
(Register 1.7) (see 45.2.1.6.1).
Insert the following new subclause before 45.2.1.1.4:
45.2.1.1.3a PMA remote loopback (1.0.1)
The PMA shall be placed in a remote loopback mode of operation when bit 1.0.1 is set to a one. When bit
1.0.1 is set to a one, the PMA shall accept data on the receive path and return it on the transmit path.
The remote loopback function is optional for all port types, except 2BASE-TL and 10PASS-TS, which do
not support loopback. A device’s ability to perform the remote loopback function is advertised in the remote
loopback ability bit of the related speed-dependent status register. A PMA that is unable to perform the
remote loopback function shall ignore writes to this bit and shall return a value of zero when read. For
40/100 Gb/s operation, the remote loopback functionality is detailed in 83.5.9. For 40/100 Gb/s operation,
the remote loopback ability bit is specified in the 40G/100G PMA/PMD extended ability register.
The default value of bit 1.0.1 is zero.
Change 45.2.1.1.4 (as modified by IEEE Std 802.3av) to distinguish from remote loopback as follows:
45.2.1.1.4 PMA local
 loopback (1.0.0)
The PMA shall be placed in a local loopback mode of operation when bit 1.0.0 is set to a one. When bit 1.0.0
is set to a one, the PMA shall accept data on the transmit path and return it on the receive path.
The local  loopback function is mandatory for the 1000BASE-KX, 10GBASE-KR, and  10GBASE-X,
40GBASE-KR4, 40GBASE-CR4 , and 100GBASE-CR10  port type and optional for all other port types,
except 2BASE-TL, 10PASS-TS and 10/1GBASE-PRX, which do not support loopback. A device’s ability to
perform the local loopback function is advertised in the local loopback ability bit of the related speed-depen-
dent status register. A PMA that is unable to perform the local loopback function shall ignore writes to this
bit and shall return a value of zero wh en read. For 10 Gb/s operation, the local loopback functionality is
detailed in 48.3.3 and 51.8, and . For 40/100 Gb/s operation, the local loopback functionality is detailed in
83.5.8. For 10/40/100 Gb/s operation, the local loopback ability bit is specified in the 10G PMA/PMD status
2 register.
The default value of bit 1.0.0 is zero.
NOTE—The signal path through th e PMA that is exercised in the loopback mode of operation is  implementation spe-
cific, but it is recommended that the signal path encompass as much of the PMA circuitry as is practical. The intention of
providing this loopback mode of operation is to permit a diagnostic or self-test function to perform the transmission and
reception of a PDU, thus testing the transmit and receive data paths. Other loopback signal paths may be enabled using
loopback controls within other MMDs.

---
<!-- Page 46 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
22 Copyright © 2010 IEEE. All rights reserved.
Change the indicated rows of Table 45–6 (as modifi ed by IEEE Std 802.3av) for 40 Gb/s and 100 Gb/s
speed ability:
Change 45.2.1.2.1 for 10/40/100 Gb/s as follows:
45.2.1.2.1 Fault (1.1.7)
Fault is a global PMA/PMD variable. When read as a one, bit 1.1.7 indicates that either (or both) the PMA or
the PMD has detected a fault condition on either the transmit or receive paths. When read as a zero, bit 1.1.7
indicates that neither the PMA nor the PMD has detected a fault condition. For 10/40/100
Gb/s operation, bit
1.1.7 is set to a one when either of the fault bits (1.8.1 1, 1.8.10) located in register 1.8 are set to a one. For
10PASS-TS or 2BASE-TL operations, when read as a one, a fault has been detected and more detailed infor-
mation is conveyed in 45.2.1.16, 45.2.1.39, 45.2.1.40, and 45.2.1.55.
Insert 45.2.1.4.a and 45.2.1.4.b before 45.2.1.4.1 (inserted by IEEE Std 802.3av) as follows:
45.2.1.4.a 100G capable (1.4.9)
When read as a one, bit 1. 4.9 indicates that the PMA/PMD is able to operate at a data rate of 100 Gb/s.
When read as a zero, bit 1.4.9 indicates that the PMA/PMD is not able to operate at a data rate of 100 Gb/s.
45.2.1.4.b 40G capable (1.4.8)
When read as a one, bit 1.4.8 indicates that the PMA/PMD is able to operate at a data rate of 40 Gb/s. When
read as a zero, bit 1.4.8 indicates that the PMA/PMD is not able to operate at a data rate of 40 Gb/s.
Table 45–6—PMA/PMD speed abilit y register bit definitions
Bit(s) Name Description R/Wa
aRO = Read only
1.4.15:8
1.4.15:10
Reserved for future speeds Valu e always 0, writes ignored RO
1.4.9 100G capable 1 = PMA/PMD is capable of operating at 100 Gb/s
0 = PMA/PMD is not capable of operating as 100 Gb/s
RO
1.4.8 40G capable 1 = PMA/PMD is capable of operating at 40 Gb/s
0 = PMA/PMD is not capable of operating as 40 Gb/s
RO

---
<!-- Page 47 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 23
Change Table 45–7 (as modified by IEEE Std 802.3av) for 40 Gb/s and 100 Gb/s PMA/PMD type
selections:
Table 45–7—PMA/PMD control 2 register bit definitions
Bit(s) Name Description R/Wa
aR/W = Read/Write
1.7.15:5
1.7.15:6
Reserved Value always 0, writes ignored R/W
1.7.4:0
1.7.5:0
PMA/PMD type selection 5 4 3 2 1 0
1 1 x x x x = reserved for future use
1 0 1 1 x x = reserved for future use
1 0 1 0 1 1 = 100GBASE-ER4 PMA/PMD type
1 0 1 0 1 0 = 100GBASE-LR4 PMA/PMD type
1 0 1 0 0 1 = 100GBASE-SR10 PMA/PMD type
1 0 1 0 0 0 = 100GBASE-CR10 PMA/PMD type
1 0 0 1 x x = reserved for future use
1 0 0 0 1 1 = 40GBASE-LR4 PMA/PMD type
1 0 0 0 1 0 = 40GBASE-SR4 PMA/PMD type
1 0 0 0 0 1 = 40GBASE-CR4 PMA/PMD type
1 0 0 0 0 0 = 40GBASE-KR4 PMA/PMD type
0 1 1 1 x x = reserved
0 1 1 0 1 1 = reserved
0 1 1 0 1 0 = 10GBASE-PR-U3
0 1 1 0 0 1 = 10GBASE-PR-U1
0 1 1 0 0 0 = 10/1GBASE-PRX-U3
0 1 0 1 1 1 = 10/1GBASE-PRX-U2
0 1 0 1 1 0 = 10/1GBASE-PRX-U1
0 1 0 1 0 1 = 10GBASE-PR-D3
0 1 0 1 0 0 = 10GBASE-PR-D2
0 1 0 0 1 1 = 10GBASE-PR-D1
0 1 0 0 1 0 = 10/1GBASE-PRX-D3
0 1 0 0 0 1 = 10/1GBASE-PRX-D2
0 1 0 0 0 0 = 10/1GBASE-PRX-D1
0 0 1 1 1 1 = 10BASE-T PMA/PMD type
0 0 1 1 1 0 = 100BASE-TX PMA/PMD type
0 0 1 1 0 1 = 1000BASE-KX PMA/PMD type
0 0 1 1 0 0 = 1000BASE-T PMA/PMD type
0 0 1 0 1 1 = 10GBASE-KR PMA/PMD type
0 0 1 0 1 0 = 10GBASE-KX4 PMA/PMD type
0 0 1 0 0 1 = 10GBASE-T PMA type
0 0 1 0 0 0 = 10GBASE-LRM PMA/PMD type
0 0 0 1 1 1 = 10GBASE-SR PMA/PMD type
0 0 0 1 1 0 = 10GBASE-LR PMA/PMD type
0 0 0 1 0 1 = 10GBASE-ER PMA/PMD type
0 0 0 1 0 0 = 10GBASE-LX4 PMA/PMD type
0 0 0 0 1 1 = 10GBASE-SW PMA/PMD type
0 0 0 0 1 0 = 10GBASE-LW PMA/PMD type
0 0 0 0 0 1 = 10GBASE-EW PMA/PMD type
0 0 0 0 0 0 = 10GBASE-CX4 PMA/PMD type
R/W

---
<!-- Page 48 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
24 Copyright © 2010 IEEE. All rights reserved.
Change 45.2.1.6.1 for 40 Gb/s and 100 Gb/s PMA/PMD type selections as follows:
45.2.1.6.1 PMA/PMD type selection (1.7.35:0)
The PMA/PMD type of the PMA/PMD shall be selected using bits 35 through 0. The PMA/PMD type abili-
ties of the PMA/PMD are advertised in bits 9 and 7 through 0 of the PMA/PMD status 2 register;  and bits 8
through 0 of the PMA/PMD extended ability register; and the 40G/100G PMA/PMD extended ability regis-
ter. A PMA/PMD shall ignore writes to the PMA/PMD type selection bits that select PMA/PMD types it has
not advertised in the PMA/PMD status 2 register . It is the responsibility of the STA entity to ensure that
mutually acceptable MMD types are applied consistently across all the MMDs on a particular PHY .
The PMA/PMD type selection defaults to a supported ability.
Change 45.2.1.7 and change the indicated row of Table 45–8 for naming as follows:
45.2.1.7 10G PMA/PMD status 2 register (Register 1.8)
The assignment of bits in the 10G  PMA/PMD status 2 register is shown in Table 45–8. All the bits in the
10G PMA/PMD status 2 register are read only; a write to the 10G PMA/PMD status 2 register shall have no
effect.
Change 45.2.1.7.4 and 45.2.1.7.5 as follows:
45.2.1.7.4 Transmit fault (1.8.11)
When read as a one, bit 1.8.11 indicates that the PMA/PMD has det ected a fault condition on the transmit
path. When read as a zero, bit 1.8. 11 indicates that the PMA/PMD has no t detected a fault condition on the
transmit path. Detection of a fault condition on the transm it path is optional and the ability to detect such a
condition is advertised by bit 1.8.13. A PMA/PMD that is unable to detect a fault condition on the transmit
path shall return a value of zero for this bit. The description of the transmit fault function for the 10GBASE-
KR PMD is given in 72.6.8, for 10GBASE-LRM serial PMDs in 68.4.8, and for other serial PMDs in 52.4.8.
The description of the transmit fault function for WWDM PMDs is given in 53.4.10. The description of the
transmit fault function for the 10GBASE-CX4 PMD is given in 54.5.10. The description of the transmit fault
function for the 10GBASE-T PMA is given in 55.4.2.2. The description of the transmit fault function for the
10GBASE-KX4 PMD is given in 71.6.10. The descriptio n of the transmit fault function for the 40GBASE-
KR4 PMD is given in 84.7.10. The description of the transmit fault function for the 40GBASE-CR4 and
100GBASE-CR10 PMDs is given in 85.7.10. The description of the transmit fault function for the
40GBASE-SR4 and 100GBASE-SR10 PMDs is given in 86.5.10. The description of the transmit fault func-
tion for the 40GBASE-LR4 PMD  is given in 87.5.10. The description of the transmit fault function for the
100GBASE-LR4 and 100GBASE-ER4 PMDs is given in 88.5.10. The transmit fault bit shall be imple-
mented with latching high behavior.
The default value of bit 1.8.11 is zero.
Table 45–8—10G  PMA/PMD status 2 register bit definitions
Bit(s) Name Description R/Wa
aRO = Read only, LH = Latching high
1.8.0 PMA local  loopback ability 1 = PMA has the ability to perform a local  loopback function
0 = PMA does not have the ability to perform a local loop-
back function
RO

---
<!-- Page 49 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 25
45.2.1.7.5 Receive fault (1.8.10)
When read as a one, bit 1.8.10 indicates that th e PMA/PMD has detected a fault condition on the receive
path. When read as a zero, bit 1.8. 10 indicates that the PMA/PMD has not detected a fault condition on the
receive path. Detection of a fault condition on the receive  path is optional and the ability to detect such a
condition is advertised by bit 1.8.12. A PMA/PMD that is unable to  detect a fault condition on the receive
path shall return a value of zero for this bit. The description of the receive fault function for the 10GBASE-
KR PMD is given in 72.6.9, for 10GBASE-LRM serial PMDs in 68.4.9, and for other serial PMDs in 52.4.9.
The description of the receive fault function for WWDM PMDs is given in 53.4.11. The description of the
receive fault function for the 10GBAS E-CX4 PMD is given in 54.5.11. Th e description of the receive fault
function for the 10GBASE-T PMA is gi ven in 55.4.2.4. The description of the receive fau lt function for the
10GBASE-KX4 PMD is given in 71.6 .11. The description of the recei ve fault function for the 40GBASE-
KR4 PMD  is given in 84.7.11. The description of the receive fa ult function for the 40GBASE-CR4 and
100GBASE-CR10 PMDs is given in 85.7.11. The description of the recei ve fault func tion for the
40GBASE-SR4 and 100GBASE-SR10 PMDs is given in 86.5.11. The description of the receive fault func-
tion for the 40GBASE-LR4 PMD  is given in 87.5.11. The description of the r eceive fault function for the
100GBASE-LR4 and 100GBASE-ER4 PMDs is given in 88.5.11. The receive fault bit shall be implemented
with latching high behavior.
Change 45.2.1.7.15 for local loopback as follows:
45.2.1.7.15 PMA local loopback ability (1.8.0)
When read as a one, bit 1.8.0 indicates that the PMA is able to perform the local  loopback function. When
read as a zero, bit 1.8.0 indicates that the PMA is not able to perform the local loopback function. If a PMA
is able to perform the local loopback function, then it is controlled using the PMA local loopback bit 1.0.0.
Change 45.2.1.8 for 40 Gb/s and 100 Gb/s PMA/PMD transmit disable as follows:
45.2.1.8 10G
 PMD transmit disable register (Register 1.9)
The assignment of bits in the 10G PMD transmit disable register is shown in Table 45–9. The transmit
disable functionality is optional and a PMD’s ability to perform the transmit disable functionality is
advertised in the PMD transmit disable ability bit 1.8.8. A PMD that does not implement the transmit disable
functionality shall ignore writes to the 10G PMD transmit disable register and may return a value of zero for
all bits. A PMD device that operates using a single wavelength  lane  and has implemented the transmit
disable function shall use bit 1.9.0 to control the func tion. Such devices shall ignore writes to bits 1.9.4 10:1
and return a value of zero for those bits when they are read. The transmit disable function for the 10GBASE-
KR PMD is described in 72.6.5, for 10GBASE-LRM seri al PMDs in 68.4.7, and for other serial PMDs in
52.4.7. The transmit disable function for wide wavelength division multiplexing (WWDM) PMDs  the
10GBASE-LX4 PMD is described in 53.4.7. The transmit disable function for the 10GBASE-CX4 PMD is
described in 54.5.6. The transmit disable function fo r 10GBASE-KX4 is described in 71.6.6. The transmit
disable function for the 10GBASE-T PMA is describe d in 55.4.2.3. The transmit disable function for
40GBASE-KR4 is described in 84.7.6. The transmit disable function for 40GBASE-CR4 and 100GBASE-
CR10 is described in 85.7.6. The transmit disable function for 40GBASE-SR4 and 100GBASE-SR10 is
described in 86.5.7. The transmit disable function for 40GBASE-LR4 is described in 87.5.7. The transmit
disable function for 100GBASE-LR4 and 100GBASE-ER4 is described in 88.5.7.
NOTE—Disabling the transmitter on one or more lanes stops the entire link from carrying data .

---
<!-- Page 50 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
26 Copyright © 2010 IEEE. All rights reserved.
Change the indicated rows of Table 45–9 for 10 lane transmit disables as follows:
Insert two new subclauses before 45.2.1.8.1 for 10 lane transmit disable as follows:
45.2.1.8.a PMD transmit disable 9 (1.9.10)
When bit 1.9.10 is set to a one, the PMD shall disable output on lane 9 of the transmit path. When bit 1.9.10
is set to zero, the PMD shall enable output on lane 9 of the transmit path.
The default value for bit 1.9.10 is zero.
NOTE—Transmission will not be enabled when this bit is set to zero unless the global PMD transmit disable bit is also
zero.
45.2.1.8.b PMD transmit disable 4, 5, 6, 7, 8 (1.9.5, 1.9.6, 1.9.7, 1.9.8, 1.9.9)
These bits are defined similarly to bit 1.9.10 for lanes 4, 5, 6, 7, and 8, respectively.
Change 45.2.1.9 for 40 Gb/s and 100 Gb/s PMA/PMD signal detect as follows:
45.2.1.9 10G PMD receive signal detect register (Register 1.10)
The assignment of bits in the 10G PMD receive signal detect register is shown in Tabl e 45–10. The 10G
PMD receive signal detect register is mandatory. PMD types that use only a single wavelength  lane indicate
the status of the receive signal de tect using bit 1.10.0 and return a value of zero for bits 1.10.4:1 10:1 PMD
types that use multiple wavelengths or lanes indicate the status of each lane in bits 1.10.4:110:1 and the log-
ical AND of those bits in bit 1.10.0.
Table 45–9—10G PMD transmit disable register bit definitions
Bit(s) Name Description R/Wa
aR/W = Read/Write
1.9.15:511 Reserved Value always 0, writes ignored R/W
1.9.10 PMD transmit disable 9 1 = Disable output on transmit lane 9
0 = Enable output on transmit lane 9
R/W
1.9.9 PMD transmit disable 8 1 = Disable output on transmit lane 8
0 = Enable output on transmit lane 8
R/W
1.9.8 PMD transmit disable 7 1 = Disable output on transmit lane 7
0 = Enable output on transmit lane 7
R/W
1.9.7 PMD transmit disable 6 1 = Disable output on transmit lane 6
0 = Enable output on transmit lane 6
R/W
1.9.6 PMD transmit disable 5 1 = Disable output on transmit lane 5
0 = Enable output on transmit lane 5
R/W
1.9.5 PMD transmit disable 4 1 = Disable output on transmit lane 4
0 = Enable output on transmit lane 4
R/W

---
<!-- Page 51 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 27
Change the indicated rows of Table 45–10 for 10 lane signal detect as follows:
Insert two new subclauses before 45.2.1.9.1 for 10 lane signal detect as follows:
45.2.1.9.a PMD receive signal detect 9 (1.10.10)
When bit 1.10.10 is read as a one, a signal has been detected on lane 9 of the PMD receive path. When bit
1.10.10 is read as a zero, a signal has not been detected on lane 9 of the PMD receive path.
45.2.1.9.b PMD receive signal detect 4, 5, 6, 7, 8 (1.10.5, 1.10.6, 1.10.7, 1.10.8, 1.10.9)
These bits are defined similarly to bit 1.10.10 for lanes 4, 5, 6, 7, and 8, respectively.
Table 45–10—10G  PMD receive signal detect register bit definitions
Bit(s) Name Description R/Wa
aRO = Read only
1.10.15:511 Reserved Value always 0, writes ignored RO
1.10.10 PMD receive signal detect 9 1 = Signal detected on receive lane 9
0 = Signal not detected on receive lane 9
RO
1.10.9 PMD receive signal detect 8 1 = Signal detected on receive lane 8
0 = Signal not detected on receive lane 8
RO
1.10.8 PMD receive signal detect 7 1 = Signal detected on receive lane 7
0 = Signal not detected on receive lane 7
RO
1.10.7 PMD receive signal detect 6 1 = Signal detected on receive lane 6
0 = Signal not detected on receive lane 6
RO
1.10.6 PMD receive signal detect 5 1 = Signal detected on receive lane 5
0 = Signal not detected on receive lane 5
RO
1.10.5 PMD receive signal detect 4 1 = Signal detected on receive lane 4
0 = Signal not detected on receive lane 4
RO

---
<!-- Page 52 -->
---

IEEE Std 802.3ba-2010 AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD
28 Copyright © 2010 IEEE. All rights reserved.
Change the indicated rows of Table 45–11 (as modified by IEEE Std 802.3av) in 45.2.1.10 for 40G/100G
extended abilities as follows:
45.2.1.10 PMA/PMD extended ability register (Register 1.11)
Insert new subclause 45.2.1.11a and 45.2.1.11a.1 th rough 45.2.1.11a.9 after existing subclause 45.2.1.11
(this subclause was renumbered by IEEE Std 802.3av):
45.2.1.11a 40G/100G PMA/PMD extended ability register (Register 1.13) 
The assignment of bits in the 40G/100G PMA/PMD extended ability register is shown in Table 45–12a. All
of the bits in the PMA/PMD extended ability register are read only; a write to the PMA/PMD extended abil-
ity register shall have no effect.
Table 45–11—PMA/PMD extended ability register bit definitions
Bit(s) Name Description R/Wa
aRO = Read only
1.11.15:1011 Reserved Ignore on read RO
1.11.10 40G/100G extended abilities 1 = PMA/PMD has 40G/100G extended abilities listed in 
register 1.13
0 = PMA/PMD does not have 40G/100G extended abilities
RO
Table 45–12a—40G/100G PMA/PMD extended  ability register bit definitions
Bit(s) Name Description R/Wa
aRO = Read only
1.13.15 PMA remote loopback 
ability
1 = PMA has the ability to perform a remote loopback function
0 = PMA does not have the ability to perform a remote loop-
back function
RO
1.13.14:12 Reserved Ignore on read RO
1.13.11 100GBASE-ER4 ability 1 = PMA/PMD is able to perform 100GBASE-ER4
0 = PMA/PMD is not able to perform 100GBASE-ER4
RO
1.13.10 100GBASE-LR4 ability 1 = PMA/PMD is able to perform 100GBASE-LR4
0 = PMA/PMD is not able to perform 100GBASE-LR4
RO
1.13.9 100GBASE-SR10 ab ility 1 = PMA/PMD is able to perform 100GBASE-SR10
0 = PMA/PMD is not able to perform 100GBASE-SR10
RO
1.13.8 100GBASE-CR10 ability 1 = PMA/PMD is able to perform 100GBASE-CR10
0 = PMA/PMD is not able to perform 100GBASE-CR10
RO
1.13.7:4 Reserved Ignore on read RO
1.13.3 40GBASE-LR4 ability 1 = PMA/PM D is able to perform 40GBASE-LR4
0 = PMA/PMD is not able to perform 40GBASE-LR4
RO
1.13.2 40GBASE-SR4 ability 1 = PMA/PMD is able to perform 40GBASE-SR4
0 = PMA/PMD is not able to perform 40GBASE-SR4
RO
1.13.1 40GBASE-CR4 ability 1 = PMA/PM D is able to perform 40GBASE-CR4
0 = PMA/PMD is not able to perform 40GBASE-CR4
RO
1.13.0 40GBASE-KR4 abilit y 1 = PMA/PMD is able to perform 40GBASE-KR4
0 = PMA/PMD is not able to perform 40GBASE-KR4
RO

---
<!-- Page 53 -->
---

AMENDMENT TO IEEE Std 802.3-2008: CSMA/CD IEEE Std 802.3ba-2010
Copyright © 2010 IEEE. All rights reserved. 29
45.2.1.11a.1 PMA remote loopback ability (1.13.15)
