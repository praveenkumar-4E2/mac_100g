//==============================================================================
// File       : rtl/mac_speed_params_pkg.sv
// Module     : mac_speed_params_pkg
// Purpose    : Validated speed-dependent defaults for reusable MAC blocks
//              (synthesizable combinational mux functions)
// IEEE Ref   : IEEE 802.3ba Clause 4 Table 4-2
// Dependencies: —
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-4.2: Converted automatic functions to synthesizable mux logic
//==============================================================================

`default_nettype none

package mac_speed_params_pkg;
  // Speed encoding (IEEE 802.3 Clause 4, Table 4-2)
  // 0 = 10G, 1 = 25G, 2 = 40G, 3 = 50G, 4 = 100G

  //----------------------------------------------------------------------------
  // Function: tx_ipg_for_speed
  // Purpose:  Return IPG value (in bit-times) for given speed
  //           All speeds use 96 bit-times IPG
  //----------------------------------------------------------------------------
  function automatic int unsigned tx_ipg_for_speed(input int unsigned speed);
    case (speed)
      0, 1, 2: tx_ipg_for_speed = 96;
      3:       tx_ipg_for_speed = 96;
      4:       tx_ipg_for_speed = 96;
      default: tx_ipg_for_speed = 0;
    endcase
  endfunction

  //----------------------------------------------------------------------------
  // Function: pause_delay_for_speed
  // Purpose:  Return PAUSE delay (in bit-times) for given speed
  //   10G/25G: 394 bit-times, 40G/50G: 118 bit-times, 100G: 60 bit-times
  //----------------------------------------------------------------------------
  function automatic int unsigned pause_delay_for_speed(input int unsigned speed);
    case (speed)
      0:       pause_delay_for_speed = 394;
      1:       pause_delay_for_speed = 394;
      2:       pause_delay_for_speed = 118;
      3:       pause_delay_for_speed = 118;
      4:       pause_delay_for_speed = 60;
      default: pause_delay_for_speed = 0;
    endcase
  endfunction

  //----------------------------------------------------------------------------
  // Function: supported_data_width
  // Purpose:  Check if data width is supported
  //----------------------------------------------------------------------------
  function automatic bit supported_data_width(input int unsigned width);
    supported_data_width = (width == 8) || (width == 16) || (width == 32) ||
                           (width == 64) || (width == 128) || (width == 256) ||
                           (width == 512);
  endfunction
endpackage

`default_nettype wire