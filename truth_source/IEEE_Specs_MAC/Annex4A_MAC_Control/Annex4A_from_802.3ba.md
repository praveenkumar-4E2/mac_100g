# Annex 4A Amendment — from 802.3ba-2010

> Source: 802.3ba-2010.md, Pages 379-380 (PDF pages)
> This is an amendment to Annex 4A, adding NOTE 4 for 40 Gb/s and 100 Gb/s operation.

NOTE—This annex is numbered in corres pondence to its associated clause; i.e., Annex 4A corresponds to Clause 4.
Annex 4A
(normative) 
Simplified full duplex media access control 
This annex is based on the Clause 4 MAC, with simpli fications for use in networks that do not require the
half duplex operational mode. Additional functionality is included for managing Physical Layer congestion
and for support of interframe spacing outside this sublayer. This annex stands alone and does not rely on
information within Clause 4 to be implemented.
4A.4.2 MAC parameters
Insert the following note below Table 4A-2 (above the warning box) for 40 Gb/s and 100 Gb/s MAC data
rates, and renumber notes as appropriate:
NOTE 4— For 40 Gb/s and 100 Gb/s operation, the received interPacketGap (the spacing between two packets, from the
last bit of the FCS field of the first packet to the first bit of the Preamble of the second packet) can have a minimum value
of 8 BT (bit times), as measured at the XLGMII or CGMII receive signals at the DTE due to clock tolerance and lane
alignment requirements.

---
