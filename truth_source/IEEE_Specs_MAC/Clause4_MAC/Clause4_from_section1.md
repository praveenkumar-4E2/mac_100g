4. Media Access Control
4.1 Functional model of the MAC method
4.1.1 Overview
The architectural model described in Clause 1 is used in this clause to provide a functional description of the 
LAN 
CSMA/CD MAC sublayer.
The MAC sublayer defines a medium-independent facility, built on the medium-dependent physical facility 
provided by
 the Physical Layer, and under the access-layer-independent LAN LLC sublayer (or other MAC 
client). It is applicable to a general class of local area broadcast media suitable for use with the media access 
discipline known as Carrier Sense Multiple Access with Collision Detection (CSMA/CD).
The LLC sublayer and the MAC sublayer  togeth er are intended to have the same function as that described 
in the OSI model for the Data Link Layer alone. In a broadcast network, the notion of a data link between 
two network entities does not correspond directly to a distinct physical connection. Nevertheless, the parti -
tioning of functions presented in this standard requires tw o mai n functions generally associated with a data 
link control procedure to be performed in the MAC sublayer. They are as follows:
a) Data encapsulation (transmit and receive)
1) Framing (frame boundary deli mitation, frame synchronizatio n)
2) Addressing (handling of sour ce and destination addresses)
3)
Error detection (detection of physical medium transmission errors)
b) Media Access Management
1) Medium allocation (collision avoidance)
2) Contention resolution (collision handling)
An optional MAC control sublayer, architecturally positioned between LLC (or other M
 AC client) and the 
MAC, is specified in Clause 31. This MAC Control sublayer is transparent to both the underlying MAC and 
its client (typically LLC). The MAC sublayer operates independently  of its client; i.e., it is unaware whether 
the client is LLC or the MAC Control sublayer. This allows the MAC to be specified and implemented in 
one manner, whether or not the MAC Control sublayer is implemented. References to LLC as the MAC cli -
ent in text and figures apply equally to the MAC Cont rol sublayer, if implemented.
This standard provides for two modes of operation of the MAC sublayer:
a)
In half duplex mode, stations contend for the use of the physical medium, using the CSMA/CD algo-
rithms specified. Bidirectional communication is accomplished by rapid exchange of frames, rather 
than full duplex op
eration. Half duplex operation is possible on all supported media; it is required on 
those media that are incapable of supporting simultaneous transmission and reception without inter-
ference, for example, 10BASE2 and 100BASE-T4.
b) The full duplex m ode of operation can be used when all of the following are true:
1) The physical medium is capab le of supporting simultaneous transmis sion and reception with -
out interference (e.g., 10BASE-T, 10BASE-FL, and 100BASE-TX/FX).
2) There are exactly 
two stations on the LAN. This allow s the physical medium to be treated as a 
full duplex point-to-point link between the stations. Since there is no contention for use of a 
shared medium, the multiple access (i.e., CSMA/CD) algorithms are unnecessary.
3) Both stations on the LAN are capable of and have  been configured to use full
  duplex operation.
The most common configuration envisioned for full dup lex operation consi s ts of a central bridge (also 
known as a switch) with a dedicated LAN connecting each bridge port to a single device.

---
<!-- Page 130 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
56 Copyright © 2008 IEEE. All rights reserved.
The formal specification of the MAC in 4.2 comprises both the half duplex and full duplex modes of opera -
tion. The remainder of this clause provides a functional mo del of the CSMA/CD MAC method.
4.1.2 CSMA/CD operation
This subclause provides an overview of frame transmission and reception in terms of the functional model of 
the architecture. This overview is descriptive, rather than definitional; the formal specifications of the opera-
tions described here are given in 4.2 and 4.3. Specific implementations fo r CSMA/CD mechanisms that 
meet this standard are given in 4.
4. Figure 1–1 provides the architectural model described fu nctionally in the 
subclauses that follow.     
The Physical Layer Signaling (PLS) component of the Physical Layer provides an interface to the MAC sub-
layer for the serial transmission of bits onto th e physical m edia. For completeness, in the operational 
description that follows some of these functions are included as descriptive material. The concise specifica -
tion of these functions is given in 4.2 for the MAC functions and in Clause 7 for PLS.
Transmit frame operations are independent from the receive frame operatio ns. A transmitted frame 
addressed to the o
riginating station will be received and passed to the MAC client at that station. This char -
acteristic of the MAC sublayer may be implemented by functionality within the MAC sublayer or full 
duplex characteristics of portions 
of the lower layers.
4.1.2.1 Normal operation
4.1.2.1.
1 Transmission without contention
When a MAC client requests the transmission of a frame, the Tr ansmit Data Encapsulation component of the 
CSMA/CD MAC sublayer constructs the frame from the client-supplied data. It prepends a preamble and a 
Start Frame Delimiter to the beginni ng of the frame. Using information provided by the client, the CSMA/
CD MAC sublayer also appends a Pad at the end of the MAC information field of sufficient length to ensure 
that the transmitted frame length satisfi es a minimum frame-size requirement (see 4.2.3.3). It also prepends 
destination and source addresses, the length/type fiel d, and appends a fram e check sequence to provide for 
error detection. If the MAC supports the use of client-supplied frame check sequence values, then it shall use 
the client-supplied value, when present. If the use of client-supplied frame check sequence values is not sup-
ported, or if the client-supplied frame check sequence value is not presen t, then the MAC shall compute this 
value. The frame is then handed  to the Transmit Media Access Mana gement component in the MAC sub -
layer for transmission.
In half duplex mode, Transmit Media Access Management attempts to avoid conte ntion with other traffic on 
the medium by monitoring the carrier sense signal prov ided by the Physical La yer Signaling (PLS) compo-
nent and deferring to passing traffic. When the medium is clear, frame transmission is initiated (after a brief 
interframe delay to provide recovery time for other CSMA/CD MAC sublayers and for the physical 
medium). The MAC sublayer then provides a serial stream of bits to the Physical Layer for transmission.
In half duplex mode, at an operating speed of 1000 Mb /s, the minimum  frame size is insufficient to ensure 
the proper operation of the CSMA/CD protocol for the desired network topologies. To circumvent this prob-
lem, the MAC sublayer will append a sequence of  extension bits to frames which are less than slotTime bits 
in length so that the duration of the resulting transmission is sufficient to en sure proper operation of the 
CSMA/CD protocol.
In half duplex mode, at an operating speed of 1000 Mb/s, the CSMA/CD MAC may optionally transmit 
additional frames without
 relinquishing control of the transmission medium, up to a specified limit.
In full duplex mode, there is no need for Transmit Media Access Management to avoid contention with 
other tr
affic on the medium. Frame transmission may be initiated after the interframe delay, regardless of the 

---
<!-- Page 131 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 57
presence of receive activity. In fu ll duplex mode, the MAC sublayer does n ot perform either carrier exten -
sion or frame bursting.
The Physical Layer performs the task of generating the signals on the medium that represent the bits of the 
frame. Simultaneously, it monitors the medium and generates the collision detect signal, which in the con -
tention-free case under discussion, remains off for the duration of th e fram e. A functional description of the 
Physical Layer is given in Clause 7 and beyond.
When transmission has completed without contention, the CSMA/CD MAC sublayer so informs the MAC 
client and awaits the next request for frame transm
ission.
4.1.2.1.2 Reception without contention
At each receiving station, the arrival of a frame is  first detected by the Physical Layer, which responds by 
synchronizing with the incoming preamble, and by turning on the receiveDataValid signal. As the encoded 
bits arrive from the medium, they are decoded and tr anslated back into binary data. The Physical Layer 
passes subsequent bits up to the MAC sublayer, where the leading bits are discarded, up to and including the 
end of the preamble and Start Frame Delimiter.
Meanwhile, the Receive Media Access Management component of the MAC s ublayer
 , having observed 
receiveDataValid, has been waiting for the incoming bits to be delivered. Receive Media Access Manage -
ment collects bits from the Physical Layer entity as  long as the receiveDataValid sig nal remains on. When 
the receiveDataValid signal is removed, the frame is truncated to an octet boundary, if necessary, and passed 
to Receive Data Decapsulation for processing.
Receive Data Decapsulation checks the frame’s Destin ation Address field to decide whether the frame 
should be received by this station. 
If so, it passes the Destination Ad dress (DA), the Source Address (SA), 
the Length/Type, the Data and (optionally) the Fram e Check Sequence (FCS) fields to the MAC client, 
along with an appropriate status code, as defined in 4.3.2. It also checks for invalid MAC frames by inspect-
ing the frame check sequence to detect any damage to  the frame enrout e, and by checking for proper octet-
boundary alignment of the end of the frame. Frames with a valid FCS may also be checked for proper octet-
boundary alignment.
In half duplex mode, at an operating speed of 1000 Mb/s, frames may be extended by the transmitting station 
under the condit
ions described in 4.2.3.4. The extension is discarded by the MAC sublayer of the receiving 
station, as 
defined in the procedural model in 4.2.9.
4.1.2.2 Access interference and recovery
In half duplex mode, if multiple stations attempt to transmit at the same  time, it is possible for them to inter-
fere with each other’s transmissions, in spite of their attempts to a void this by deferring. When transmissions 
from two stations overlap, the resulting contention is called a collision. Collisions occur only in half duplex 
mode, where a collision indicates that there is more than one station attempting to use the shared physical 
medium. In full duplex mode, two stations may transmit to each other simultaneously without causing inter-
ference. The Physical Layer may generate a collision indication, b
 ut this is ignored by the full duplex MAC. 
A given station can experience a collision during  the in itial part of its transmission (the collision window) 
before its transmitted signal has had time to propaga te to all stations on the CSMA/CD medium. Once the 
collision window has passed, a transmitting station is said to have acquired the medium; subsequent colli -
sions are avoided since all other (properly functioning) stations can be assumed to have noticed the signal 
and to be deferri
ng to it. The time to acquire the medium is thus based on the round-trip propagation time of 
the Physical Layer whose elements include the PLS, PMA, and physical medium.

---
<!-- Page 132 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
58 Copyright © 2008 IEEE. All rights reserved.
In the event of a col lision, the transmitting station’s Physical Layer initially notices the interference on the 
medium and then turns on the collision detect signal. In half duplex mode, this is noticed in turn by the 
Transmit Media Access Management component of the MAC sublayer, and collision handling begins. First, 
Transmit Media Access Management enforces the collision by transmitting a bit sequence called jam. In 4.4, 
implementations that use this enforcemen t procedure are provided. This ensures that the duration of the col-
lision is sufficient to be noticed by the other transmitting station(s) invo lved in the collision. After the jam is 
sent, Transmit Media Access Management terminates the transmission and schedules another transmission 
attempt after a randomly selected time interval. Retransmission is attempted again in the face of repeated 
collisions. Since repeated collisions indicate a busy medium, however, Transmit Media Access Management 
attempts to adjust to the medium load by backing off (voluntarily delaying its own retransmissions to reduce 
its load on the medium). This is accomplished by expanding the interval from which the random retransmis-
sion time is selected on each successive transmit attempt. Eventually, either the transmission succeeds, or 
 the 
attempt is abandoned on the assumption that the medium has failed or has become overloaded.
In full duplex mode, a station ignores any collision detect signal generated by the Physical Layer. Transmit 
Media Access Management in a full duplex 
station will always be able to transmit its frames without conten-
tion, so there is never any need to jam or reschedule transmissions.
At the receiving end, the bits resu lting from a collision are received and decoded by the PLS just as are the 
bits of a valid frame. Fragmentar y frames received during collisi
ons are distinguished from valid transmis -
sions by the MAC sublayer’s Receive Media Access Management component.
4.1.
3 Relationships to the MAC client and Physical Layers
The CSMA/CD MAC sublayer provides services to the MAC client required for the transmis sion and recep-
tion of frames. Access to these services is specified in 4.3. The CSMA/CD MAC sublayer makes a best 
effort to acquire the medium and transfer a serial st ream of bits  to the Physical Layer. Although certain 
errors are reported to the client, error recovery is not provided by MAC. Error recovery may be provided by 
the MAC client or higher (sub)layers.
4.2 CSMA/CD Media Access Control (MAC) method: Precise specification
4.2.1 Introduction
A precise algorithmic definition is given in this s ubclause, providin g procedural model for the CSMA/CD 
MAC process with a program in the computer language Pascal. See references [B13] and [B24] for resource 
material. Note whenever there is any apparent ambigui ty concerning the d e finition of some aspect of the 
CSMA/CD MAC method, it is the Pascal procedural specification in 4.2.7 through 4.2.10 which should be 
consulted for the definitive statement. Subclauses 4.2.2 through 4.2.6 provide, in prose, a description of the 
access mechanism with the formal terminology to be used in the remaining subclauses.
4.
2.2 Overview of the procedural model
The functions of the CSMA/CD MAC method are presen ted be low, modeled as a program written in the 
computer language Pascal. This procedural model is intended as the primary specification of the functions to 
be provided in any CSMA/CD MAC sublayer implementation. It is important to distinguish, however, 
between the model and a real implementation. The model is optimized for simplicity and clarity of presenta-
tion, while any realistic implementati on shall place heavier emphasis on su ch constraints as efficiency and 
suitability to a particular implementation technology or  computer architecture. In this context, several 
important properties of the procedural model shall be considered.

---
<!-- Page 133 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 59
4.2.2.1 Ground rules for the procedural model
a) First, it shall be emphasized that the description of  the MAC sublayer in a computer language is in 
no way intended to imply that procedures shall be implemented as a program executed by a com -
puter. The implementati on may consist of any appropriate technology including hardware, firmware, 
software, or any combination.
b) Similarly, it shall be emphasized that it is the behavior of  any MAC sublayer implementations that 
shall match the standard, not their internal structure. The internal details of the procedural model are 
useful only to the extent that they help specify that behavior clearly and precisely.
c) The handling of incoming and outgoing frames is rather styli zed in the p r ocedural model, in the 
sense that frames are handled as single entities by most of the MAC sublayer and are only serialized 
for presentation to the Physical Layer. In realit y, many implementations will instead handle frames 
serially on a bit, octet or word basis. This appro ach has not been reflected in the procedural model, 
since this only complicates the description of the functions without changing them in any way.
d) The model consists of algorithms designed to be executed by a number of concurrent processes; 
these algorithms col
lectively implement the CSMA/CD procedure. The timing dependencies intro -
duced by the need for concurrent activity are resolv ed in two ways:
1) Processes Versus External Events.  It is assumed that the algo rithms are executed “very fast” 
relative to external events, in the sense that a pr ocess never falls behind in its work and fails to 
respond to an external event in a timely manner. For example, when a frame is to be received, it 
is assumed that the Media Access procedure Rece iveFrame is always called well before the 
frame in question has started to arrive.
2) Processes Versus Processes. Amo ng processes, no assumptions are made about relative speeds 
of execution. This means that each interaction between two pro cesses shall be structured to 
work correctly independent of their respective speeds. Note, however, that the timing of inter -
actions among processes is often, in part, an indirect reflection of the timing of external events, 
in which case appropriate
 timing assumptions may still be made.
It is intended that the concurrency in the model reflect the pa rallelism intrinsic to the task of implementing the 
MAC client and MAC procedures, although the actual parallel structure of the implementations is likely to vary.
4.2.2.2 Use of Pascal in the procedural model
Several observations need to be made regarding the met hod wi th which Pascal is used for the model. Some 
of these observations are as follows:
a) The following limitations of the language have been circumvented to simplify the sp ecification:
1) The elements of the program (variables and procedures, for exam ple) are presented in logical 
groupings, in top-down order. Certain Pascal ordering restrictions have thus been circumvented 
to improve readability.
2) The process and cycle  co nstructs of Concurrent Pascal, a Pascal derivative, have been intro -
duced to indicate the sites of autonomous concurrent activity. As used here, a process is simply 
a parame
terless procedure that begins execution at “the beginning of time” rather than being 
invoked by a procedure call. A cycle statement re presents the main body of a process and is 
executed repeatedly forever.
3) The lack of variable array bounds in the langua ge has been circu mvented by treating frames as 
if they are always of a single fixed size (which is never actually specified). The size of a frame 
depends on the size of its data field, hence the value of the “pseudo-constant” frameSize should 
be thought of as varying in the long term, even though it is fixed for any given frame.
4) The use of a variant record to represent a frame (as fields and as  bits) follows th
 e spirit but not 
the letter of the Pascal Report, since it allows the underlying representation to be viewed as two 
different data types.
b) The model makes no use of any explicit interprocess synchroni zation prim iti ves. Instead, all 
interprocess interaction is done by way of carefully stylized manipula tion of shared variables. For 

---
<!-- Page 134 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
60 Copyright © 2008 IEEE. All rights reserved.
example, some variables are set by only one process and inspected by another process in such a 
manner that the net result is independent of their execution speeds. While su ch techniques are not 
generally suitable for the construction of large c oncurrent programs, they simplify the model and 
more nearly resemble the methods appropriate to the most likely implementation technologies 
(microcode, hardware state machines, etc.) 
4.2.2.3 Organization of the procedural model
The procedural model used here is based on seven cooperating concurrent pro
 cesses. The Frame Transmitter 
process and the Frame Receiver pro cess are provided by the clients of  the MAC sublayer (which may 
include the LLC sublayer) and make use of the inte rface operations provided by the MAC sublayer. The 
other five processes are defined to reside in the MAC sublayer. The seven processes are as follows:
a) Frame Transmitter process 
b) Frame Receiver process 
c) Bit Transmitter process 
d) Bit Receiver process 
e) Deference process 
f) BurstTimer process
g) SetExtending process
This organization of the model is illustrated in Figure 4–1 and reflects the fact that the communication of entire 
fr
ames is initiated by the client of the MAC sublayer, while the timing of collision backoff and of individual bit 
transfers is based on interactions
 between the MAC sublayer and the Physical-Layer-dependent bit time. 
Figure 4–1 depicts the static structure of the procedural model , showing how the various processes and pro -
cedures interact by invoking each other. Figure  4–2a, 4–2b, 4–3a, and 4–3b summarize the dynamic behav-
ior of the model during transmission and reception, focusing on the steps that shall be performed, rather than 
the procedural structure that performs them. The usage of the shared state variables is not depicted in the fig-
ures, but is described in the comments and prose in the fo llowing subclauses.             
4.2.2.4 Layer management extensions to procedural model
In order to incorporate network management functions , this Procedur al Model has been expanded beyond 
that provided in ISO/IEC 8802-3:1990. Network management functions have been incorporated in two 
ways. First, 4.2.7–4.2.10, 4.3.2, Figure 4–2a, and Figure 4–2b have been modified and expanded to provide 
management services. Second, Layer Management procedures have been added as 5.2.4. Note that Pascal 
variables are shared between Clause  4 and Clause 5. Within the Pascal descriptions provided in Clause 4, a 
“‡” in the left margin indicates a line that has been added to sup port management services. These lines are 
only required if Layer Management is being implemented. These changes do not affect any aspect of the 
MAC behavior as observed at the LLC-MAC and MAC-PLS interfaces of ISO/IEC 8802-3:1990.
The Pascal procedural specification sh all be consulted for the definiti
 ve statement when there is any appar -
ent ambiguity concerning the definition of some aspect of the CSMA/CD MAC access method.
The Layer Management facilities provided by the CSMA/CD MAC and Physical Layer management 
definitions 
provide the ability to manipulate management counters and initiate actions within the layers. The 
managed objects within this standard are defined as sets of attributes, actions, notifications, and behaviors in 
accordance with IEEE Std 802.1F-1993, and ISO/IEC International Standards for network management.
4.2.3 Packet transmission model
Packet transmission includes the fol
 lowing data encapsulation and Media Access management aspects:

---
<!-- Page 135 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 61
a) Transmit Data Encapsulation includes the assembly  of the outgoing packet  (from the val ues pro-
vided by the MAC client) and frame check sequence generation (if not provided by the MAC client).
b) Transmit Media Access Management includes carrier  deference, interpacket gap, collision detection 
and enforcement, collision backoff and retra
nsmission, carrier extension and packet bursting. 
4.2.3.1 Transmit data encapsulation
The fields of the CSMA/CD MAC frame are set to the values provided by  the MAC client as arguments to 
the TransmitFrame operation (see 4.3) with the following po ssible exceptions: the padd ing field, the exten-
sion 
field, and the frame check sequence. The padding field is necessary to enforce the minimum frame size. 
*BurstTimer
PHYSICAL LAYER
MEDIA ACCESS SUBLAYER
FrameTransmitter FrameReceiver
TransmitFrame
TransmitDataEncap ReceiveDataDecap
ReceiveFrame
CRC32ComputePad RemovePadLayerMgmt
TransmitLinkMgmt ReceiveLinkMgmt
StartTransmit
StartReceive
BitReceiverDeference
PhysicalSignalDecapPhysicalSignalEncap
BitTransmitter
NextBit
TransmitBit ReceiveBitWait
TRANSMIT RECEIVE 
MEDIUM
MANAGEMENT
FRAMING
† Not applicable to full duplex operation.
†WatchForCollision †BackOff
†Random
†StartJam
*SetExtending
* Applicable only to half duplex operation at 1000 Mb/s.
*InterFrameSignal
MAC CLIENT
Figure 4–1—Relationship among CSMA/CD procedures
RecognizeAddress

> **[Figure 4-1 Description — page_images/page_136.png]**
> Architecture diagram of the seven-process CSMA/CD procedural model, organized in three layers:
> - **MAC CLIENT:** FrameTransmitter, FrameReceiver
> - **MEDIA ACCESS SUBLAYER:** TransmitFrame→TransmitDataEncap→ComputePad→TransmitLinkMgmt→StartTransmit→BitTransmitter→PhysicalSignalEncap→TransmitBit (transmit path); ReceiveFrame→ReceiveDataDecap→CRC32→LayerMgmt/RecognizeAddress→ReceiveLinkMgmt→StartReceive→BitReceiver→PhysicalSignalDecap→ReceiveBit (receive path); Deference, BurstTimer(*), SetExtending(*) (management); WatchForCollision(†), BackOff(†), Random(†), StartJam(†), InterFrameSignal(*) (half-duplex)
> - **PHYSICAL LAYER:** TransmitBit, Wait, ReceiveBit
> † = Not applicable to full duplex; * = Half duplex at 1000 Mb/s only

---
<!-- Page 136 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
62 Copyright © 2008 IEEE. All rights reserved.
TransmitFrame
Transmit
ENABLE?
assemble frame
burst
continuation?
deferring on?
start transmission
halfDuplex
and 
collisionDetect?
transmission
done?
send jam
increment attempts
too many
attempts?
compute backoff
wait backoff time
Done:
transmitOK
Done:
excessiveCollisionError
no
yes
yes
no
no
no
yes
yes
yes
no
‡
no
yes
late
‡ For Layer Management
Done:
transmitDisabled
‡
yes
no
collision and >
100 Mb/s?
*Applicable only to half duplex operation at 1000 Mb/s
*
Done:
lateCollisionErrorStatus
a) TransmitFrame
Figure 4–2a—Control flow summary

> **[Figure 4-2a Description — page_images/page_137.png]**
> TransmitFrame flowchart: Check Transmit ENABLE→no: Done(transmitDisabled); Assemble frame→Check burst continuation(*); Check deferring on?→yes: loop; Start transmission→Check halfDuplex AND collisionDetect?→yes: send jam→increment attempts→check late collision and >100 Mb/s?→check too many attempts?→compute backoff→wait backoff time→loop; Check transmission done?→no: loop. Exit: Done(transmitOK), Done(lateCollisionErrorStatus), Done(excessiveCollisionError). ‡=Layer Management; *=1000 Mb/s half duplex.

---
<!-- Page 137 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 63
ReceiveFrame
Receive
ENABLE?
start receiving
done
receiving?
disassemble frame
extra bits?
Done:
receiveOK
no
yes
yes
no
‡
no
yes
‡ For Layer Management
Done:
receiveDisabled
‡
frame
(collision)
too small?
recognize
address?
frame
too long?
valid
sequence?
frame check
valid
field?
length/type
Done:
lengthError
Done:
frameCheckError
Done:
alignmentError
Done:
frameTooLong
‡
‡
yes
yes
yes
yesyes
no
nono
no
no
b) ReceiveFrame
Figure 4–2b—Control flow summary

> **[Figure 4-2b Description — page_images/page_138.png]**
> ReceiveFrame flowchart: Check Receive ENABLE→no: Done(receiveDisabled); Start receiving→loop until done; Check frame too small?(collision)→yes: Done(receiveDisabled); Check recognize address?→no: Done(receiveDisabled); Check frame too long?→yes: Done(frameTooLong); Check valid frame check sequence?→no: check extra bits?→Done(alignmentError or frameCheckError); Check valid length/type field?→no: Done(lengthError); Disassemble frame→Done(receiveOK). ‡=Layer Management.

---
<!-- Page 138 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
64 Copyright © 2008 IEEE. All rights reserved.
no
yes
yes
no transmission
started?
transmit a bit
end of
frame?
transmission done
BitTransmitter process
yes
yes
no
no receiving
started?
receive a bit
receiving done
BitReceiver process
bursting on?
fill interframe
yes
no*
*
bursting off
no
yes
*
*
# of bits
≥ slotTime?
extending off
errors in
extension?
extensionOK off
yes
yes
no
no
extending off?
receiveSucceeding
 off
yes
no
*Applicable only to half duplex operation at 1000 Mb/s
*
*
*
*
*
*
receiveDataValid
off or frameFinished
on?
frameWaiting
and bursting on?
a) MAC sublayer
Figure 4–3a—Control flow

> **[Figure 4-3a Description — page_images/page_139.png]**
> Two parallel process flows for MAC sublayer:
> **BitReceiver (left):** Wait for receiving→receive a bit→check #bits≥slotTime?→extending off(*)→check errors in extension?→extensionOK off(*)→check receiveDataValid off or frameFinished on?→check extending off?→receiving done / receiveSucceeding off(*).
> **BitTransmitter (right):** Wait for transmission→transmit a bit→check end of frame?→check bursting on?→fill interframe(*)→check frameWaiting and bursting on?→bursting off(*)→transmission done. *=1000 Mb/s half duplex.

---
<!-- Page 139 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 65
extending on
yes
yes
no
*SetExtending process
halfDuplex
and 
> 100 Mb/s?
no
bursting on?
clear burstCounter
wait one Bit Time
increment 
burstCounter
bursting on and 
burstCounter <
burstLimit?
no
no
yes
yes
*BurstTimer process
*Applicable only to half duplex operation at 1000 Mb/s
bursting off
deferring on
channel busy?
no
no
deferring off
wait 
channel free?
interpacket gap
frameWaiting?
yes
yes
yes
no
Deference process
b) MAC sublayer
Figure 4–3b—Control flow
receiveDataValid 
on?

> **[Figure 4-3b Description — page_images/page_140.png]**
> Three parallel process flows:
> **Deference (left):** Check channel busy?→deferring on→check channel free?→wait interpacket gap→deferring off→check frameWaiting?→loop.
> **BurstTimer (right, *):** Check bursting on?→clear burstCounter→wait one Bit Time→increment burstCounter→check burstCounter<burstLimit?→loop or bursting off.
> **SetExtending (bottom, *):** Check receiveDataValid on?→loop; Check halfDuplex and >100 Mb/s?→extending on. *=1000 Mb/s half duplex.

---
<!-- Page 140 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
66 Copyright © 2008 IEEE. All rights reserved.
The extension field is necessary to enforce the minimum carrier event duration on the medium in half duplex 
mode at an operating speed of 10 00 Mb/s. The frame check sequence fiel d may be (optionally) provided as 
an argument to the MAC sublayer. It is optional for a MAC to support the provision of the frame check 
sequence in such an argument. If this field is provided by the MAC client, the padding field shall also be 
provided by the MAC client, if necessary. If this field is not provided by the MAC client, or if the MAC does 
not support the provision of the frame check sequence as an external argument, it is set to the CRC value 
generated by the MAC sublayer, after appending the padding field, if necessary.
4.2.3.2 Transmit media access management
4.2.3.2.
1 Deference
When a packet is submitted by the MAC client for transmis sion, the transmission is initiated as soon as pos-
sible, but in conformance with the rules of deference stated below. The rules of deference diff er between half 
duplex and full duplex modes.
a) Half duplex mode 
Even when it
 has nothing to transmit, the CSMA/CD MAC sublayer monitors the physical medium 
for traffic by watching
 the carrierSense signal provi ded by the PLS. Whenever the medium is busy, 
the CSMA/CD MAC defers to the passing packet by delaying any pending transmission of its own. 
After the last bit of the passing packet (that is, when carrierSense changes from true to false), the 
CSMA/CD MAC continues to defer for a proper interPacketGap (see 4.2.3.2.2).
If, at the end of the interPacketGap,  a packet  i s waiting to be transmitted, transmission is initiated 
independent of the value of carrierSense. When transmission has completed (or immediately, if there 
was nothing to transmit) the CSMA/CD MAC sublayer resumes its original monitoring of carri -
erSense.
NOTE—It is possible for the PLS carrier  sense indication to fail to be asserted briefly during a collision on the 
media. If the Deference process simply times the interp acket gap based on this i ndication it is possible for a 
short interpacket gap to be generated, leading to a potential reception failure of a subsequent frame. To enhance 
system robustness the following optional measures, as specified in 4.2.8, are recommended when 
interPacketGapPart1 is other than zero:
Start the timing of the interPacketGap as soon as  transmitting and carrierSense are both false. Reset 
the interPacketGap timer if carrierSense becomes true during the first 2/3 of the interPacketGap tim-
ing interval. During the final 1/3 of  the interval, the timer  shall not be reset to ensure fair access to 
the m
edium. An initial period shorter than 2/3 of the interval is permissible including zero.
b) Full duplex mode 
In full dupl
ex mode, the CSMA/CD MAC does not defer pending transmissions based on the carri -
erSense signal from the PLS. Instead , it us es the internal variable transmitting to maintain proper 
MAC state while the transmission is in progress. After the last bit of  a transmitted frame, (that is, 
when transmitting changes from true to false), the MAC continues to defer for a proper interPacket -
Gap (see 4.2.3.2.2).
4.2.3.2.2 Interpacket gap
As defined in 4.2.3.2.1, the rules for deferring to passing packet s ensure a minimum interpacket spacing of 
int
erPacketGap bit times. This is intended to provide interpacket recovery time for oth er CSMA/CD sublay-
ers and for the physical medium.
Note that interPacketGap is the minimum value o
 f the interpacket gap. If necessary for implementation rea-
sons, a transmitting sublayer may use a larger value with a resulting decrease in its throughput. The larger 
value is determined by the parameters of the implementation, see 4.4.

---
<!-- Page 141 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 67
A larger value for interpacket gap is used for dynamically adapting the nominal data rate of the MAC sub -
layer to SONET/SDH data rates (with packet granularity) for WAN-comp atibl e applications of this stan -
dard. While in this optional mode of operation, the MA C sublayer coun ts t he number of bits sent during a 
frame’s transmission. After the pack et’s transmission has been completed, the MAC sublayer extends the 
minimum interpacket gap by a number of bits that is proportional to the length of the previously transmitted 
packet. For more details, see 4.2.7 and 4.2.8.
4.2.3.2.3 Collision handling (half duplex mode only)
Once a CSMA/CD sublayer has finished deferring and has started transmission, it is still possible for it to 
experience contention for the medi um. Collision s
 can occur until acquisition of the network has been 
accomplished through the deference of all other stations’ CSMA/CD sublayers.
The dynamics of collision handling are largely determined by a singl e parameter called the slot time. This 
single parameter describes three important aspects of collision handling:
a) It is an upper bound on the acquisition time of the medium.
b) It is an upper bound on the length of a packet fragment generated by a collision.
c) It is the scheduling quantum for retransmission.
To fulfill all three functions, the slot time shall be lar ger than the sum of the Physical Layer rou
 nd-trip 
propagation time and the Media Access Layer maximum jam time. The slot time is determined by the 
parameters of the implementation, see 4.4.
4.2.3.2.4 Collision detection and enforcement (half duplex mode only)
Collisio
ns are detected by monitoring the collisionDetect signal prov ided by the Physical Layer. When a col-
lision is detected during a packet tr ansmission, the transmis sion is not terminated immediately. Instead, the 
transmission continues until additional bits specified by  jamSize have been transmitted (counting from the 
time collisionDetect went on). This collision enforcement or jam guarantees that the duration of the collision 
is sufficient to ensure its detection by all transmitting stations on the network. The content of the jam is 
unspecified; it may be any fixed or variable pattern convenient to the Media Access implementation; how -
ever, the implementation shall not be intentionally designed to be the 32-bit CRC value corresponding to the 
(partial) packet transmitt
ed prior to the jam.
4.2.3.2.5  Collision backoff and retransmission (half duplex mode only)
When a transmission attempt has terminated due to a collisi on, it is retried by the transmitting CSMA/CD 
sublayer until either it is successful or a maximum numb er of attempts (attemptLimit) have been made and 
all have terminated due to collisions. Note that all at tempts to transmit a given packet are completed before 
any subsequent outgoing packets are transmitted. The scheduling of the retransmissions is determined by a 
controlled randomization process calle d “truncated binary exponential backoff.” At the end of enforcing a 
collision (jamming), the CSMA/CD sublayer delays before attempting to retransmit the packet. The delay is 
an integer multiple of slotTime. The number of slot times to delay before the n th retransmission attempt is 
chosen as a uniformly distributed random integer r in the range:
0 ≤ r < 2k
where
k = min (n, 10)

---
<!-- Page 142 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
68 Copyright © 2008 IEEE. All rights reserved.
If all attemptLimit attempts fail, this event is reported as an error. Algorithms used to generate the integer r
should be designed to minimize the correlation between the numbers generated by any two stations at any 
given time.
Note that the values given above define the most aggressive behavior that a station may exhibit in attempting 
to retran smit after a colli sion. In
 the course of implementing the retransmission  scheduling procedure, a 
station may introduce extra delays that will degrade its own throughput, but in no case may a station’s 
retransmission scheduling result in a lower average delay between retransmission attempts than the proce -
dure defined above.
4.2.3.2.6 Full duplex transmission
In full duplex mode, there is never contention for a shared physical medium. The Physical Layer may indi -
cate to the MAC that there are simultaneou
 s transmissions by both stations, but since these transmissions do 
not interfere with each other, a MAC operating in full duplex  mode must not react to such Physical Layer 
indications. Full duplex stations do not defer to received traffic, nor ab ort transmission, jam, backoff, and 
reschedule transmissions as part of Transmit Medi a Access Management. Transm issions may be initiated 
whenever the station has a packet queued, subject only to the interpacket gap required to allow recovery for 
other sublayers and for the physical medium.
4.2.3.2.7 Packet bursting (half duplex mode only)
At an operating speed of 1000 Mb/s, an implementation may optionally transmit a series of packets without 
relinquishin
g control of the transmission medium. This mode of operation is referred to as burst mode. Once 
a packet has been successfully transmitted, the transmitting station can begin transmission of another packet 
without contending for the medium because all of the other stations on the network will continue to defer to 
its transmission, provided that it does not allow the medium to assume an idle condition between packets. 
The transmitting station fills the interpacket gap interval with extension bits, which are readily distinguished 
from data bits at the receiving stations, and which maintain the detect ion of carrier in the receiving stations. 
The transmitting station is allowed to initiate packet transmission until a specified limit, referred to as 
burstLimit, is reached. The value of burstLimit is  specified in 4.4.2. Figure 4–4 shows an example of 
transmission with packet bursting.
The first packet of a burst will be extend ed, if necessary, as 
 described in 4.2.3.4. Subsequent packets within 
a burst do not require extension. In a properly configur ed network, and in the ab sen ce of errors, collisions 
cannot occur during a burst at any time after the first packet of a burst (including any extension) has been 
transmitted. Therefore, the MAC will treat any collision that occurs after the first packet of a burst, or that 
occurs after the slotTime has been reached in the first packet of a burst, as a late collision.
4.2.3.3 Minimum frame size
The CSMA/CD Media Access mechanism requires that a minimu m frame length of minFrameSize bits be 
transmitted. If frameSize is less than minFrameSize, then the CSMA/C D MAC sublayer shall append extra 
bits in units of octets (Pad), after the end of the MAC Client Data field but prior to calculating and append -
ing the FCS (if not provided by the MAC client). The number  of extra bits shall be suf ficient to ensure that 
the frame, from the DA field throu gh the FCS field inclusive, is at least minFrameSize bits. If the FCS is 
burstLimit
duration of carrier Event
MAC Packet with Extension Inter Packet MAC Packet InterPacket MAC Packet
Figure 4–4—Packet bursting

> **[Figure 4-4 Description — page_images/page_142.png]**
> Timing diagram showing packet bursting at 1000 Mb/s half duplex:
> [MAC Packet with Extension] [InterPacket] [MAC Packet] [InterPacket] ... [MAC Packet]
> The first packet includes carrier extension. Subsequent packets separated by interpacket fill (extension bits). Total burst must not exceed burstLimit. Duration of carrier event spans the entire burst.

---
<!-- Page 143 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 69
(optionally) provided by the MAC client, the Pad shal l also  be provided by the MAC client. The content of 
the Pad is unspecified.
4.2.3.4 Carrier extension (half duplex mode only)
At an operating speed of 1000 Mb/s, the slotTime employed at 
 slower speeds is inadequate to accommodate 
network topologies of the desired physical extent. Carrier Extension provides a means by which the 
slotTime can be increased to a sufficient value for the desired topologies, without increasing the 
minFrameSize parameter, as this would have deleterious effects. Non-data bits, referred to as extension bits, 
are appended to frames that are less th an slotTime bits in length so that the resulting transmission is at least 
one slotTime in duration. Carrier Extension can be performed only if the underlying Physical Layer is 
capable of sending and receiving symbols that are readily distinguished from data symbols, as is the case in 
most Physical Layers that use a block encoding/decoding scheme. The maximum length of the extension is 
equal to the quantity (slotTime 
– minFrameSize). Figure 4–5 depicts a frame with carrier extension.
The MAC continues to monitor the medium for collisions while it is transmitting extension bits, and it will 
treat any collision that occurs after the 
threshold (slotTime) as a late collision.
4.2.4 Frame reception model
CSMA/CD MAC sublayer frame reception includes both data decaps ulation and Media Access management 
aspects:
a) Receive Data Decapsulation comprises address recognition, frame check sequence validation, and 
frame disassembly to pass the fields of the received frame to the MAC client.
b) Receive Media Access Management comprises reco gnition of collision fr agments from incoming 
frames 
and truncation of frames to octet boundaries.
4.2.4.1 Receive data decapsulation
4.2.
4.1.1 Address recognition
The CSMA/CD MAC sublayer is capable of recognizing ind ividual and group addresses.
a) Individual Addresses. The CSMA/CD MAC sublayer recognizes and accepts any frame whose DA 
field contains the individual address of the station.
b) Group Addresses. The CS MA/CD MAC sublayer recognizes and accepts any frame whose DA field 
contains the Broadcast address.
The CSMA/CD MAC sublayer is capable of activating some number of gro up addresses as specified by 
higher layers. The CSMA/CD MAC sublayer recognizes and accepts any frame whose Destination Address 
field contains an active group address. An active group address may be deactivated.
Figure 4–5—Frame with carrier extension
Preamble SFD DA SA Length/Type Data/Pad FCS Extension
minFrameSize
slotTime
FCS Coverage
late collision threshold (slotTime)
duration of carrier event

> **[Figure 4-5 Description — page_images/page_143.png]**
> Frame structure with carrier extension at 1000 Mb/s half duplex:
> [Preamble][SFD][DA][SA][Length/Type][Data/Pad][FCS][Extension]
> - minFrameSize: spans DA through FCS
> - slotTime: spans DA through end of Extension
> - FCS Coverage: spans DA through FCS
> - Late collision threshold = slotTime
> - Duration of carrier event: spans Preamble through end of Extension
> Extension bits appended after FCS to ensure transmission meets slotTime.

---
<!-- Page 144 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
70 Copyright © 2008 IEEE. All rights reserved.
The MAC sublayer may also provide the capability of operat ing in the promiscuous receive mode. In this 
mode of operation, the MAC sublayer recognizes and accepts all valid frames, regardless of their Destina -
tion Address field values.
4.2.4.1.2 Frame check sequence validation
FCS validation is essentially identical to FCS generation.  If the bits of the in
 coming frame (exclusive of the 
FCS field itself) do not generate a CRC value identical to the one received, an er ror has occurred and the 
frame is identified as invalid.
4.2.4.1.3 Frame disassembly
Upon recognition of the Start Frame Delimiter at the end of the pr eamble sequence, 
 the CSMA/CD MAC 
sublayer accepts the frame. If there are no errors, the frame is disassemb led and the fields are passed to the 
MAC client by way of the output parameters of the ReceiveFrame operation.
4.2.4.2 Receive media access management
4.2.4.2.
1 Framing
The CSMA/CD sublayer recognizes the boundaries of an incomin g MAC frame by monitoring the receive -
DataValid signal provided by the Physical Layer. Tw o possible leng th errors can  occur that indicate ill-
framed
 data: the MAC frame may be too long, or its length may not be an integer number of octets.
a) Maximum Frame Size. The receiving CSMA/CD sublayer is not required to enforce the MAC frame 
size li m
it, but it is allowed to truncate MAC fr ames longer than maxFrameSizeLimit octets (see 
4.2.7.1). If optional layer manage ment is implemented, such frames may be counted whether or not 
they are truncated. They may also be reported as an implementation-dependent error.
b) Integer Number of Octets i n  Frame. Since the format of a valid MAC frame specifies an integer 
number of octets, only a collision or an error can produce a MAC frame with a length that is not an 
integer multiple of 8 bits. Complete MAC frames (t hat is, not rejected as collision fragments; see 
4.2.4.2.2) that do not contain an integer number of octets are truncated to the nearest octet boundary. 
If frame check sequence 
validation detects an error in such a MAC frame, the status code alignmen-
tError is reported.
When a burst of MAC frames is received while operating in half duplex  mode at an operating speed of 
1000 Mb/s, the ind
ividual MAC frames within the burst are delimited by sequences  of interpacket fill 
symbols, which are conveyed to the receiving M
AC sublayer as extension bits. Once the collision filtering 
requirements for a given MAC frame, as described in 4.2.4.2.2, have been satisfied,  the receipt of an 
extension bit can be used as an indication that all of the data bits of the MAC frame have been received.
4.2.4.2.2  Collision filtering
In the absence of a collision, the s hortest valid tr
 ansmission in half duplex mode must be at least one slot -
Time in length. Within a burst of frames, the first frame of a burst m ust be at least slotTime bits in length in 
order to be accepted by the receiver, while subsequent frames within a burst must be at least minFrameSize 
in length. Anything less is presumed to be a fragment  resulting from a collision, and is discarded by the 
receiver. In half duplex mode, occasional collisions are a normal part of the Media Access management pro-
cedure. The discarding of such a fragment by a MAC is  not reported as an error.
CAUTION
It is recommended that any implementation that truncate s MAC frames should invalidate those frames as they 
may have severely weakened error protection and may cause serious problems if forwarded to the MAC client.

---
<!-- Page 145 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 71
The shortest valid transmission in full duplex mode must be at least minFrameSize in length. While 
collisions 
do not occur in full duplex mode MACs, a full duplex MAC nevertheless discards received frames 
containing less than minFrameSize bits. The discarding of such a frame by a MAC is not reported as an 
error.
4.2.5 Preamble generation
In a LAN implementation, most of the Physical Layer comp
 onents are allowed to provide valid output some 
number of bit times after being presented valid input sign als. Thus it is necessary for a preamble to be sent 
before the start of data, to allow the PLS circuitry to  reach its steady state. Up on request by TransmitLink -
Mgmt to transmit the first bit of a new frame, Physical SignalEncap shall first transmit the preamble, a bit 
sequence used for 
physical medium stabilization and synchronization, followed by the Start Frame Delim -
iter. If, while transmitting the preamble or Start Frame Delimiter, the collision detect variable becomes true, 
any remaining preamb
le and Start Frame Delimiter bits shall be sent. The preamble pattern is:
10101010  10101010  10101010  10101010  10101010  10101010  10101010
The bits are transmitted in order, from left to right. The nature of th e pa ttern is such that, for Manchester 
encoding, it appears as a periodic waveform on the medium that enables bit synchronization. It should be 
noted that the preamble ends with a “0.”
4.2.6 Start frame sequence
The receiveDataValid signal is the indication to the MAC th at the frame reception pr ocess should 
 begin. 
Upon reception of the sequ ence 10101011 followi ng the assertion of receiveDataValid, PhysicalSignalDe -
cap shall begin passing successive bits to ReceiveLinkMgmt for passing to the M AC client.
4.2.7 Global declarations
This subclause provides detailed formal specifications for the CSMA/CD MAC sublayer. It is a specification 
of 
generic features and parameters to be used in systems implementing this media access method. Subclause 
4.4 provides values for these sets of parameters for recommended implementa tions of this  media acce ss 
mechanism.
4.2.7.1 Common constants, types, and variables
The following declarations of constants, types and va riables are used by the MA C frame transmission and 
reception sections of each CSMA/CD 
sublayer:
const
addressSize = 48; {In bits, in compliance with 3.2.3}
lengthOrTypeSize = 16; {In bits}
clientDataSize = ...; {In bits, size of MAC Client Data; see 4.2.2.2, a) 3)}
padSize = ...; {In bits, = max (0, minFrameSize 
– (2 x addressSize + lengthOrTypeSize +
clientDataSize + crcSize))}
dataSize = ...; {In bits, = clientDataSize + padSize}
crcSize = 32; 
{In bits, 32-bit CRC}
frameSize = ...; {In bits, = 2 x addressSize + lengthOrTypeSize + dataSize + crcSize; see 4.2.2.2, a)}
minFrameSize = ..; {In bits, see 4.4}
maxBasicFrameSize = 1518; {In octets, see 3.2.7, 4.4}
maxEnvelopeFrameSize = 2000; {In octets, see 3.2.7, 4.4}
qTagPrefixSize = 4; {In octets, length of
  Q-tag prefix, see 3.2.7, 4.4}
maxFrameSizeLimit = maxBasicFrameSize or (maxBasicFrameSize + qT agPrefixSize) or
maxEnvelopeFrameSize ; {in octets}

---
<!-- Page 146 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
72 Copyright © 2008 IEEE. All rights reserved.
extend = ...; {Boolean, true if (slotTime – minFrameSize) > 0, false otherwise}
extensionBit = ...; {A non-data value which is used for carrier extensi on and interpacket 
during bursts}
extensionErrorBit = ...; {A non-data value which is  used to jam during carrier extension}
minTypeValue = 1536; {Minimum value of the Length/Type field for Type interpretation}
maxBasicDataSize = 1500;
{In octets, the maximum length of the MAC Client Data field of the basic frame.}
slotTime = ...; {In bit times, unit of time for collision han dling, implementation-dependent, see 4.4}
preambleSize = 56; {In bits, see 4.2.5}
sfdSize = 8; {In bits, Start Frame Delimiter}
headerSize = 64; {In bits, sum of preambleSize and sfdSize}
type
Bit = (0
, 1);
PhysicalBit = (0, 1, extensionBit, extensionErrorBit);
{Bit
s transmitted to the Physical Layer can be either 0, 1, extensionBit or
extensionErrorBit. Bits received from the Physical Layer can be either 0, 1
or extensionBit
}
AddressValue = array [1..addressSize] of Bit;
LengthO
rTypeValue = array [1..lengthOrTypeSize] of Bit;
DataVa
lue = array [1..dataS ize] of Bit; {Contains the portion of the MAC frame that starts with the first 
bit following the Length/Type field and ends with the last bit
prior to the FCS field.
CRCValue = array [1..crcSize] of Bit;
PreambleValue = array [1..preambleSize] of Bit;
SfdV
alue = array [1..sfdSize] of Bit;
View
Point = (fields, bits); {Two ways to view the contents of a frame}
