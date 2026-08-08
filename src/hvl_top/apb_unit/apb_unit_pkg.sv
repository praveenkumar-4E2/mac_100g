/**
 * @brief Standalone APB agent unit-test package.
 *
 * Includes the reusable APB agent core files (transfer, config, sequencer,
 * sequences, driver, monitor, checker, agent) in dependency order, then the
 * unit-harness files. apb_agent_top.sv is intentionally NOT included: it
 * depends on mac_env_cfg_c, which does not exist in this standalone package.
 * The harness deliberately does not include any MAC test-package content.
 */
package apb_unit_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  `include "apb_transfer.sv"
  `include "apb_agent_cfg.sv"
  `include "apb_sequencer.sv"
  `include "apb_sequence_base.sv"
  `include "apb_write_sequence.sv"
  `include "apb_read_sequence.sv"
  `include "apb_burst_sequence.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_protocol_checker.sv"
  `include "apb_agent.sv"

  `include "apb_unit_cfg.sv"
  `include "apb_unit_scoreboard.sv"
  `include "apb_unit_env.sv"
  `include "apb_unit_tests.svh"
endpackage
