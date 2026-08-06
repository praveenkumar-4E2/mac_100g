//==============================================================================
// File       : rtl/registers/apb_interrupt.sv
// Module     : apb_interrupt
// Purpose    : APB domain interrupt enable/status/clear register interface
// IEEE Ref   : —
// Dependencies: reg_map_pkg
// Author     : —
// Revision History:
//   2026-07-28 — Reformatted to AGENTS.md standard
//==============================================================================

`default_nettype none

module apb_interrupt (
  input  logic        apb_clk,
  input  logic        apb_rst,
  input  logic        write_valid,
  input  logic [15:0] write_addr,
  input  logic [31:0] write_data,
  output logic [31:0] enable,
  output logic        enable_write,
  output logic [6:0]  clear_mask,
  output logic        clear_write,
  output logic [2:0]  counter_clear_mask,
  output logic        counter_clear_write
);

  //============================================================================
  // Module     : apb_interrupt
  // Parameters : (none)
  // Inputs     :
  //   apb_clk         — APB clock
  //   apb_rst         — APB reset (synchronous, active high)
  //   write_valid     — APB write strobe
  //   write_addr      — APB write address
  //   write_data      — APB write data
  // Outputs    :
  //   enable          — Interrupt enable register
  //   enable_write    — Interrupt enable write strobe
  //   clear_mask      — Interrupt status clear mask
  //   clear_write     — Interrupt status clear write strobe
  //   counter_clear_mask  — Statistics counter clear mask
  //   counter_clear_write — Statistics counter clear write strobe
  // Dependencies: reg_map_pkg
  // Timing    : 1 cycle
  // Reset     : synchronous, active high
  // Clock     : apb_clk
  //============================================================================

  import reg_map_pkg::*;

  always_ff @(posedge apb_clk) begin
    if (apb_rst) begin
      enable             <= '0;
      enable_write       <= 1'b0;
      clear_mask         <= '0;
      clear_write        <= 1'b0;
      counter_clear_mask <= '0;
      counter_clear_write<= 1'b0;
    end else begin
      enable_write       <= 1'b0;
      clear_write        <= 1'b0;
      counter_clear_write<= 1'b0;

      if (write_valid && (write_addr == REG_INTERRUPT_ENABLE)) begin
        enable       <= write_data;
        enable_write <= 1'b1;
      end

      if (write_valid && (write_addr == REG_INTERRUPT_STATUS)) begin
        clear_mask  <= write_data[6:0];
        clear_write <= 1'b1;
      end

      if (write_valid) begin
        unique case (write_addr)
          REG_RX_INVALID_COUNT: begin
            counter_clear_mask  <= { 2'b00, write_data[0] };
            counter_clear_write <= write_data[0];
          end
          REG_RX_OVERSIZE_COUNT: begin
            counter_clear_mask  <= { 1'b0, write_data[0], 1'b0 };
            counter_clear_write <= write_data[0];
          end
          REG_RX_UNSUPPORTED_COUNT: begin
            counter_clear_mask  <= { write_data[0], 2'b00 };
            counter_clear_write <= write_data[0];
          end
          default: begin end
        endcase
      end
    end
  end

endmodule

`default_nettype wire