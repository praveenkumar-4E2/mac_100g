# Annex 31A Page Image Descriptions

Source pages: IEEE Std 802.3-2008 section2, Annex 31A pages 737-740.

This file captures the content of the page images so the opcode tables and operand semantics can be reviewed without reopening the scans.

## Page image summary

- `page_0737.png`: Table 31A-1, the opcode assignment table. It lists the defined 2-octet MAC Control opcodes, their function names, the reference annex or clause, short semantic notes, and whether a timestamp is present. The table explicitly reserves 00-00 and 00-07 through FF-FF.

- `page_0738.png`: Table 31A-2, PAUSE indications; Table 31A-3, GATE indications; Table 31A-4, REPORT indications. These pages define the opcode-specific operand semantics used by `MA_CONTROL.indication`.

- `page_0739.png`: Table 31A-5, REGISTER_REQ indications; Table 31A-6, REGISTER indications; start of Table 31A-7, REGISTER_ACK indications.

- `page_0740.png`: continuation of Table 31A-7, completing the REGISTER_ACK indication operand list.

## Key tables

- Table 31A-1: opcode map for PAUSE, GATE, REPORT, REGISTER_REQ, REGISTER, and REGISTER_ACK.
- Table 31A-2: PAUSE status values `paused` and `not_paused`.
- Table 31A-3: GATE operands `start`, `length`, `status`, `force_report`, and `discovery`.
- Table 31A-4: REPORT operands `RTT`, `n`, `report_list valid[8]`, and `status[8]`.
- Table 31A-5: REGISTER_REQ operands `status`, `flags`, `pending_grants`, and `RTT`.
- Table 31A-6: REGISTER operands `SA`, `ID`, and `status`.
- Table 31A-7: REGISTER_ACK operands `SA`, `ID`, `status`, and `RTT`.

## Practical RTL relevance

This annex is the authoritative opcode map for MAC Control. It is directly useful for decoding control frames and mapping the control opcode field to MAC Control behavior.
