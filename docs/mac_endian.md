# MAC Endianness — Network Byte Order

**The RTL is big-endian (IEEE 802.3 network byte order).** The first octet
transmitted on the wire sits in the **lowest byte lane** of a beat
(`tdata[7:0]`) and is the **most significant byte** of every multi-byte field.

## 1. What "endianness" means here

"Endianness" is not about the 512-bit `tdata` vector — it's about **byte
ordering** within the stream. The rule is one line:

> Byte 0 of the frame = `tdata[7:0]` = first byte on the wire = MSB of its field.

## 2. Header fields (evidence from the RTL)

`rx_header_extract.sv:85-93`:

```systemverilog
// Header fields are big-endian: the first wire octet (lowest lane) is the most
// significant byte.
dest_addr   <= { in_data[ 0*8 +: 8], in_data[ 1*8 +: 8], ... in_data[ 5*8 +: 8] };
src_addr    <= { in_data[ 6*8 +: 8], ... };
length_type <= { in_data[12*8 +: 8], in_data[13*8 +: 8] };
```

The concat places lane 0's byte into the **MSB** of the 48-bit `dest_addr`.
Also:

- `rx_length_check.sv:126` — "Big-endian: the first wire octet (lane 12) is the
  most significant."
- `mac_control_top.sv:163-164` — "Fields are big-endian: lane 0 is the MSB"
  (control opcode high byte in lane 0, PAUSE time in lanes 2-3).

## 3. Concrete example

DA `01:02:03:04:05:06`, SA `AA:BB:CC:DD:EE:FF`, Length/Type `0x0800`:

```
lane:    0    1    2    3    4    5    6    7    8    9   10   11   12   13
byte:   0x01 0x02 0x03 0x04 0x05 0x06 0xAA 0xBB 0xCC 0xDD 0xEE 0xFF 0x08 0x00
                 dest_addr=48'h010203040506   src_addr=48'hAABBCCDDEEFF  LT=16'h0800
```

## 4. The wire order (MAC side)

- `tx_frame_builder` emits preamble `0x55` at lanes 0-6, SFD `0xD5` at lane 7,
  then **body byte 0 at lane 8**.
- `rx_preamble_detect` strips preamble/SFD and **re-aligns the body to lane 0**.

So preamble/SFD precede the header on the wire, and after stripping them the
first header octet is again lane 0 / MSB.

## 5. FCS / CRC byte order

IEEE 802.3 Clause 3.2.9: the FCS is transmitted with its **most significant
octet first** (the octet carrying CRC bits 31:24).

The RTL matches:

- `crc32_pkg.update_bytes` processes valid lanes in order `0,1,2,...` (first
  byte on the wire first).
- `rx_crc_check.shift_last4` builds the received-FCS window as
  `{v[23:0], data[lane*8 +: 8]}` — the first-transmitted FCS octet ends up in
  the MSB of `received_fcs`.

Example: CRC value `0x11223344` is transmitted as bytes `11 22 33 44`
(octet 0x11 first, lane 0 of the final beat first).

## 6. Driving rule for the testbench

When driving from the AXI-Stream side:

1. First frame byte in `tdata[7:0]` of the first beat (lane 0).
2. Subsequent bytes in ascending lanes.
3. Multi-byte fields big-endian: `dest_addr[47:40]` is the first byte you send.
4. Same layout as the `drive_frame()` example in
   `doc/interface/axi4-stream_examples.md` — it already builds beats
   lane-by-lane from byte 0.

## 7. Comparison cheat sheet

| Item | Byte order | RTL evidence |
|---|---|---|
| DA/SA (48-bit) | first octet = MSB | `rx_header_extract.sv:89-90` |
| Length/Type (16-bit) | first octet = MSB | `rx_header_extract.sv:93`, `rx_length_check.sv:126` |
| Control opcode / PAUSE time | first octet = MSB | `mac_control_top.sv:163-164` |
| FCS (32-bit) | first octet = MSB | `rx_crc_check.sv:108`, `crc32_pkg` |
| Preamble/SFD | generated, prepended | `tx_frame_builder.sv:219-222` |
