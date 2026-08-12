`default_nettype none
module tx_ipg_timer_stage #(
    parameter IPG_VALUE = 96
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire enable,
    input wire tick,
    input wire [2:0] speed,
    output wire done,
    output reg [6:0] remaining
);
  reg active;
  always @(posedge clk) begin
    if (rst) begin
      remaining <= 7'd0;
      active <= 1'b0;
    end else if (start) begin
      remaining <= IPG_VALUE;
      active <= 1'b1;
    end else if (active && enable && tick) begin
      if (remaining == 7'd1) begin
        remaining <= 7'd0;
        active <= 1'b0;
      end else remaining <= remaining - 1'b1;
    end
  end
  assign done = !active;
endmodule
`default_nettype wire
