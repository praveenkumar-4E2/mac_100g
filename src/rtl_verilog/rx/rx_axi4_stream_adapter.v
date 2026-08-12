`default_nettype none
module rx_axi4_stream_adapter #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 8,
    parameter frame_end_byte_index_W = $clog2(KEEP_WIDTH + 1)
) (
    input wire clk,
    input wire rst,
    input wire mac_valid,
    output wire mac_ready,
    input wire [DATA_WIDTH-1:0] mac_data,
    input wire [KEEP_WIDTH-1:0] mac_keep,
    input wire mac_sop,
    input wire mac_eop,
    input wire [frame_end_byte_index_W-1:0] mac_frame_end_byte_index,
    input wire mac_error,
    input wire mac_fcs_valid,
    output wire [DATA_WIDTH-1:0] m_tdata,
    output wire [KEEP_WIDTH-1:0] m_tkeep,
    output wire m_tvalid,
    input wire m_tready,
    output wire m_tlast,
    output wire [7:0] m_tuser
);
  assign mac_ready = m_tready;
  assign m_tdata   = mac_data;
  assign m_tvalid  = mac_valid;
  assign m_tlast   = mac_eop;
  assign m_tuser   = {6'b0, mac_fcs_valid, mac_error};
  assign m_tkeep   = mac_eop ? mac_keep : {KEEP_WIDTH{1'b1}};
endmodule
`default_nettype wire
