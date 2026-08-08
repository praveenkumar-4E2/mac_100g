/**
 * @brief Standalone APB unit-test control interface.
 *
 * Carries the programmable slave-model configuration (read data, slave
 * error, wait cycles for the next transfer) and the reset-pulse request that
 * the unit tests drive to inject reset at a chosen point. The tb_top
 * combines this pulse with its own power-on reset hold to form the apb_if
 * rst input, so the driver/monitor and the slave all observe one coherent
 * reset.
 */
interface apb_unit_ctrl_if;
  logic [31:0] rd_data     = '0;
  logic        slverr      = 1'b0;
  int          wait_cycles = 0;
  logic        rst_pulse   = 1'b0;
endinterface
