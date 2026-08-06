//==============================================================================
// File       : rtl/registers/reg_file.sv
// Module     : reg_file
// Purpose    : APB-domain configuration register file with group address filter
// IEEE Ref   : —
// Dependencies: reg_map_pkg
// Author     : —
// Revision History:
//   2026-07-29 — Reformatted to AGENTS.md standard
//   2026-07-29 — T-2.1: Added PAUSE TX config register read/write logic
//   2026-07-29 — T-3.1: Added cfg_promiscuous_mode output (Bit 7 of REG_GLOBAL_CONTROL)
//   2026-07-29 — T-4.1: Added cfg_mac_speed and cfg_speed_override outputs (REG_MAC_SPEED_CONFIG)
//   2026-07-29 — T-6.1: Added cfg_max_frame_size and cfg_min_frame_size outputs
//==============================================================================

`default_nettype none

module reg_file #(
  parameter int unsigned GROUP_COUNT = 4
) (
  input  logic        apb_clk,
  input  logic        apb_rst,
  input  logic        write_valid,
  input  logic [15:0] write_addr,
  input  logic [31:0] write_data,
  output logic        cfg_write,
  output logic [31:0] cfg_control,
  output logic [47:0] cfg_mac_addr,
  output logic [15:0] cfg_max_client_data,
  output logic        cfg_pause_tx_enable,
  output logic        cfg_pause_tx_soft_req,
  output logic [15:0] cfg_pause_quanta,
  output logic        cfg_promiscuous_mode,
  output logic [2:0]  cfg_mac_speed,
  output logic        cfg_speed_override,
  output logic [15:0] cfg_max_frame_size,
  output logic [15:0] cfg_min_frame_size,
  output logic [GROUP_COUNT-1:0][47:0] cfg_group_addr,
  output logic [GROUP_COUNT-1:0]       cfg_group_valid
);

  //============================================================================
  // Module     : reg_file
  // Parameters :
  //   GROUP_COUNT = 4 — Number of address filter groups
  // Inputs     :
  //   apb_clk        — APB clock
  //   apb_rst        — APB reset (synchronous, active high)
  //   write_valid    — APB write strobe
  //   write_addr     — APB write address
  //   write_data     — APB write data
  // Outputs    :
  //   cfg_write          — Config write strobe
  //   cfg_control        — Global control register
  //   cfg_mac_addr       — MAC address register
  //   cfg_max_client_data — Max client frame data octets
  //   cfg_pause_tx_enable   — PAUSE TX enable (Bit 0 of REG_PAUSE_TX_CONFIG)
  //   cfg_pause_tx_soft_req — PAUSE TX soft request (Bit 1 of REG_PAUSE_TX_CONFIG)
  //   cfg_pause_quanta      — PAUSE quanta value [15:0] (Bits 15:0 of REG_PAUSE_TX_CONFIG)
  //   cfg_promiscuous_mode  — Promiscuous mode enable (Bit 7 of REG_GLOBAL_CONTROL)
  //   cfg_mac_speed         — MAC speed select [2:0] (000=10G, 001=25G, 010=40G, 011=50G, 100=100G)
  //   cfg_speed_override    — Speed override enable (Bit 3 of REG_MAC_SPEED_CONFIG)
  //   cfg_max_frame_size    — Max frame size [15:0] (default 1518)
  //   cfg_min_frame_size    — Min frame size [15:0] (default 64)
  //   cfg_group_addr     — Group address filter table
  //   cfg_group_valid    — Group address filter valid bits
  // Dependencies: reg_map_pkg
  // Timing    : 1 cycle
  // Reset     : synchronous, active high
  // Clock     : apb_clk
  //============================================================================

  import reg_map_pkg::*;

  always_ff @(posedge apb_clk) begin
    if (apb_rst) begin
      cfg_write              <= 1'b0;
      cfg_control            <= '0;
      cfg_control[6]         <= 1'b1;
      cfg_mac_addr           <= '0;
      cfg_max_client_data    <= 16'd1500;
      cfg_pause_tx_enable    <= 1'b0;
      cfg_pause_tx_soft_req  <= 1'b0;
      cfg_pause_quanta       <= '0;
      cfg_promiscuous_mode   <= 1'b0;
      cfg_mac_speed          <= 3'b100;  // Default: 100G
      cfg_speed_override     <= 1'b0;
      cfg_max_frame_size     <= 16'd1518;  // Default: Ethernet max frame
      cfg_min_frame_size     <= 16'd64;    // Default: Ethernet min frame
    end else begin
      cfg_write <= 1'b0;
      if (write_valid && is_valid_address(write_addr, GROUP_COUNT)) begin
        cfg_write <= 1'b1;
        unique case (write_addr)
          REG_GLOBAL_CONTROL:      cfg_control            <= write_data;
          REG_MAC_ADDR_LOW:        cfg_mac_addr[31:0]     <= write_data;
          REG_MAC_ADDR_HIGH:       cfg_mac_addr[47:32]    <= write_data[15:0];
          REG_MAX_CLIENT_DATA:     cfg_max_client_data    <= write_data[15:0];
          REG_PAUSE_TX_CONFIG: begin
            cfg_pause_tx_enable    <= write_data[PAUSE_TX_ENABLE_BIT];
            cfg_pause_tx_soft_req  <= write_data[PAUSE_TX_SOFT_REQ_BIT];
            cfg_pause_quanta       <= write_data[15:0];
          end
          REG_MAC_SPEED_CONFIG: begin
            cfg_mac_speed          <= write_data[2:0];
            cfg_speed_override     <= write_data[SPEED_OVERRIDE_BIT];
          end
          REG_MAX_FRAME_SIZE:     cfg_max_frame_size     <= write_data[15:0];
          REG_MIN_FRAME_SIZE:     cfg_min_frame_size     <= write_data[15:0];
          default:                 /* no action */;
        endcase
      end
    end
  end

  generate
    for (genvar i = 0; i < GROUP_COUNT; i++) begin : g_group_regs
      always_ff @(posedge apb_clk) begin
        if (apb_rst) begin
          cfg_group_addr[i]  <= '0;
          cfg_group_valid[i] <= 1'b0;
        end else if (write_valid && is_valid_address(write_addr, GROUP_COUNT)) begin
          if (write_addr == group_low_addr(i)) begin
            cfg_group_addr[i][31:0] <= write_data;
          end
          if (write_addr == group_high_addr(i)) begin
            cfg_group_addr[i][47:32] <= write_data[15:0];
            cfg_group_valid[i]       <= write_data[16];
          end
        end
      end
    end
  endgenerate

endmodule

`default_nettype wire