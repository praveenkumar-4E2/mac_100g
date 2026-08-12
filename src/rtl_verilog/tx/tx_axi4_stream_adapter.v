`default_nettype none
module tx_axi4_stream_adapter #(
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = DATA_WIDTH / 8,
    parameter frame_end_byte_index_W = $clog2(KEEP_WIDTH + 1)
) (
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] s_tdata,
    input wire [KEEP_WIDTH-1:0] s_tkeep,
    input wire s_tvalid,
    output wire s_tready,
    input wire s_tlast,
    input wire [7:0] s_tuser,
    output wire mac_valid,
    input wire mac_ready,
    output wire [DATA_WIDTH-1:0] mac_data,
    output wire [KEEP_WIDTH-1:0] mac_keep,
    output wire mac_sop,
    output wire mac_eop,
    output reg [frame_end_byte_index_W-1:0] mac_frame_end_byte_index,
    output wire mac_error,
    output wire mac_fcs_present
);
  reg frame_active;
  integer lane_index;
  always @* begin
    mac_frame_end_byte_index = {frame_end_byte_index_W{1'b0}};
    for (lane_index = 0; lane_index < KEEP_WIDTH; lane_index = lane_index + 1)
    mac_frame_end_byte_index = mac_frame_end_byte_index + s_tkeep[lane_index];
  end
  assign s_tready = mac_ready;
  assign mac_valid = s_tvalid;
  assign mac_data = s_tdata;
  assign mac_keep = s_tkeep;
  assign mac_sop = s_tvalid && !frame_active;
  assign mac_eop = s_tlast;
  assign mac_error = s_tuser[0];
  assign mac_fcs_present = s_tuser[1];
  always @(posedge clk) begin
    if (rst) frame_active <= 1'b0;
    else if (s_tvalid && s_tready) frame_active <= !s_tlast;
  end
endmodule
`default_nettype wire
