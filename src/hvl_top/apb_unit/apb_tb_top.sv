/**
 * @brief Standalone APB agent unit-testbench.
 *
 * No MAC DUT: instantiates one free-running clock, a power-on reset hold
 * combined with the ctrl_if reset pulse (so the driver, monitor, slave, and
 * interface assertions all observe one coherent reset), two apb_if buses
 * (apb_bus for the active-agent tests, apb_bus_ext for the passive-observation
 * test), and a programmable apb_slave on each. The apb_unit_cfg and the
 * apb_ext_vif virtual interface are published to the config db before
 * run_test().
 */
module apb_tb_top;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import apb_unit_pkg::*;

  //============================================================================
  // Clock: 10 ns period, free-running from t=0.
  //============================================================================
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5ns clk = ~clk;
  end

  //============================================================================
  // Reset: power-on hold for 8 clocks, ORed with the ctrl_if reset pulse the
  // tests drive to inject reset at a chosen point.
  //============================================================================
  logic rst;
  logic rst_hold;
  apb_unit_ctrl_if ctrl_h();
  assign rst = rst_hold | ctrl_h.rst_pulse;

  initial begin
    rst_hold = 1'b1;
    repeat (8) @(negedge clk);
    rst_hold = 1'b0;
  end

  //============================================================================
  // Buses: apb_bus is observed by the active-agent tests; apb_bus_ext is the
  // bus an external harness master drives for the passive test.
  //============================================================================
  apb_if apb_bus (
    .clk (clk),
    .rst (rst)
  );

  apb_if apb_bus_ext (
    .clk (clk),
    .rst (rst)
  );

  apb_slave slave_inst (
    .clk            (clk),
    .rst            (rst),
    .apb            (apb_bus),
    .cfg_rd_data    (ctrl_h.rd_data),
    .cfg_slverr     (ctrl_h.slverr),
    .cfg_wait_cycles(ctrl_h.wait_cycles)
  );

  apb_slave slave_ext_inst (
    .clk            (clk),
    .rst            (rst),
    .apb            (apb_bus_ext),
    .cfg_rd_data    (ctrl_h.rd_data),
    .cfg_slverr     (ctrl_h.slverr),
    .cfg_wait_cycles(ctrl_h.wait_cycles)
  );

  //============================================================================
  // UVM: build and publish the harness configuration, then run the test at
  // time 0. The passive test swaps apb_vif to apb_bus_ext before the env
  // builds, so the same apb_unit_cfg object is shared test/env (config_db
  // stores a reference, not a copy).
  //============================================================================
  initial begin
    automatic apb_unit_cfg_c unit_cfg = apb_unit_cfg_c::type_id::create("unit_cfg");
    unit_cfg.apb_vif  = apb_bus;
    unit_cfg.ctrl_vif = ctrl_h;
    unit_cfg.validate();
    uvm_config_db#(apb_unit_cfg_c)::set(null, "*", "apb_unit_cfg", unit_cfg);
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_ext_vif", apb_bus_ext);
    run_test("apb_unit_wr_test_c");
  end

endmodule
