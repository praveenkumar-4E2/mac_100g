# Annex 4A — Simplified Full Duplex Media Access Control (from 802.3-2008 Section 1)

> Source: 802.3-2008_section1.md, Pages 647-671 (PDF pages)

NOTE—This annex is numbered in corres pondence to its associated clause; i.e., Annex 4A corresponds to Clause 4.
Annex 4A
(normative) 
Simplified full duplex media access control 
This annex is based on the Clause 4 MAC, with simpli fications for use in networks that do not require the 
half duplex operational mode. Additional functionality is included for managing Physical Layer congestion 
and for support of interframe spacing outside this s ublayer. This annex stands alone and does not rely on 
information within Clause 4 to be implemented.
4A.1 Functional model of the MAC method
4A.1.1 Overview
The architectural model described in Clause 1 is used in this clause to provide a functional description of the 
LAN fu
ll duplex MAC sublayer.
The MAC sublayer defines a medium-independent facility, built on the medium-dependent physical facility 
provided by
 the Physical Layer, and under the access-layer-independent LAN LLC sublayer (or other MAC 
client). It is applicable to a general class of me dia suitable for use with the full duplex media access 
discipline.
The LLC sublayer and the MAC sublayer  togeth er are intended to have the same function as that described 
in the OSI model for the Data Link Layer alone. The partitioning of functions presented in this standard 
requires two main functions generally associated with a data link control procedure to be performed in the 
MAC sublayer. They are as follows:
a) Data encapsulation (transmit and receive)
1) Framing (frame boundary deli mitation, frame synchronizatio
 n)
2) Addressing (handling of sour ce and destination addresses)
3)
Error detection (detection of physical medium transmission errors)
b) Media access management (Physical Layer congestion)
This MAC does not support the ha lf duplex m ode of operation so there is no need for collision detection or 
handling. However, this MAC does have the ability to avoid congestion within the Physical Layer. There -
fore, Media Access Management comprises the transmissi on of bits to the Phys ical Layer and optionally 
delayi
ng any transmission for an interframe gap or for a longer period of time based on congestion within 
the Physical Layer.
An optional MAC control sublayer, architecturally positioned between LLC (or other M AC client) and the 
MAC, is specified in Clause 31 and Clause 64. This MAC Control sublayer is transparent to both the 
underlying MAC and its client (typically LLC). The MAC sublayer  operates independently of its client; i.e., 
it is unaware whether the client is LLC or the MAC Control sublayer. This allows the MAC to be specified 
and implemented in one manner, whether or not the MA C Control sublayer is implemented. References to 
LLC as the MAC client in text and figures apply equally to the MAC Control sublayer, if implemented.
The remainder of this clause provides a functional model of this MAC method.

---
<!-- Page 648 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
574 Copyright © 2008 IEEE. All rights reserved.
4A.1.2 Full duplex operation
This subclause provides an overview of frame transmission and reception in terms of the functional model of 
the architecture. This overview is descriptive, rather than definitiona l; the formal speci fications of the 
operations described here are given in 4A.2 and 4A.3. Specific implementations for full duplex mechanisms 
that meet this standard are given in 4A.4. Figure 1-1 provides the architectural model described functionally 
in the subclauses that follow.
The Physical Layer Signaling (PLS) component of the Physical Layer provides an interface to the MAC 
subl
ayer for the serial transmission of bits onto th e physical media. For completeness, in the operational 
description that follows some of these functions are included as descriptive material. The concise 
specification of these functions is given in 4A.2 for the MAC functions and in Clause 7 for PLS.
Transmit frame operations are indepe ndent from receive frame o p erations and respond to different signals 
from the Physical Layer. Th e carrierSense signal indicat es that the transmit function must defer because of 
congestion at the Physical Layer (see 4A.2.3.2.1). The receiveDataValid signal  indicates the presence of 
incoming data to the receive function (see 4A.2.4.2).
4A
.1.2.1 Transmission
When a MAC client requests the transmission of a frame, the Tr ansmit Data Encapsulation component of the 
full duplex MAC sublayer constructs the frame from the client-supplied data. It prepends a preamble and a 
Start Frame Delimiter to the beginning of the frame. Using information provided by the client, the MAC 
sublayer also appends a Pad at the end of the MAC inform ation field of sufficient length to ensure that the 
transmitted frame length satisfies a minimum frame-size requirement (see 4A.2.3.2.4). It also prepends 
destination and source addresses, the length/type fiel d, and appends a fram e check sequence to provide for 
error detection. If the MAC supports the use of client-supplied frame check sequence values, then it shall use 
the client-supplied value, when present. If the use of client-supplied frame check sequence values is not 
supported, or if the client-supplied frame check sequen ce value is not present, then the MAC shall compute 
this value. Frame transmission may be initiated once th e carrierSense signal has been removed and after the 
interframe delay, regardless of the presence of receive activity.
The Physical Layer performs the task of generating the signals on 
 the medium that represent the bits of the 
frame. Once the Physical Layer has indicated its r eadiness to transmit anothe r frame by removing the 
carrierSense signal, it shall accept a complete frame fr om the MAC layer. A functional description of the 
Physical Layer is given in Clause 7 and beyond.
When transmission has completed, the MAC sublayer s o informs the MAC client and awaits the ne xt 
request for 
frame transmission.
4A.1.2.2 Reception
At each receiving station, the arrival of a frame is  first detected by 
 the Physical Layer, which responds by 
synchronizing with the incoming preamble, and by turning on the receiveDataValid signal. As the encoded 
bits arrive from the medium, they are decoded and tr anslated back into binary data. The Physical Layer 
passes subsequent bits up to the MAC sublayer, where the leading bits are discarded, up to and including the 
end of the preamble and Start Frame Delimiter.
Meanwhile, the Receive Media Access Management component of the MAC s ublayer
 , having observed 
receiveDataValid, has been waiting for the incomi ng bits to be delivere d. Receive Media Access 
Management collects bits from the Ph ysical Layer entity as long as th e receiveDataValid signal remains on. 
When the receiveDataValid signal is removed, the frame is truncated to an octet boundary, if necessary, and 
passed to Receive Data Decapsulation for processing.

---
<!-- Page 649 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 575
Receive Data Decapsulation checks the frame’s Destin ation Address field to decide whether the frame 
should be received by this station. 
If so, it passes the Destination Ad dress (DA), the Source Address (SA), 
the Length/Type, the Data, and (optionally) the Fram e Check Sequence (FCS) fields to the MAC client, 
along with an appropriate status code, as defined in 4A.3.2. It also checks for invalid MAC frames by 
inspecting the FCS to detect any damage to the fram e enroute, and b y  checking for proper octet-boundary 
alignment of the end of the frame. Frames with a valid FCS may al so be checked for proper octet-boundary 
alignment.
4A.1.3 Relationships to the MAC client and Physical Layers
The MAC sublayer provides services  to the MAC client required for the transmission and reception of 
frames. Access to these services is specified in 4A.3. The MAC sublayer makes a best effort to transfer a 
serial stream of bits to the Physical Layer. Although certain errors are reported to the client, error recovery is 
not provided by MAC. Error recovery may be provided by the MAC client or higher (sub)layers.
4A.2 Media access control (MAC) method: precise specification
4A.2.1 Introduction
A precise algorithmic definition is given in this su bclause, providing a procedural model for the MAC 
process with a program in the comput er language Pascal. See references [B13] and [B24]  for resource 
material. Note whenever there is any apparent ambigui ty concerning the d e finition of some aspect of the 
MAC method, it is the Pascal  procedural specification in 4A.2.7 through 4A.2.10 that should be consulted 
for the definitive statement. Subclauses 4A.2.2 through 4A.2.6 provide, in prose, a description of the access 
mechanism with the formal terminology to be used in the remaining subclauses.
4A.2.2 Overview of the procedural model
The functions of the MAC method are presented below, modeled as a program written in the computer 
language Pascal. This procedural model is intended as the primary specification of the functions to be 
provided in any MAC sublayer implementation. It is im portant to distinguish, however, between the model 
and a real implementation. The mode l is optimized for simplicity and clarity of presentation, while any 
realistic implementation shall place heavier emphasis on such constraints as  efficiency and suitability to a 
particular implementation technology or computer architecture. In this context, several important properties 
of the procedural model shall be considered.
4A.2.2.1 Ground rules for the procedural model
a) First, it shall be emphasized that the description of  the MAC sublayer in a computer language is in 
no way intended to imply that procedures s hall be implemented as a program executed by a 
computer. The implementation may consist of any appropriate technology including hardware, 
firmware, software, or any combination.
b) Similarly, it shall be emphasized that it is the behaviour of any MA C sublayer implementations that 
shall match the standard, not their internal structure. The internal details of the procedural model are 
useful only to the extent that they help specify that behaviour clearly and precisely.
c) The handling of incoming and outgoing frames is rather styli zed in the p r ocedural model, in the 
sense that frames are handled as single entities by most of the MAC sublayer and are only serialized 
for presentation to the Physical Layer. In realit y, many implementations will instead handle frames 
serially on a bit, octet or word basis. This appro ach has not been reflected in the procedural model, 
since this only complicates the description of the functions without changing them in any way.
d) The model consists of algorithms designed to be executed by a number of concurrent processes; 
these algorithms collectively implement the MAC pro
cedure. The timing dependencies introduced 
by the need for concurrent activity are resolved in two ways:

---
<!-- Page 650 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
576 Copyright © 2008 IEEE. All rights reserved.
1) Processes Versus External Events.  It is assumed that the algo rithms are executed “very fast” 
relative to external events, in the sense that a pr ocess never falls behind in its work and fails to 
respond to an external event in a timely manner. For example, when a frame is to be received, it 
is assumed that the Media Access procedure Rece iveFrame is always called well before the 
frame in question has started to arrive.
2) Processes Versus Processes. Amo ng processes, no assumptions are made about relative speeds 
of execution. This means that each interaction between two pro cesses shall be structured to 
work correctly independent of their respective speeds. Note, however, that the timing of 
interactions among processes is often, in part, an indirect reflection of the timing of external 
events, in which case appropriate timing assumptions may still be made.
It is intended that the concurrency in the model reflect the pa rallelism intrinsic to the task of implementing the 
MAC client and MAC procedures, although the actual parallel structure of the implementations is likely to vary.
4A.2.2.2 Use of Pascal in the procedural model
Several observations need to be made regarding the met hod wi th which Pascal is used for the model. Some 
of these observations are as follows:
a) The following limitations of the language have been circumvented to simplify the sp ecification:
1) The elements of the program (variables and procedures, for exam ple) are presented in logical 
groupings, in top-down order. Certain Pascal ordering restrictions have thus been circumvented 
to improve readability.
2) The process and cycle const r ucts of Concurrent Pascal, a Pascal derivative, have been 
introduced to indicate the sites of autonomous concurrent activity. As used here, a process is 
simply a parameterless procedure that begins ex ecution at “the beginning of time” rather than 
being invoked by a procedure call. A cycle statement represents the main body of a process and 
is executed repeatedly forever.
3) The lack of variable array bounds in the langua ge has been circu mvented by treating frames as 
if they are always of a single fixed size (which is never actually specified). The size of a frame 
depends on the size of its data field, hence the value of the “pseudo-constant” frameSize should 
be thought of as varying in the long term, even though it is fixed for any given frame.
4) The use of a variant record to represent a frame (as fields and as  bits) follows th e spirit but not 
the letter of the Pascal Report, since it allows the underlying representation to be viewed as two 
different data types.
b) The model makes no use of any explicit interprocess synchronization prim iti ves. Instead, all 
interprocess interaction is done by way of carefully stylized manipula tion of shared variables. For 
example, some variables are set by only one process and inspected by another process in such a 
manner that the net result is independent of their execution speeds. While su ch techniques are not 
generally suitable for the construction of large c oncurrent programs, they simplify the model and 
more nearly resemble the methods appropriate to the most likely implementation technologies 
(microcode, hardware state machines, etc.) 
4A.2.2.3 Organization of the procedural model
The procedural model used here is based on five co operating concurrent
  processes. The Frame Transmitter 
process and the Frame Receiver pro cess are provided by the clients of  the MAC sublayer (which may 
include the LLC sublayer) and make use of the inte rface operations provided by the MAC sublayer. The 
other three processes are defined to reside in the MAC sublayer. The five processes are as follows:
a) Frame Transmitter process 
b) Frame Receiver process 
c) Bit Transmitter process 
d) Bit Receiver process 
e) Deference process 
This organization of the model is illustrated in Figure 4A–1 and reflects the fact th at the communication of 
ent
ire frames is initiated by the client of the MAC sub layer, while the timing of individual bit transfers is based 
on interactions between the MAC sublayer and the Physical-Layer-dependent bit time.

---
<!-- Page 651 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 577
Figure 4A–1 depicts the static structure of  the procedu r al model, showing how the various processes and 
procedures interact by invoking each other. Figu re 4A–2a, Figure 4A–2b, and Figure 4A–2c summarize the 
dynamic behaviour of the model during transmission an d reception, fo cusing  on the steps that shall be 
performed, rather than the procedural structure that performs them. The usage of the shared state variables is 
not depicted in the figures, but is described in the comments and prose in the following subclauses. 
PHYSICAL LAYER
MEDIA ACCESS SUBLAYER
FrameTransmitter FrameReceiver
TransmitFrame
TransmitDataEncap ReceiveDataDecap
ReceiveFrame
ComputePad RemovePadLayerMgmt
TransmitLinkMgmt ReceiveLinkMgmt
StartTransmit StartReceive
BitReceiverDeference
PhysicalSignalDecap
BitTransmitter
TransmitBit ReceiveBitWait
TRANSMIT RECEIVE 
MEDIUM
MANAGEMENT
FRAMING
MAC CLIENT
Figure 4A–1—Relationship among MAC procedures
RecognizeAddress
CRC32 CRC32

> **Figure 4A-1 Description — Architecture Diagram**
> **Type:** Architecture / structural diagram
> **Visual content:** The diagram depicts the static structure of the MAC procedural model, organized into three horizontal layers separated by double lines: MAC CLIENT (top), MEDIA ACCESS SUBLAYER (middle), and PHYSICAL LAYER (bottom). A vertical dashed line divides the diagram into TRANSMIT (left) and RECEIVE (right) sides.
> **Key elements (TRANSMIT side, top to bottom):** FrameTransmitter (oval, MAC CLIENT) calls TransmitFrame, which invokes TransmitDataEncap. TransmitDataEncap calls ComputePad and CRC32. The result flows to TransmitLinkMgmt, then StartTransmit. Below the sublayer boundary, BitTransmitter (oval) calls TransmitBit, and the Deference process (oval) calls Wait.
> **Key elements (RECEIVE side, top to bottom):** FrameReceiver (oval, MAC CLIENT) calls ReceiveFrame, which invokes ReceiveDataDecap. ReceiveDataDecap calls CRC32, LayerMgmtRecognizeAddress, and RemovePad. The result flows to ReceiveLinkMgmt, then StartReceive. Below the sublayer boundary, BitReceiver (oval) calls PhysicalSignalDecap, which calls ReceiveBit.
> **Right-side labels:** FRAMING spans the MAC CLIENT procedures; MEDIUM MANAGEMENT spans the sublayer receive procedures.
> **Relationships shown:** Arrows indicate procedure invocation direction. The diagram shows how five concurrent processes (FrameTransmitter, FrameReceiver, BitTransmitter, BitReceiver, Deference) interact through shared procedures and state variables across the three architectural layers.

---
<!-- Page 652 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
578 Copyright © 2008 IEEE. All rights reserved.
TransmitFrame
Transmit
ENABLE?
assemble frame
deferring on?
start transmission
transmission
done?
Done:
transmitOK
no
yes
yes
no
no
yes
Done:
transmitDisabled
a) TransmitFrame
Figure 4A–2a—Control flow summary

> **Figure 4A-2a Description — Flowchart (TransmitFrame)**
> **Type:** Flowchart
> **Visual content:** A top-down flowchart showing the TransmitFrame control flow.
> **Flow:** TransmitFrame (oval start) → Transmit ENABLE? (diamond decision). If "no" → Done: transmitDisabled (oval). If "yes" → assemble frame (rectangle) → deferring on? (diamond). If "yes" → loops back to deferring check. If "no" → start transmission (rectangle) → transmission done? (diamond). If "no" → loops back. If "yes" → Done: transmitOK (oval).
> **Key elements:** Two exit states (transmitDisabled, transmitOK). The deferring loop implements Physical Layer congestion avoidance. The transmission loop sends bits until the frame is complete.
> **Relationships shown:** Sequential control flow with two decision points (enable check, deferring check, transmission completion).
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 579
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
no
yes
Done:
receiveDisabled
frametoo small?
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
yes
yes
yes
yesyes
no
nono
no
no
b) ReceiveFrame
Figure 4A–2b—Control flow summary

> **Figure 4A-2b Description — Flowchart (ReceiveFrame)**
> **Type:** Flowchart
> **Visual content:** A top-down flowchart showing the ReceiveFrame control flow with multiple error exit paths.
> **Flow:** ReceiveFrame (oval start) → Receive ENABLE? (diamond). If "no" → Done: receiveDisabled. If "yes" → start receiving (rectangle) → done receiving? (diamond, loops if "no") → frame too small? (diamond, loops back to start if "yes") → recognize address? (diamond, loops back if "no") → frame too long? (diamond, "yes" → Done: frameTooLong) → valid frame check sequence? (diamond, "no" → extra bits? diamond → "yes" → Done: alignmentError, "no" → Done: frameCheckError) → valid length/type field? (diamond, "no" → Done: lengthError) → disassemble frame (rectangle) → Done: receiveOK.
> **Key elements:** Six exit states: receiveDisabled, receiveOK, lengthError, alignmentError, frameCheckError, frameTooLong. The flowchart shows comprehensive frame validation including size checks, address recognition, FCS validation, and length/type field verification.
> **Relationships shown:** Sequential validation pipeline with early-exit error paths at each validation stage.
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
580 Copyright © 2008 IEEE. All rights reserved.
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
no receiving
started?
receive a bit
receiving done
BitReceiver process
fill interframeyes
no receiveDataValid
off or frameFinished
on?
Figure 4A–2c—Control flow
deferring on
transmitting or
deferring off
**wait 
interframe spacing
yes
no
Deference process
*carrierSense?
transmitting or
no
yes
*carrierSense?
* - carrierSense is ignored when
carrierSenseMode is FALSE
** - deferring for an interframe spacing is
ignored when deferenceMode is FALSE
c) MAC sublayer

> **Figure 4A-2c Description — Flowcharts (BitTransmitter, BitReceiver, Deference)**
> **Type:** Three flowcharts (control flow diagrams)
> **Visual content:** Three separate flowcharts arranged on the page:
> **BitTransmitter process (top-right):** transmission started? (diamond, loops if "no") → transmit a bit (rectangle) → end of frame? (diamond, "no" loops back, "yes") → fill interframe (rectangle) → transmission done.
> **BitReceiver process (top-left):** receiving started? (diamond, loops if "no") → receive a bit (rectangle) → receiveDataValid off or frameFinished on? (diamond, "no" loops back, "yes") → receiving done.
> **Deference process (bottom):** transmitting or *carrierSense? (diamond, "no" loops back, "yes") → deferring on (rectangle) → transmitting or *carrierSense? (diamond, "yes" loops back, "no") → **wait interframe spacing (rectangle, **) → deferring off (rectangle) → loops back to start.
> **Key annotations:** * carrierSense is ignored when carrierSenseMode is FALSE. ** deferring for an interframe spacing is ignored when deferenceMode is FALSE.
> **Relationships shown:** Three concurrent asynchronous processes that collectively manage bit-level transmission, reception, and interframe spacing/deference.
Copyright © 2008 IEEE. All rights reserved. 581
4A.2.2.4 Layer management extensions to procedural model
In order to incorporate network management functions , this Procedu r al Model has been expanded beyond 
that provided in ISO/IEC 8802-3:  1990. Network management functions have been incorporated in two 
ways. First, 4A.2.7–4A.2.10, 4A.3.2, Figure 4A–2a, and Figure 4A–2b have been modified and expanded to 
provide management services. Second, Layer Management procedures hav e been added as 5.2.4. The Pascal 
variables are shared between Annex 4A and Clause 5.
The Pascal procedural specification shal l be co nsult ed for the defini tive statement when there is any 
apparent ambiguity concerning the definition of some aspect of the MAC access method.
The Layer Management facilities provided by the MAC and Physical Layer ma nagement definitions provide 
the ability to manipulate management counters and initiate actions within the layers. The managed objects 
within this standard are defined as sets of attributes, actions, notif ications, and behaviours in accordance 
with IEEE Std 802.1F-1993, and ISO/IEC International Standards for network management.
4A.2.3 Packet transmission model
Packet transmission includes data encapsulation and Media Access management aspects:
a) Transmit Data Encapsulation includes the assembly  of the outgoing packet  (from the val ues pro-
vided by the MAC client) and frame check sequence generation.
b) Transmit Media Access Management includes carrier deference, interpacket gap and bit 
transmission.
4A.2.3.1 Tr
ansmit data encapsulation
The fields of the MAC frame are se t to the valu es provided by the MAC client as arguments to the 
TransmitFrame operation (see 4A.3) with the following possible exceptions: the padding field and the frame 
check sequence. The padding field is necessary to  enforce the minimum frame size. The frame check 
sequence field ma
y be (optionally) provided as an argument to the MAC sublayer. It is optional for a MAC 
to support the provision of the frame check sequence in such an argument. If this field is provided by the 
MAC client, the padding field shall also be provided by the MAC client, if necessary. If this field is not 
provided by the MAC client, or if the MAC does not support the provision of the frame check sequence as 
an external argument, it is set to the CRC value as generated by the MAC sublayer, after appending the 
padding field, if necessary.
4A.2.3.2 Transmit media access management
4A.2.3.2.1 Deference
When a packet is submitted by the MAC cli ent fo r transmi
 ssion, the transmission is initiated as soon as 
possible, but in conformance with the following rule s. The variable carrierSense is ignored in process 
Deference when the variable carrierSenseMode is FALSE.
The MAC sublayer monitors the transmitting variable, which indicates the MAC is transmitting data to the 
Physical Layer, as well as the carrierSense sign
al provided by the PLS, which indicates the Physical Layer is 
not ready for the next fram e. When either transmitting or carrierSense is true, the MAC delays any pending 
transmission. When both are false, the MAC continues to defer for a proper interPacketGap (see 4A.2.3.2.2). 
If, at the end of the interP acketGap, a packet is waitin g to b e transmitted, transm ission is initiated. When 
transmission has completed (or immediately, if there was nothing to transmit) the MAC sublayer resumes its 
original monitoring of transmitting and carrierSense.

---
<!-- Page 656 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
582 Copyright © 2008 IEEE. All rights reserved.
4A.2.3.2.2 Interpacket gap
As defined in 4A.2.3.2.1, the rules for deferring ensure a minimu m interpacket spacing of interPacketGap
bit times. Thi
s is intended to provide interframe recovery time to aid in packet delineation on the physical 
medium.
No
te that interPacketGap is the minimum value o f the interpacket gap. If necessary for implementation rea-
sons, a transmitting sublayer may use a larger value with a resulting decrease in its throughput. The larger 
value is determined by the parameters of the implementation, see 4A.4.
4A.2.3.2.3 Transmission
Transmissions may be initiated whenever the station has a frame queued, subject only to the Physical Layer 
cong
estion and interframe spacing required to allow recovery for the physical medium. In certain 
implementations, interframe spacing is accomplished outside this layer. These implementations are allowed 
to ignore the deference process and always initiate transmissions immedi ately, subject only to conditions 
enforced outside this sublayer.
4A.2.3.2.4 Minimum frame size
The MAC requires that a minimum fr ame length of
  minFrameSize bits be transmitted. If frameSize is less 
than minFrameSize, then the MAC sublay er shall append extra bits in units of octets (pad), after the end of 
the MAC client data field but prior to calculating, and appending, the FCS (if not provided by the MAC 
client). The number of extra bits shall be sufficient to  ensure that the frame, fr om the DA field through the 
FCS field inclusive, is at least minFrameSize bits. If the FCS is (optionally) provided by the MAC client, the 
pad shall also be provided by the MAC client. The content of the pad is unspecified.
4A.2.4 Frame reception model
The MAC sublayer frame reception includes both data decapsulation and Media Access management aspects:
a) Receive data decapsulation comprises address recognition, frame check sequence validation, and 
frame disassembly to pass
 the fields of the received frame to the MAC client.
b) Receive media access management comprises recognition of collision fr agment s from incoming 
frames and truncation of frames to octet boundaries.
4A.2.4.1 Receive data de capsulation
4A.2.4.1.1 Address recognition
The MAC sublayer is capable of recognizing individual and group addresses.
a) Individual Addresses.  The MAC sublayer recognizes an d accepts any frame whose DA field 
contains the individual address of the station.
b) Group Addresses. The MAC s u blayer recognizes and accepts any frame whose DA field contains 
the Broadcast address.
The MAC sublayer is capable of act ivating som e number of group addresses as specified by higher layers. 
The MAC sublayer recogni zes and accepts any frame whose Destinat ion Address field contains an active 
group address. An active group address may be deactivated.
The MAC sublayer may also provide the capability of operat ing in the promiscuous receive mode. In this 
mode of operation, the MAC  su blaye
r recognizes and accepts all va lid frames, regardless of their 
Destination Address field values.

---
<!-- Page 657 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 583
4A.2.4.1.2 Frame check sequence validation
FCS validation is essentially identical to FCS generation.  If the bits of the in coming frame (exclusive of the 
FCS field itself) do not generate a CRC value identical to the one received, an er ror has occurred and the 
frame is identified as invalid.
4A.2.4.1.3 Frame disassembly
Upon recognition of the Start Frame Delimiter at th e en d of the preambl e sequen ce, the MAC sublayer 
accepts the frame. If there are no errors, the frame is disassembled a nd the fields are passed to the MAC 
client by way of the output parameters of the ReceiveFrame operation.
4A.2.4.2 Receive media access management
The MAC sublayer recognizes the boundaries of an incoming MAC frame by monitoring the  receiveData-
Vali
d signal provided by the Physical Layer. Two possib le length errors can occu r that indicate ill-framed 
data: 
the MAC frame may be too long, or its length may not be an integer number of octets.
a) Maximum Frame Size. The receiving MAC sublayer is not required to enforce the MAC frame size 
limit, but it is allowed to truncate MAC frames longer than maxFrameSizeLimit octets (see 4.2.7.1). 
If optional layer management is implemented, such frames may be counted whether or not they are 
truncated. They may also be reported as an implementation-dependent error.
b) Integer Number of Octets i n  Frame. Since the format of a valid MAC frame specifies an integer 
number of octets, only a collision or an error can produce a MAC frame with a length that is not an 
integer multiple of 8 bits. Complete MAC frames (that is, not rejected for being too small) that do 
not contain an integer number of octets are trun cated to the nearest octet boundary. If frame check 
sequence validation detects an error in such a MA C frame, the status co de alignmentError is 
reported
4A.2.5 Preamble generation
In a LAN implementation, most of the Physical Layer components are allowed to provide valid output some 
number of bit times after being presented valid input sign als. Thus it is necessary for a preamble to be sent 
before the start of data, to allow the PLS circ uitry to reach it s steady state. Upon request by 
TransmitLinkMgmt to transmit the first bit of a new fram e, BitTransmitter shall first transmit the preamble, 
a bit sequence used for physical medium stabilization and synchronization, followed by the Start Frame 
Delimiter. The preamble pattern is:
10101010 10101010  10101010  10101010  10101010  10101010  10101010
The bits are transmitted in order, from left to right. The nature of th e pa ttern is such that, for Manchester 
encoding, it appears as a periodic waveform on the medium that enables bit synchronization. It should be 
noted that the preamble ends with a 0.
4A.2.6 Start frame sequence
The receiveDataValid signal is the indication to the MAC th at the frame reception pr ocess should begin. 
Upon reception of the sequence 10101011 fo llowing the assertion of receiveDataValid, 
PhysicalSignalDecap shall begin passing successive bits to ReceiveLinkMgmt for passing to the MAC 
client.
CAUTION
It is recommended that any implem entation that truncates MAC frames sh ould invalidate those fra mes as 
they may have severely weakened error protection and may cause seri ous problems if forwarded to the 
MAC client.

---
<!-- Page 658 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
584 Copyright © 2008 IEEE. All rights reserved.
4A.2.7 Global declarations
This subclause provides detailed formal specifications fo r the MAC sublayer. It is a specification of generic 
features and parameters to be used in systems implementing this media access method. 4A.4 provides values 
for these sets of parameters for recommended implementations of this media access mechanism.
4
A.2.7.1 Common constants, types, and variables
The following declarations of constants, types and va riables are used by the MA C frame transmission and 
reception sections of each MAC sublayer:
const
address
Size = 48; {In bits, in compliance with 3.2.3}
lengthOrTypeSize = 16; {In bits}
clientDataSize = ...; {In bits, size of MAC Cl ient Data; see 4A.2.2.2, a) 3)}
padSize = ...; {In bits, = max (0, minFrameSize – (2 × addressSize + lengthOrTypeSize +
clientDataSize + crcSize))}
dataSize = ...; {In bits, = clientDataSize + padSize}
crcSize = 32; 
{In bits, 32-bit CRC}
frameSize = ...; {In bits, = 2 × addressSize + lengthOrTypeSize + dataSize + crcSize; see 4A.2.2.2, a)}
minFrameSize = ...; {In bits, see 4A.4}
maxBasicFrameSize = 1518; {In octets, see 3.2.7, 4A.4}
maxEnvelopeFrameSize = 2000; {In octets, see 3.2.7, 4A.4}
qTagPrefixSize = 4; {In octets, length of Q-tag Prefix, see 3.2.7, 4A.4}
maxFrameSizeLimit = maxBasicFrameSize or (maxBasicFrameSize + qT
 agPrefixSize) or
maxEnvelopeFrameSize ; {in octets}
minTypeValue = 1536; {Minimum value of the Length/Type field for Type interpretation}
maxBasicDataSize = 1500;
{In octets, the maximum length of the MAC Client Data field of the basic frame.}
preambleSize = 56; {In bits, see 4A.2.5}
sfdSize = 8; {In bits, Start Frame Delimiter}
headerSize = 64; {In bits, sum of preambleSize and sfdSize}
type
Bit = (0
, 1);
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
Point = (fields, bits); {Two ways to view the contents of a MAC frame}
HeaderVi
ewPoint = (headerFields, headerBits);
Frame = record {Format of MAC frame}
case view: V
iewPoint of
fields: (
desti
nationField: AddressValue;
sourceField: AddressValue;
lengthOrTypeField: LengthOrTypeValue;
dataField: DataValue;
fcsField: CRCValue);
bits: (contents: array [1..frameSize] of Bit)
end; {MAC frame}
Header = record {Format of Preamble and Start Frame Delimiter}
case headerV
iew: HeaderVi ewPoint of

---
<!-- Page 659 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 585
headerFields: (
preamble: PreambleValue;
sfd: SfdValue);
headerBits: (headerContents: array [1..headerSize] of Bit)
end; {Defines header for MAC frame}
Tran
smitStatus = (transmitDisabled, transmitOK, excessiveCollisionError , lateCollisionErrorStatus);
ReceiveStatus = (receiveDisabled, receiveOK, frameToo Long, frameCheckError, lengthError, 
alignmentError);
4A.2.7.2 Transmit state variables
The following items are specific to packet transmission. (See also 4A .4.)
const
interPacketGap = ...; {In bit times, minimum gap between packets,
see 4A.4}
var
outgoingFrame: Frame; {The frame to be transmitted}
outgoingHeader: Header;
curren
tTransmitBit, lastTransmitBit: 1..frameSize; {Positions o f current and last outgoing bits in
outgoingFrame}
lastHeaderBit: 1..headerSize;
deferring: Boolean; {Implies any pending transmission must wait for the Physical Layer to be ready for
 the next packet and for the interpacket gap}
deferenceMode: Boolean; {Indicates the desired mode of operation, an
 d enables waiting for
interpacket gap during the deference process}
carrierSenseMode: Boolean; {Indicates the desired mode of operation, and enables using carrierSense
to extend deference due to congestion in the PHY}
4A.2.7.3 Receive state variables
The following items are specific to frame reception. (See also 4A.4.)
var
incomingFrame: Frame; 
{The frame being received}
receiving: Boolean; {Indicates that a frame reception is in progress}
excessBits: 0..7; {Count of 
excess trailing bits beyond octet boundary}
receiveSucceeding: Boolean; {Running indicator of whether reception is succeeding}
validLength: Boolean; {Indicator of wh
ether received frame has a length error}
exceedsMaxLength: Boolean; {Indicator of whether received frame has a length longer than the
maximum permitted length}
passReceiveFCSMode: Boolean; {Indicates the desired mode of operation, and enables pass ing of
the frame check sequence field of all received frames from the
MAC sublayer to 
the MAC client. passReceiveFCSMode is a
static variable}
4A.2.7.4 State variable initialization
The procedure Initiali
ze must be run when the MAC sublay er begins operation, before any of the processes 
begin execution. Initialize sets certain crucial shared state variables to thei r initial values. (All other global 
variables are appropriately reinitialized before each use.) Initialize then waits for the medium to be idle, and 
starts operation of the various processes.
NOTE—Care should be taken to ensure that the time from the completion of the Initialize process to when the first 
packet transmission begins is at least an interFrameGap.

---
<!-- Page 660 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
586 Copyright © 2008 IEEE. All rights reserved.
If Layer Management is implemented, the Initialize pr ocedure shall only be called as the result of the 
initializeMAC action (30.3.1.2.1).
procedure Initialize;
begi
n
deferring := false;
transmitting := false; {An interface to Physical Layer; see below}
receiving := false;
passReceiveFCSMode := ...; {True when enabling the passing 
of the frame check sequence of all
received frames from the 
MAC sublayer to the MAC client is desired and
supporte
d, false otherwise}
deferenceMode := ...; {False for implementations that cannot rely on deference within the MAC to
provide an interframe gap, true otherwise}
carrierSenseMode := ...; {True for implementations that use carrierSense to indicate congestion in the
PHY, false otherwise.}
while ((carrierSenseMode and carrierSense) or receiveDataValid) do n othing
{Start execution of all processes}
end; {Initialize}
4A.2.8 Frame transmission
The algorithms in this subclause define MAC subl ayer frame transmission. The function TransmitFrame 
implements the frame transmission operation provided to the MAC client.
The TransmitFrame operation is synchronous. Its duration is the ent ire attempt to transmit the frame; when 
the operation completes, transmission has either succeeded or failed, as  indicated by the TransmitStatus sta-
tus code.
The transmitDisabled status code in dicates tha t the transmitter is not enabled. Successful transmission is 
indicated by the s
tatus code transmitOK. The codes excessiveCollisionError and lateCollisionErrorStatus 
are artifacts of the CSMA/CD MAC and maintained here for histori cal purposes. These codes are never 
generated by this full duplex MAC. TransmitStatus is not used by the service interface de fined in 2.3.1. 
TransmitStatus may be used in an implementation dependent manner.
function TransmitFrame (
destinationParam: AddressValue;
sourceParam: AddressValue;
lengthOrTypeParam: LengthOrTypeValue;
dataParam: DataValue;
fcsParamValue: CRCValue;
fcsParamPresent: Bit): TransmitStatus;
procedure TransmitDataEncap; {Nes
 ted procedure; see body below}
begin
if transmitEnabled then
begin
TransmitDataEncap;
TransmitFrame := TransmitLinkMgmt
end
else TransmitFrame := transmitDisabled
end; {TransmitFrame}

---
<!-- Page 661 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 587
If transmission is enabled, Trans mitFrame calls the internal p rocedure TransmitDataEncap to construct the 
frame. Next, TransmitLinkMgmt is called to perform th e actual transmission. The TransmitStatus returned 
indicates the success or failure of the transmission attempt.
TransmitDataEncap builds the frame and places the 32-bit CRC in the fram e check sequence field:
procedure TransmitDataEncap;
begin
with outgoingFrame do
begin {Ass
emble frame}
view := fields;
destin
ationField := destinationParam;
sourceField := sourceParam;
lengthOrTypeField := lengthOrTypeParam;
if fcsParamPresent then
begin
dataFiel
d := dataParam; {No need to generate pad if the FCS is passed fro m MAC client}
fcsField := fcsParamValue {Use the FCS passed from MAC client}
end
else
begi
n
dataField := ComputePad(dataParam);
fcsField := CRC32(outgoingFrame)
end;
view := bits
end {Assemble frame}
with outgoingHeader do
begin
headerView := headerFields;
preamble := ...; {* ‘1010...10,’ LSB to MSB*}
sfd := ...; {* ‘10101011,’ LSB to MSB*}
headerView := headerBits
end
end; {TransmitDataEncap}
If th
e MAC client chooses to generate the frame check sequence field for th e frame, it passes this field to the 
MAC sublayer via the fcsParam Value parameter. If the fcsParamPresent parameter is true, 
TransmitDataEncap uses the fcsParamValue parameter as the frame check sequence field for the frame. 
Such a frame shall not require any padding, since it is the responsibility of the MAC client to ensure that the 
frame meets the minFrameSize constrai nt. If the fcsParamPresent parame ter is false, the fcsParamValue 
parameter is unspecified. TransmitDataEncap first calls the ComputePad function, followed by a call to the 
CRC32 function to generate the padding (if necessary) and the frame check seque nce field for the frame 
internally to the MAC sublayer.
ComputePad appends an arra y of  arbitrary bits to the MAC client data to pad the frame to the minimum 
frame size:
function ComputePad(var dataPara m: DataValue): DataValue;
begin
ComputePad := {Append an array of size padSize of arbitrary bits to the MAC client dataField}
end; {ComputePad}
Transm
itLinkMgmt attempts to transmit the frame. When  deferenceMode is true, it first d e fers to the 
Physical Layer if it is not ready for the next pack et and to ensure proper interframe spacing. When 
deferenceMode is false, it begins transmitting immediately:

---
<!-- Page 662 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
588 Copyright © 2008 IEEE. All rights reserved.
function TransmitLinkMgmt: TransmitStatus;
begin
while deferring do nothing {Defer to Physical Lay er congestion and IFS}
StartTransmit;
while transmitting do nothi
 ng
LayerMgmtTransmitCounters; {Update transmit and transmit error counters in 5.2.4.2}
TransmitLinkMgmt := transmitOK
end; {TransmitLinkMgmt}
Each time a fram
e transmission attempt is initiated, StartTransmit is called to alert the BitTransmitter 
process that bit transmission shou
ld begin:
procedure StartTra nsmit;
begin
currentTransmitBit := 1;
lastTransmitBit := frameSize;
lastHeaderBit:= headerSize;
transmitting := true
end; {StartTransmit}
The Deferenc e 
process runs asynchronously to contin uously com put e the proper value for the variable 
deferring:
process Deference;
begin
cycle {Main loop}
whi
le (not transmitting and not (carrierSens eMode and carrierSense)) do nothing; {Wait for the start 
of transmission or congestion}
deferring := true; {Inhibit future transmissions}
while (transmitting or (carrierSenseMode and
  carrierSense)) do nothing; {Wait for the end of
transmission and congestion}
if deferenceMode then Wait(interPacketGap); 
{Time out entire interpacket 
gap if enabled}
deferring := false {Don’t inhibit transmission}
end {Main loop}
end; {Deference}
The BitT ran
smitter process runs asynchronously, transm itting bits at a rate determined by the Physical 
Layer’s TransmitBit operation:
process BitTransmitter;
begin
cycle {Outer loop
}
if transmitting then
begin
 {Inner loop}
while (currentTransmitBit  ≤ lastHeaderBit) do
begin
TransmitBit(outgoingHeader[currentTransmitBit]);
currentTransmitBit := currentTransmitBit + 1
end;
currentTransmitBit := 1;
while transmitting do
begin
TransmitB
it(outgoingFrame[currentTransmitBit]);
currentTransmitBit := currentTransmitBit + 1;
transmitting := (currentTransmitBit ≤ lastTransmitBi
 t)
end

---
<!-- Page 663 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 589
end {Inner loop}
end {Outer loop}
end; {BitTransmitter}
4A.2.9 Frame reception
The algorithms in this subclause define the MAC sublayer frame reception.
The function ReceiveFrame implements the frame reception operation provided to the MAC client.
The ReceiveFrame operation is sy
nchronous. The operation do es not complete until a frame has been 
received. The 
fields of the frame are delivered via the output parameters with the ReceiveStatus status code.
The receiveDisabled status indicates that the receiver is not enabled. Successful reception is indicated by the 
status code receiveOK. The frameT
ooLong error indicates th at the last frame received had a frameSize 
beyond the maximum allowable frame size. The code frameCheckError indicates that the frame received 
was damaged by a transmission error. The lengthError indicates that the lengthOrTypeParam value was both 
consistent with a length interpretation of this field (i.e ., its value was less than or equal to maxValidFrame), 
and inconsistent with the frameSize of the received frame. The code alignmentError indicates that the frame 
received was damaged, and that in addition, its length was not an integer number of octets. ReceiveStatus is 
not mapped to any MAC client parameter by the servi ce interface defined in 2.3.2. ReceiveStatus may be 
used in an implementation dependent manner.
function ReceiveFrame (
var destinationParam: AddressValue;
var sourceParam: AddressValue;
var lengt
hOrTypeParam: LengthOrTypeValue;
var dataParam: DataValu e;
var fcsParamValue: CRCValue;
var fcsParamPresent: Bit): ReceiveStatus;
functio
n ReceiveDataDecap: ReceiveStatus; {Nested fu nction; see body below}
begin
if receiveEnabled then
repeat
ReceiveLinkMgmt;
ReceiveFrame := ReceiveDataDecap;
unt
il receiveSucceeding
else ReceiveFrame := receiveDisabled
end; {ReceiveFrame}
If enabled, ReceiveFrame calls Rec
eiveLinkMgmt to receive the next valid frame, and then calls  the internal 
function ReceiveDataDecap to return th e frame’s fields to the MAC client  if the frame’s address indicates 
that it should do so. The returned ReceiveStatus indicates the presence or absence of detected transmission 
errors in the frame.
function ReceiveDataDecap: ReceiveStatus;
var status: ReceiveStatus; {Holds receive status information}
begi
n
with incomingFrame do
begin
view := fields;
receiveSucceeding := LayerMgmtRecognizeAddress(destinationField);
if receiveSucceeding then

---
<!-- Page 664 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
590 Copyright © 2008 IEEE. All rights reserved.
begin {Disassemble MAC frame}
destinationParam := destinationField;
sourceParam := sourceField;
lengthOrTypeParam := lengthOrTypeField;
dataParam := RemovePad(lengthOrTypeField, dataField);
fcsParamValue := fcsField;
fcsParamPresent := passReceiveFCSMode;
exceedsMaxLength := ...; {Check to determine if received MAC frame size 
 exceeds
maxFrameSizeLimit.
MAC implementations use maxFrameSizeLimit to
determine if management counts the frame as too long.
It is recommended that new implementations support
maxFrameSizeLimit = maxEnvelopeFrameSize )
if exceedsMaxLength then status := frameTooLong
else if fcsField 
= CRC32(incomingFrame) then
if validLeng
th then status := receiveOK else st atus := lengthError
else if excessBits = 0 then status := frameCheckError
else status := alignm
entError;
LayerMgmtReceiveCounters(status); {Update receive counters in 5.2.4.3}
view :
= bits
end {Disassemble MAC frame}
end; {With incomingFrame}
ReceiveDataDecap := status
end; {ReceiveDataDecap}
functio
n LayerMgmtReco gnizeAddress(address: AddressValue): Boolean;
begin
if {promiscuous receive enabled} then LayerMgmtRecognizeAddress := true;
else if address = ... {MAC station address} then LayerMgmtRecognizeAddress := true;
else if address = ... {Broadcast address} th en LayerMgmtRecognizeAddress := true;
else if address = ... {O ne of the addresses on the multicast list and multicast reception is enabled} then
LayerMgmtRecognizeAddress := true;
else LayerMgmtRecognizeAddress := false
end; {LayerMgmtRecognizeAddress}
The function Rem
ovePad strips any padding that was generated to meet t he minFrameSize constraint, if pos-
sible. When the MAC sublayer operates in the mode th at enables pass ing of the frame check sequence field 
of all received MAC frames to the MAC client (passRecei veFCSMode variable is true), it shall not strip the 
padding and it shall leave the data field of the MAC frame intact. Length checkin g is provided for Length 
interpretations of the Length/Type field. For Length /Type field values in the range between maxBasicData -
Size and minTypeValue the behavior of the RemovePad function is unspecified:
function RemovePa d(var lengthOrTypeParam: LengthOrTypeValue; dataParam: DataValue): DataValue; 
begin 
if lengthOrTypeParam ≥ minTypeValue then 
begin 
validLength := true; {Don’t perform length checking for Type field interpretations} 
RemovePad := dataParam 
end 
else if lengthOrTypeParam ≤ maxBasicDataSize then 
begin 
validLength := {For length interpretations of the Length/Type field, check to determine if value 
represented by Length/Type field matches the received clientDataSize}; 
if validLength and no t passReceiveFCSMode then 

---
<!-- Page 665 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 591
RemovePad := {Truncate the dataParam (when present) to the value represented by th e 
lengthOrTypeParam (in octets) and return the result} 
else RemovePad := dataParam 
end 
end; {RemovePad}
ReceiveLinkMgmt attempts repeatedly to receive the bits of a frame, discarding any fragments smaller than 
the minimum valid 
frame size:
procedure ReceiveLinkMgmt;
begin
repeat
StartReceive;
while receiving do nothing; {Wait for frame to finish arriving}
excessBits := frameSize mod 8;
frameSize := frameSize – excessBits; {Truncate to octet b oundary}
receiveSucceeding := (frameSize ≥ minFrameSize) {Reject frames too small}
until receiveSucceeding
end; {ReceiveLinkMgmt}
procedu
re StartReceive;
begin
receiving := true
end; {StartReceive}
The BitReceiver process runs asynchronously, receiving bits from the medium at the rate determined by the 
Physical Layer’s ReceiveBit operation, partitioning them into frames, and optionally receiving them:
process BitReceiver;
var b: Bit;
currentReceiveBit: 1..frameSize; {Position of current bit in incomingFrame}
begin
cycle
 {Outer loop}
if receiveEnabl
ed then
begin {Receive next 
frame from Physical Layer}
currentReceiveBit := 1;
PhysicalSignalDecap; {Skip idle, strip off preamble and 
sfd}
while receiveDataValid do
begin {Inner loop to receive 
the rest of an incoming frame}
b := ReceiveBit; {Next 
bit from physical medium}
if receiving then {Append to frame}
begin
incomingFrame[curre
ntReceiveBit] := b;
currentReceiveBit := currentReceiveBit + 1
end; {append bit to frame}
receiving := receiveDataValid
end; {Inner loop}
frameSize := currentReceiveBit 
– 1
end {Enabled}
end {Outer loop}
end; {BitReceiver}
procedure PhysicalSignalDecap;
begi
n
{Receive one bit at a time from physical medium until a valid sfd is detected, discard bits and return}
end; {PhysicalSignalDecap}

---
<!-- Page 666 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
592 Copyright © 2008 IEEE. All rights reserved.
4A.2.10 Common procedures
The function CRC32 is used by both the transmit and receive algorithms to generate a 32-bit CRC value:
function CRC32(f: Frame): CRCValue;
begin
CRC32 := 
{The 32-bit CRC for the entire frame as defined in 3.2.8, excluding the FCS field (if
present)}
end; {CRC32}
Purely to enhance readabil
ity, the following procedure is also defined:
procedure nothing; begin end ;
The idle state of a process (that is, while waiting for some event) is cast as repeated calls on this procedure.
4A.3 Interfaces to/from adjacent layers
4A.3.1 Overview
The purpose of this clause is to pr ovide precise definitions of the interf aces between the architectural layers 
defined in Clause 1 in compliance with the Media Access Service Specification given in Clause  2. In 
addition, 
the services required from the physical medium are defined.
The notation used here is the Pascal language, in keeping with the procedural nature of the precise MAC 
sublayer specification (see 4A.2). Each interface is des
cribed as a set of  procedures or shar ed variables, or 
both, that collectively provide the on ly valid interactions between layers. The accompanying text des cribes 
the meaning 
of each procedure or variable and points out any implicit interactions among them.
The description of the interfaces in Pascal is a notati onal tech nique, and in no way implies that they can or 
should be implemented in software. This point is discussed more fully in 4A.2, that provides complete 
Pascal declarations for the data types used in the rema inder of this clause. The synch ronous (one frame at a 
time) nature of the frame transmission and reception operations is a property of  the architectural interface 
between the MAC client and MAC s ublayers, and need not be reflec ted in the implementation interface 
between a station and its sublayer.
4A.3.2 MAC service
The services provided to the MAC client by the MAC sublayer are transmission and reception of MAC
frames using service primitives MA_DATA.request and MA_DATA.indication, as defined in Clause 2. For 
historical reasons the MAC sublay er definitions use tw o functions, Tran smitFrame and ReceiveFrame, 
defined in 4A.2.8 and 4A.2.9. The relationship between these two functions and the service primitives is 
defined by the MAC client state diagrams in 4A.3.2.1 and 4A.3.2.2.
4A.3.2.1 MAC client transmit interface state diagram
4A.3.2.1.1 Variables
data 
The value of mac_service_data_unit excluding the first two octets (Length/Type field).
destination_address 
The Destination Address field parsed from the client request.
fcsPresent 
Indi
cates whether the MA_DATA.request service primitive contained the frame_check_s equence 
field.
frame_check_sequence 
The fcs field parsed from the client request.

---
<!-- Page 667 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 593
lengthOrType 
The value of the first two octets at the start of the mac_service_data_unit.
mac_service_data_unit 
The concatenation of the lengthOrType field and the data field parsed from the client request.
source_address 
The Source Address field parsed from the client request.
TransmitStatus 
Indicates the status of the transmitted MAC frame. See 4.2.8.
4A.3.2.1.2 Functions
TransmitFrame 
The MAC sublayer function invoked to transmit a MAC frame with the specified parameters. See 
4A.2.8.
4A
.3.2.1.3 Messages
MA_DATA.request
The service primitive used to convey a MAC fram e to be transmi tted from the MAC client. See 
2.3.1.
4A.3.2.1.4 MAC client transmit interface state diagram
Figure 4A-3 specifies the behavior of the transmit interface from the MAC client.
4
A.3.2.2 MAC client receive interface state diagram
4A.3.2.2.1 Variables
destination_address 
The Destination Address field parsed from the received MAC frame.
Figure 4A–3—MAC client transmit interface state diagram
WAIT_FOR_TRANSMIT
TransmitFrame(
GENERATE_TRANSMIT_FRAME
BEGIN
source_address,
lengthOrType,
destination_address,
MA_DATA.request(
source_address,
mac_service_data_unit,
frame_check_sequence)
destination_address,
UCT
data,
frame_check_sequence,
fcsPresent): TransmitStatus

> **Figure 4A-3 Description — State Diagram (MAC Client Transmit Interface)**
> **Type:** State diagram
> **Visual content:** A two-state state diagram with BEGIN entry point.
> **States:** WAIT_FOR_TRANSMIT (initial state, shown as a rectangle with state name) and GENERATE_TRANSMIT_FRAME (rectangle with state name and action).
> **Transitions:** BEGIN → WAIT_FOR_TRANSMIT. WAIT_FOR_TRANSMIT → GENERATE_TRANSMIT_FRAME triggered by MA_DATA.request(destination_address, source_address, mac_service_data_unit, frame_check_sequence). GENERATE_TRANSMIT_FRAME → WAIT_FOR_TRANSMIT via UCT (Unconditional Transition), after calling TransmitFrame(destination_address, source_address, lengthOrType, data, frame_check_sequence, fcsPresent): TransmitStatus.
> **Key elements:** The diagram shows the MAC client's transmit behavior: it waits for a transmit request, then generates and transmits the frame, returning to wait state. The TransmitFrame call includes all frame parameters and returns a TransmitStatus.
> **Relationships shown:** Cyclic behavior between waiting for requests and generating/transmitting frames.
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
594 Copyright © 2008 IEEE. All rights reserved.
source_address 
The Source Address field parsed from the received MAC frame.
lengthOrType 
The lengthOrType field parsed from the received MAC frame.
data 
The data payload field parsed from the received MAC frame.
fcsP
resent 
A Boolean set by the MAC sublayer. 
ReceiveStatus 
Indicates the status of the received MAC frame. 
mac_service_data_unit 
The conca t
enation of the lengthOrType field a nd the data field parsed from the received MAC 
frame.
frame_check_sequence 
The fcs fiel
d parsed from the received MAC frame.
4A.3.2.2.2 Functions
ReceiveFrame 
The MAC sublayer function invoked to accept an incoming MA C fra m e with the specified 
parameters. See 4A.2.9.
4A.3.2.2.3 Messages
MA_DATA.indication
The service primitive used to transfer an inco ming MAC frame to the MAC client with the speci -
fied parameters. See 2.3.2.
4A.3.2.2.4 MAC client receive interface state diagram
Figure 4A-4 specifies the behavior of the receive interface to the MAC client.
Figure 4A–4—MAC client receive interface state diagram
WAIT_FOR_RECEIVE
MA_DATA.indication(
PASS_TO_CLIENT
BEGIN
source_address,
mac_service_data_unit,
frame_check_sequence,
ReceiveStatus)
destination_address,
ReceiveFrame(
source_address,
data,
frame_check_sequence,
fcsPresent): ReceiveStatus
destination_address,
lengthOrType,
UCT
ReceiveFrame()

> **Figure 4A-4 Description — State Diagram (MAC Client Receive Interface)**
> **Type:** State diagram
> **Visual content:** A two-state state diagram with BEGIN entry point.
> **States:** WAIT_FOR_RECEIVE (initial state, rectangle with state name and ReceiveFrame() action) and PASS_TO_CLIENT (rectangle with state name and action).
> **Transitions:** BEGIN → WAIT_FOR_RECEIVE. WAIT_FOR_RECEIVE → PASS_TO_CLIENT after ReceiveFrame(destination_address, source_address, lengthOrType, data, frame_check_sequence, fcsPresent): ReceiveStatus completes. PASS_TO_CLIENT → WAIT_FOR_RECEIVE via UCT (Unconditional Transition), after calling MA_DATA.indication(destination_address, source_address, mac_service_data_unit, frame_check_sequence, ReceiveStatus).
> **Key elements:** The diagram shows the MAC client's receive behavior: it waits for a frame via ReceiveFrame(), then passes the received frame to the client via MA_DATA.indication, returning to wait state.
> **Relationships shown:** Cyclic behavior between waiting for frames and delivering received frames to the client.
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 595
4A.3.3 Services required from the Physical Layer
The interface through which the MAC s ublayer uses the facilit ies of the Physical Layer consists of a 
function, a pair of procedures and four Boolean variables as described in Table 4A–1. 
During transmission, the contents of an outgoing fram e are passed from the M A C sublayer to the Physical 
Layer by way of repeated use of the TransmitBit operation:
procedure TransmitBit (bitParam: Bit);
Each invocation 
of TransmitBit passes one new bit of the outgoing fram e to the Physical Layer. The 
TransmitBit operation is synchronous. The duration of the operation is the entire transmission of the bit. The 
operation completes when the Physical Layer is ready to  accept the next bit and it transfers control to the 
MAC sublayer.
The overall event of data being transmitted is signal ed t o the Physical  Layer by way of the variable 
transmitting:
var transmitting: Boolean;
Before sending t
he first bit of a frame, the MAC sublayer sets transmitting to true, to inform the Physical 
Layer that a stream of bits will
 be presented via the TransmitBit operation. After the last bit of the frame has 
been presented, the MAC sublayer sets transmitting to false to indicate the end of the frame.
The collisionDetect variable is not used by this full duplex MAC but maintained as an artifact of the CSMA/
CD MAC’s interface to the Physical 
Layer.
var collisionDetect: Boolean;
During reception, the contents of an incoming frame are retrieved from the Physical Layer by the MAC 
sublayer via repeated use of the ReceiveBit operation:
function ReceiveBit: Bit;
Each invocation of ReceiveB it retrieves one new bit of the incoming  frame from the Physical Layer. The 
ReceiveBit operation is synchronous. Its duration is the entire reception of a single bit. Upon receiving a bit, 
the MAC sublayer shall immediately re quest the next bit until all bits of the frame have been received (see 
4A.2 for details).
The overall event of data being received is signaled to the MA C sublayer by the variable receiveDataValid:
var receiveDataValid: Boolean;
When the Physical Layer sets receiveDataValid to  true, the MAC sublayer shall immediately begin 
retrieving the incoming 
bits by the ReceiveBit operation. When recei veDataValid subsequently becomes 
false, the MAC sublayer can begin processing the recei ved bits as a completed frame. If an invocation of 
ReceiveBit is pending when receiveDataValid becomes false, ReceiveBit returns an undefined value, which 
should be discarded by the MAC sublayer (see 4A.2 for details).
Table 4A–1—Full duplex MAC functions, procedures and variables
Function Procedures Variables
ReceiveBit TransmitBit collisionDetect
Wait carrierSense
receiveDataValid
transmitting

---
<!-- Page 670 -->
---

IEEE 
Std 802.3-2008 REVISION OF IEEE Std 802.3:
596 Copyright © 2008 IEEE. All rights reserved.
The overall event of congestion at the Physical Layer,  indicating that the Physical Layer is not ready to 
accept the next packet, is signaled to the MAC sublayer by the variable carrierSense:
var carrierSense: Boolean;
When the value of variable carrierSenseMod
e is set to  TRUE, the MAC sublayer shall monitor the value of 
carrierSense to defer its own transm issions when the Physical Layer is busy. The Physical Layer sets 
carrierSense to true immediately upo n congestion within the Physical Layer. After the congestion ceases, 
carrierSense is set to false. When the value of variab le carrierSenseMode is set to FALSE, the carrierSense 
variable is ignored by the MAC.
While the label carrierSense does not accu rately describe the condition presented by this variable, the name 
is maintained as
 an artifact of the CSMA/CD MAC interface to the Physical Layer.
The Physical Layer also provides the procedure Wait:
procedur
e Wait (bit Times: integer);
This procedure waits for the specified  number of bit tim es. This allows the MAC sublayer to measure time 
intervals in units of the (physical-medium-dependent) bit time.
4A.4 Specific implementations
4A.4.1 Compatibility overview
To provide total compatibility at all levels of the standard, it is required that each network component 
implementing the MAC sublayer pr ocedure adheres rigidly to thes e specifications. The information 
provided in 4A.4.2 provides design parameters for specifi c implementatio ns of this access method. 
Variations from these values 
result in a system implementation that  violates the standard. See the warning in 
4A.4.2.
4A.4.2 MAC parameters
The parameter values shown in Table 4A–2 shall be used. 
The minimum interPacketGap shall be enforced in this sublayer, when the deferenceMode variable is set to 
TRUE, 
or outside this sublayer, when the deferenceMode variable is set to FALSE.
NOTE 1—For 10 Mb/s operation, the spacing between two successive non-colliding packets, from start of idle at the end 
of the first packet to start of Preamble  of the subsequent packet, can have a minimum value of 47 BT (bit times), at the 
AUI receive line of the DTE. This interPacketGap shrinkage is caused by variable network delays, added preamble bits, 
and clock skew.
NOTE 2—For 1 Gb/s operation, the spacing be tween two non-colliding packets, from the last bit of the FCS field of the 
first packet to the first bit of the Preamble of the second packet, can have a minimum value of 64 BT (bit times), as mea-
sured at the GMII receive signals at the DTE. This interPacketGap shrinkage may be caused by variable network delays, 
added preamble bits, and
 clock tolerances.
Table 4A–2—Full duplex MAC parameter values
Parameters Values
interPacketGap 96 bits
maxBasicFrameSize 1518 octets
maxEnvelopeFrameSize 200 0 octets
minFrameSize 512 bits (64 octets)

---
<!-- Page 671 -->
---

IEEE 
CSMA/CD Std 802.3-2008
Copyright © 2008 IEEE. All rights reserved. 597
NOTE 3—For 10 Gb/s operation, the spacing be tween two packets, from the last bit of the FCS field of the first packet 
to the first bit of the Preamble of the second packet, can have a minimum value of 40 BT (bit times), as measured at the 
XGMII receive signals at the DTE. This interPacketGap shrinkage may be caused by variable network delays and clock 
tolerances.
WARNING
Any deviation from the above specified values may affect proper operation of the network.

---

## Rendered page image descriptions

Detailed page-image descriptions for this annex are available in [IMAGE_DESCRIPTIONS.md](IMAGE_DESCRIPTIONS.md). The key visual content is:

- Figure 4A-1: MAC procedure architecture and process interaction diagram.
- Figure 4A-2a: transmit control-flow summary for TransmitFrame.
- Figure 4A-2b: receive control-flow summary for ReceiveFrame.
- Figure 4A-2c: bit-level transmit/receive and deferral flowcharts.
- Figure 4A-3: MAC client transmit interface state diagram.
- Figure 4A-4: MAC client receive interface state diagram.
- Table 4A-1: functions, procedures, and variables used by the annex.
- Table 4A-2: normative full duplex MAC parameter values, including interPacketGap and frame-size limits.
