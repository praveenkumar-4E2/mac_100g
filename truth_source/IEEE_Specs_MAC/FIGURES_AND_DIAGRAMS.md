# Figures and Diagrams in MAC Clauses

## Summary
The MAC clauses contain **many figures and state diagrams**, but these are **visual graphics embedded in the PDF** that don't extract as text. They only exist in the rendered page images.

---

## Clause 2: MAC Service Specification

### Figures
- **Figure 2-1**: Service specification primitive relationships
  - Shows MAC client, MA_DATA.request, MA_DATA.indication
  - Visual diagram of service primitive flow
  - **Location**: page_118.png or page_119.png

### Markdown Content
The markdown file references Figure 2-1 but only contains the text description, not the actual diagram.

---

## Clause 3: MAC Frame and Packet Specifications

### Figures
- **Figure 3-1**: Packet format
  - Visual diagram showing: PREAMBLE, SFD, DESTINATION ADDRESS, SOURCE ADDRESS, MAC CLIENT DATA, PAD, EXTENSION, FCS
  - **Location**: page_124.png or page_125.png

- **Figure 3-2**: Service primitive mappings
  - Shows mapping of service interface parameters to MAC frame fields
  - **Location**: page_125.png or page_126.png

- **Figure 3-3**: Address field format
  - Visual representation of address field structure
  - **Location**: page_126.png

### Markdown Content
The markdown references all three figures but only contains text descriptions like:
- "Figure 3-1 shows the fields of a packet..."
- "Figure 3-2 shows the mapping..."
- "Figure 3-3 shows the address field format..."

The actual visual diagrams are NOT in the markdown.

---

## Clause 4: Media Access Control (MAC)

### Figures (Many!)
- **Figure 4-1**: Relationship among CSMA/CD procedures
  - Static structure diagram showing how processes interact
  
- **Figure 4-2a**: Control flow summary (part 1)
  - Dynamic behavior flowchart
  
- **Figure 4-2b**: Control flow summary (part 2)
  - Continuation of control flow
  
- **Figure 4-3a**: Control flow (part 1)
  - Detailed control flow diagram
  
- **Figure 4-3b**: Control flow (part 2)
  - Continuation of detailed control flow
  
- **Figure 4-4**: Packet bursting
  - Example of burst operation
  
- **Figure 4-5**: Frame with carrier extension
  - Shows carrier extension mechanism

### State Diagrams
The Pascal procedural model in Clause 4 implies state machine behavior, though it's expressed as code rather than visual state diagrams.

### Markdown Content
The markdown contains:
- Complete Pascal code for the procedural model
- Text descriptions referencing all figures
- But NO actual visual diagrams

The visual diagrams are only in the page images (page_129.png through page_145.png).

---

## Clause 31: MAC Control

### Figures
- **Figure 31-1**: Architectural positioning of MAC Control sublayer
  - Shows relationship between MAC Control, MAC, and clients
  - **Location**: page_421.png or page_422.png

- **Figure 31-2**: MAC Control sublayer support of interlayer service interfaces
  - Shows interlayer interface usage
  - **Location**: page_422.png or page_423.png

- **Figure 31-3**: MAC Control frame format
  - Visual frame format diagram showing all fields
  - **Location**: page_424.png or page_425.png

- **Figure 31-4**: Generic MAC Control Receive state diagram
  - **THIS IS A STATE DIAGRAM**
  - Shows states: WAIT FOR RX, CHECK TYPE, PASS TO CLIENT, etc.
  - Shows state transitions and conditions
  - **Location**: page_428.png or page_429.png

### State Diagrams
Clause 31 explicitly states:
> "The body of this clause and its associated annexes contain state diagrams, including definitions of variables, constants, and functions. Should there be a discrepancy between a state diagram and descriptive text, the state diagram shall prevail."

The markdown contains:
- Text description of the state diagram
- Variable and constant definitions
- State transition descriptions
- But NOT the actual visual state diagram

The visual state diagram (Figure 31-4) is ONLY in the page images.

---

## Why Aren't Diagrams in the Markdown?

The PDFs are **born-digital** with:
1. **Text layer**: Selectable text that extracts to markdown
2. **Graphics layer**: Vector graphics and embedded images (figures, diagrams)

When we extract text with PyMuPDF or opendataloader-pdf:
- ✅ Text is extracted perfectly
- ❌ Vector graphics are NOT extracted (they're not text)
- ❌ Embedded images are NOT extracted (unless specifically requested)

The page images we rendered (PNG files) capture BOTH layers:
- ✅ Text (as visual text)
- ✅ Graphics (as visual graphics)
- ✅ Complete page layout

---

## What You Have

For each clause folder:

1. **Markdown file** (*.md)
   - ✅ All text content
   - ✅ All table data (as text)
   - ✅ All code (Pascal model)
   - ❌ No visual diagrams
   - ❌ No state diagram graphics

2. **Page images** (page_images/*.png)
   - ✅ Complete visual representation
   - ✅ All figures and diagrams
   - ✅ All state diagrams
   - ✅ All tables (visual format)
   - ✅ Original PDF layout

---

## How to View the Diagrams

To see the actual figures and state diagrams:

1. Open the page images in the `page_images/` folder
2. Find the page number mentioned in the markdown
3. The diagram will be visible on that page

Example for Clause 31 state diagram:
- Markdown says: "Figure 31-4—Generic MAC Control Receive state diagram"
- Look at: `Clause31_MAC_Control/page_images/page_428.png` or `page_429.png`
- You'll see the actual state diagram with states and transitions

---

## Summary

**Do these clauses have state diagrams and diagrams?**
✅ YES - Many figures and state diagrams

**Are they in the markdown files?**
❌ NO - Only text references to the figures

**Where are the actual diagrams?**
✅ In the page images (PNG files)

**Why?**
The PDFs have text and graphics as separate layers. Text extraction only gets the text layer. The graphics layer (diagrams) is only visible when you render the page as an image.

---

## Recommendation

If you need the diagrams as separate image files (not full page renders), you can:
1. Use the page images we already created
2. Crop them to extract just the diagram portions
3. Or use a PDF library to extract embedded images (though many IEEE diagrams are vector graphics, not embedded images)

For most use cases (RAG, analysis, reference), the full page images are sufficient.
