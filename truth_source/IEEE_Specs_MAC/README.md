# IEEE 802.3 MAC-Related Specifications

This directory contains extracted MAC-related clauses and annexes from the IEEE 802.3-2008 standard and amendments.

## Structure

### Core Clauses

- **Clause2_MAC_Service/** - MAC Service Specification
  - `Clause2_MAC_Service_Specification.md` (134 lines)
  - Source: 802.3-2008_section1.pdf, starts at PDF page ~235

- **Clause3_MAC_Frame/** - MAC Frame and Packet Specifications
  - `Clause3_MAC_Frame_Spec.md` (235 lines)
  - Source: 802.3-2008_section1.pdf, starts at PDF page ~239

- **Clause4_MAC/** - Media Access Control (MAC)
  - `Clause4_MAC.md` (608 lines)
  - Source: 802.3-2008_section1.pdf, starts at PDF page ~245

- **Clause31_MAC_Control/** - MAC Control
  - `Clause31_MAC_Control.md` (426 lines)
  - Source: 802.3-2008_section2.pdf, starts at PDF page ~1207

### Annexes

- **Annex4A_MAC_Control/** - MAC Control (simplified)
  - `Annex4A_from_section5.md` (1,370 lines)
  - `Annex4A_from_802.3ba.md` (22 lines, amendment note)
  - Source: IEEE Std 802.3-2008 Annex 4A in section1
  - Amendment: 802.3ba-2010 adds the 40/100 Gb/s NOTE 4 update

- **Annex31A_Opcode/** - MAC Control Opcode Assignment
  - `Annex31A_from_section2.md` (153 lines)
  - Source: IEEE Std 802.3-2008 section2, Annex 31A

- **Annex31B_Pause/** - MAC Control PAUSE Operation
  - `Annex31B_from_section2.md` (313 lines, base annex)
  - `Annex31B_from_802.3ba.md` (74 lines, amendment)
  - Base source: IEEE Std 802.3-2008 section2, Annex 31B
  - Amendment source: IEEE Std 802.3ba-2010, timing updates for 10/40/100 Gb/s

- **AnnexK_MAC_Sublayer/** - MAC Sublayer (placeholder)
  - Not found in available PDFs
  - May be in a different amendment or section

- **Annex31C_Organization/** - MAC Control Organization (placeholder)
  - Not found in available PDFs
  - May be in a different amendment

- **Annex31D_PFC/** - MAC Control Priority Flow Control (placeholder)
  - Not found in available PDFs
  - Likely in 802.1Qaz or later amendment (not in 802.3-2008)

## Source PDFs

- `802.3-2008_section1.pdf` - Clauses 1-20, Annex A-H, Annex 4A (671 pages)
- `802.3-2008_section2.pdf` - Clauses 21-33, Annex 22A-33E (790 pages)
- `802.3-2008_section5.pdf` - Clauses 56-74, Annex 57A-74A (615 pages)
- `802.3ba-2010.pdf` - 40 Gb/s and 100 Gb/s amendment (457 pages)

## Processing Notes

- Section 1 processed with opendataloader-pdf (born-digital, standard options)
- Sections 2 and 5 processed with pypdf (opendataloader had Java sorting bug)
- 802.3ba-2010 processed with pypdf
- All clause and annex truth-source files include page markers and appended figure/table descriptions where applicable

## Missing Annexes

The following annexes were not found in the available PDFs:
- **Annex K** - May be in a different IEEE 802.3 section or amendment
- **Annex 31C** - MAC Control Organization (not in 802.3-2008)
- **Annex 31D** - Priority Flow Control (PFC) - This is actually defined in IEEE 802.1Qaz, not 802.3

To find these, you may need:
- Additional IEEE 802.3 amendments (802.3bc, 802.3bd, etc.)
- IEEE 802.1Qaz for Priority Flow Control
- Complete IEEE 802.3 standard (all sections)
