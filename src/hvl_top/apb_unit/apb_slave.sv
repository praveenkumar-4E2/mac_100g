/**
 * @brief Independent programmable APB slave model for the unit harness.
 *
 * Deliberately independent of the apb_driver implementation: it is a plain
 * clocked module (not a UVM component) that completes access when the wait
 * count reaches the configured bound, and presents the configured read data
 * and slave-error on prdata/pslverr continuously (the master samples them
 * only at completion). wait_cnt is cleared on reset, so an incomplete
 * transfer left behind by an injected reset never corrupts the next one.
 *
 * wait_cycles semantics: the number of full access cycles during which
 * pready is low before the completing access. wait_cycles=0 gives a
 * single-cycle transfer.
 */
module apb_slave (
  input  logic        clk,
  input  logic        rst,
  apb_if              apb,
  input  logic [31:0] cfg_rd_data,
  input  logic        cfg_slverr,
  input  int          cfg_wait_cycles
);
  int wait_cnt;

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      wait_cnt <= 0;
    else if (apb.psel && apb.penable) begin
      if (wait_cnt >= cfg_wait_cycles)
        wait_cnt <= 0;
      else
        wait_cnt <= wait_cnt + 1;
    end else
      wait_cnt <= 0;
  end

  assign apb.pready  = rst ? 1'b0 :
                       (apb.psel && apb.penable && wait_cnt >= cfg_wait_cycles);
  assign apb.prdata  = cfg_rd_data;
  assign apb.pslverr = cfg_slverr;
endmodule
