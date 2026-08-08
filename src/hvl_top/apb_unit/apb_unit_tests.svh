/**
 * @brief Base class for the standalone APB unit tests.
 *
 * Owns the environment handle, the harness interfaces, and the shared
 * helpers: waiting for reset deassertion and comparing a sequence response
 * against the monitor observation (the field set do_compare covers: pwrite,
 * addr, wdata, rdata, slverr, status, wait_cycles).
 */
class apb_unit_base_test_c extends uvm_test;
  `uvm_component_utils(apb_unit_base_test_c)

  apb_unit_env_c m_env;
  apb_unit_cfg_c m_cfg;
  virtual apb_if m_vif;
  virtual apb_unit_ctrl_if m_ctrl;

  extern function new(string name = "apb_unit_base_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task wait_rst_deasserted();
  extern function void check_match(apb_transfer_t rsp, apb_transfer_t mon, string ctx);
endclass

function apb_unit_base_test_c::new(string name = "apb_unit_base_test_c",
                                   uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_base_test_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(apb_unit_cfg_c)::get(this, "", "apb_unit_cfg", m_cfg)) begin
    `uvm_fatal("CONFIG_ERROR",
               $sformatf("%s: cannot find apb_unit_cfg in config db", get_type_name()))
  end
  m_cfg.validate();
  m_vif  = m_cfg.apb_vif;
  m_ctrl = m_cfg.ctrl_vif;
  m_env  = apb_unit_env_c::type_id::create("m_env", this);
endfunction

task apb_unit_base_test_c::wait_rst_deasserted();
  @(posedge m_vif.clk);
  while (m_vif.rst) @(posedge m_vif.clk);
endtask

function void apb_unit_base_test_c::check_match(apb_transfer_t rsp, apb_transfer_t mon,
                                                string ctx);
  if (mon == null) begin
    `uvm_error("UNIT", $sformatf("%s: no monitor item captured for response", ctx))
    return;
  end
  if (!rsp.compare(mon))
    `uvm_error("UNIT",
               $sformatf("%s: response/monitor mismatch\n  RSP: %s\n  MON: %s",
                         ctx, rsp.convert2string(), mon.convert2string()))
endfunction

//==============================================================================
// G-08 / G-11 / G-13: single successful write (immediate and with wait
// states); controls stability is enforced by the A-12 interface assertion,
// which runs in every unit test because assertions are enabled.
//==============================================================================
class apb_unit_wr_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_wr_test_c)
  int unsigned m_wait = 0;
  extern function new(string name = "apb_unit_wr_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_wr_test_c::new(string name = "apb_unit_wr_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_wr_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  apb_transfer_t rsp;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.wait_cycles = int'(m_wait);
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0010;
  seq.m_wdata = 32'hDEAD_BEEF;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  if (rsp.status != APB_OK)
    `uvm_error("UNIT", $sformatf("wr_test: expected APB_OK got %0s", rsp.status.name()))
  if (rsp.wait_cycles != m_wait)
    `uvm_error("UNIT", $sformatf("wr_test: wait_cycles=%0d expected %0d",
                                 rsp.wait_cycles, m_wait))
  check_match(rsp, m_env.m_sb.last(), "wr_test");
  phase.drop_objection(this);
endtask

class apb_unit_wait1_test_c extends apb_unit_wr_test_c;
  `uvm_component_utils(apb_unit_wait1_test_c)
  extern function new(string name = "apb_unit_wait1_test_c", uvm_component parent = null);
endclass
function apb_unit_wait1_test_c::new(string name = "apb_unit_wait1_test_c", uvm_component parent = null);
  super.new(name, parent);
  m_wait = 1;
endfunction

class apb_unit_waitn_test_c extends apb_unit_wr_test_c;
  `uvm_component_utils(apb_unit_waitn_test_c)
  extern function new(string name = "apb_unit_waitn_test_c", uvm_component parent = null);
endclass
function apb_unit_waitn_test_c::new(string name = "apb_unit_waitn_test_c", uvm_component parent = null);
  super.new(name, parent);
  m_wait = 4;
endfunction

//==============================================================================
// G-09 / G-10: single successful read; response and monitor read data must
// both equal the slave-provided data.
//==============================================================================
class apb_unit_rd_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_rd_test_c)
  extern function new(string name = "apb_unit_rd_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_rd_test_c::new(string name = "apb_unit_rd_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_rd_test_c::run_phase(uvm_phase phase);
  apb_read_sequence_c seq;
  apb_transfer_t rsp, mon;
  bit [31:0] expect_data = 32'h1234_5678;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.rd_data = expect_data;
  seq = apb_read_sequence_c::type_id::create("rd_seq");
  seq.m_addr = 32'h0000_0020;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  mon = m_env.m_sb.last();
  if (rsp.status != APB_OK)
    `uvm_error("UNIT", $sformatf("rd_test: expected APB_OK got %0s", rsp.status.name()))
  if (rsp.rdata !== expect_data)
    `uvm_error("UNIT", $sformatf("rd_test: rdata=%h expected %h", rsp.rdata, expect_data))
  if (seq.m_rdata !== expect_data)
    `uvm_error("UNIT", $sformatf("rd_test: seq.m_rdata=%h expected %h",
                                 seq.m_rdata, expect_data))
  if (mon.rdata !== expect_data)
    `uvm_error("UNIT", $sformatf("rd_test: monitor rdata=%h expected %h", mon.rdata, expect_data))
  check_match(rsp, mon, "rd_test");
  phase.drop_objection(this);
endtask

//==============================================================================
// G-14 / G-15: back-to-back read then write; every transfer must complete
// (each has its own setup and access) and responses must match the two
// monitor items in order.
//==============================================================================
class apb_unit_bb_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_bb_test_c)
  extern function new(string name = "apb_unit_bb_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_bb_test_c::new(string name = "apb_unit_bb_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_bb_test_c::run_phase(uvm_phase phase);
  apb_burst_sequence_c bseq;
  apb_transfer_t rd, wr;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.rd_data = 32'hA5A5_5A5A;
  bseq = apb_burst_sequence_c::type_id::create("bb_seq");
  bseq.m_check_responses = 1;
  rd = apb_transfer_t::type_id::create("rd_req");
  rd.pwrite = 1'b0; rd.addr = 32'h0000_0030;
  wr = apb_transfer_t::type_id::create("wr_req");
  wr.pwrite = 1'b1; wr.addr = 32'h0000_0034; wr.wdata = 32'hCAFE_F00D;
  bseq.m_requests.push_back(rd);
  bseq.m_requests.push_back(wr);
  bseq.start(m_env.m_agent.sequencer_h);
  if (bseq.m_responses.size() != 2)
    `uvm_error("UNIT", $sformatf("bb_test: responses=%0d expected 2", bseq.m_responses.size()))
  else begin
    if (bseq.m_responses[0].status != APB_OK ||
        bseq.m_responses[1].status != APB_OK)
      `uvm_error("UNIT", "bb_test: a back-to-back transfer did not complete OK")
  end
  if (m_env.m_sb.count() != 2)
    `uvm_error("UNIT", $sformatf("bb_test: monitor items=%0d expected 2", m_env.m_sb.count()))
  else begin
    if (m_env.m_sb.item(0).pwrite != 1'b0 || m_env.m_sb.item(1).pwrite != 1'b1)
      `uvm_error("UNIT", "bb_test: monitor transfer order/direction mismatch")
    check_match(bseq.m_responses[0], m_env.m_sb.item(0), "bb_test[0]");
    check_match(bseq.m_responses[1], m_env.m_sb.item(1), "bb_test[1]");
  end
  phase.drop_objection(this);
endtask

//==============================================================================
// G-16 / G-17: expected PSLVERR on write and read (the base sequence's
// check_status accepts APB_SLVERR as legitimate).
//==============================================================================
class apb_unit_wr_slverr_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_wr_slverr_test_c)
  extern function new(string name = "apb_unit_wr_slverr_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_wr_slverr_test_c::new(string name = "apb_unit_wr_slverr_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_wr_slverr_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  apb_transfer_t rsp;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.slverr = 1'b1;
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0040;
  seq.m_wdata = 32'h0;
  seq.m_expect_slverr    = 1'b1;
  seq.m_check_response   = 1'b1;
  seq.m_expected_status  = APB_SLVERR;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  if (rsp.status != APB_SLVERR || rsp.slverr != 1'b1)
    `uvm_error("UNIT", $sformatf("wr_slverr_test: expected SLVERR got %0s slverr=%0b",
                                 rsp.status.name(), rsp.slverr))
  check_match(rsp, m_env.m_sb.last(), "wr_slverr_test");
  phase.drop_objection(this);
endtask

class apb_unit_rd_slverr_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_rd_slverr_test_c)
  extern function new(string name = "apb_unit_rd_slverr_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_rd_slverr_test_c::new(string name = "apb_unit_rd_slverr_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_rd_slverr_test_c::run_phase(uvm_phase phase);
  apb_read_sequence_c seq;
  apb_transfer_t rsp;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.slverr = 1'b1;
  seq = apb_read_sequence_c::type_id::create("rd_seq");
  seq.m_addr  = 32'h0000_0044;
  seq.m_expect_slverr    = 1'b1;
  seq.m_check_response   = 1'b1;
  seq.m_expected_status  = APB_SLVERR;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  if (rsp.status != APB_SLVERR || rsp.slverr != 1'b1)
    `uvm_error("UNIT", $sformatf("rd_slverr_test: expected SLVERR got %0s slverr=%0b",
                                 rsp.status.name(), rsp.slverr))
  check_match(rsp, m_env.m_sb.last(), "rd_slverr_test");
  phase.drop_objection(this);
endtask

//==============================================================================
// G-18: unexpected PSLVERR. The test did not expect the slave error; the
// response must still complete with APB_SLVERR and the monitor must observe
// the same. Reporting (checker policy) stays informational in the harness.
//==============================================================================
class apb_unit_unexp_slverr_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_unexp_slverr_test_c)
  extern function new(string name = "apb_unit_unexp_slverr_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_unexp_slverr_test_c::new(string name = "apb_unit_unexp_slverr_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_unexp_slverr_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  apb_transfer_t rsp;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.slverr = 1'b1;
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0050;
  seq.m_wdata = 32'h0;
  seq.m_expect_slverr  = 1'b0;
  seq.m_check_response = 1'b0;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  if (rsp.status != APB_SLVERR)
    `uvm_error("UNIT", $sformatf("unexp_slverr_test: expected SLVERR got %0s", rsp.status.name()))
  if (rsp.expect_slverr !== 1'b0)
    `uvm_error("UNIT", "unexp_slverr_test: response unexpectedly marked slverr as expected")
  check_match(rsp, m_env.m_sb.last(), "unexp_slverr_test");
  phase.drop_objection(this);
endtask

//==============================================================================
// G-19: timeout at the configured bound. The bound is lowered to 4; a slave
// that never asserts pready must produce APB_TIMEOUT after the bound is
// exceeded, the bus must be restored to idle, and no hybrid transfer may be
// published.
//==============================================================================
class apb_unit_timeout_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_timeout_test_c)
  extern function new(string name = "apb_unit_timeout_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_timeout_test_c::new(string name = "apb_unit_timeout_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_timeout_test_c::build_phase(uvm_phase phase);
  if (!uvm_config_db#(apb_unit_cfg_c)::get(this, "", "apb_unit_cfg", m_cfg))
    `uvm_fatal("CONFIG_ERROR", "timeout_test: cannot find apb_unit_cfg")
  m_cfg.max_wait_cycles = 4;
  super.build_phase(phase);
endfunction

task apb_unit_timeout_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  apb_transfer_t rsp;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.wait_cycles = 1000;
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0060;
  seq.m_wdata = 32'h0;
  seq.m_check_response = 1'b0;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  if (rsp.status != APB_TIMEOUT)
    `uvm_error("UNIT", $sformatf("timeout_test: expected APB_TIMEOUT got %0s", rsp.status.name()))
  if (rsp.wait_cycles != 5)
    `uvm_error("UNIT", $sformatf("timeout_test: wait_cycles=%0d expected 5 (bound 4 exceeded)",
                                 rsp.wait_cycles))
  if (m_env.m_sb.count() != 0)
    `uvm_error("UNIT", $sformatf("timeout_test: monitor published %0d items, expected 0",
                                 m_env.m_sb.count()))
  phase.drop_objection(this);
endtask

//==============================================================================
// G-20: recovery — a good item must succeed after a timeout and after the
// driver has restored the bus to idle.
//==============================================================================
class apb_unit_timeout_recovery_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_timeout_recovery_test_c)
  extern function new(string name = "apb_unit_timeout_recovery_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_timeout_recovery_test_c::new(string name = "apb_unit_timeout_recovery_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_timeout_recovery_test_c::build_phase(uvm_phase phase);
  if (!uvm_config_db#(apb_unit_cfg_c)::get(this, "", "apb_unit_cfg", m_cfg))
    `uvm_fatal("CONFIG_ERROR", "timeout_recovery_test: cannot find apb_unit_cfg")
  m_cfg.max_wait_cycles = 4;
  super.build_phase(phase);
endfunction

task apb_unit_timeout_recovery_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  apb_transfer_t rsp;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.wait_cycles = 1000;
  seq = apb_write_sequence_c::type_id::create("tmo_seq");
  seq.m_addr  = 32'h0000_0070;
  seq.m_wdata = 32'h0;
  seq.m_check_response = 1'b0;
  seq.start(m_env.m_agent.sequencer_h);
  if (seq.m_rsp.status != APB_TIMEOUT)
    `uvm_error("UNIT", $sformatf("timeout_recovery_test: first transfer status=%0s",
                                 seq.m_rsp.status.name()))

  m_ctrl.wait_cycles = 0;
  seq = apb_write_sequence_c::type_id::create("good_seq");
  seq.m_addr  = 32'h0000_0074;
  seq.m_wdata = 32'hBADC_0FFE;
  seq.m_check_response = 1'b1;
  seq.m_expected_status = APB_OK;
  seq.start(m_env.m_agent.sequencer_h);
  rsp = seq.m_rsp;
  if (rsp.status != APB_OK)
    `uvm_error("UNIT", $sformatf("timeout_recovery_test: recovery status=%0s", rsp.status.name()))
  check_match(rsp, m_env.m_sb.last(), "timeout_recovery_test");
  phase.drop_objection(this);
endtask

//==============================================================================
// G-21: reset before an item begins. The sequence starts while reset is
// asserted; the driver must wait for reset deassertion, then complete the
// transfer normally.
//==============================================================================
class apb_unit_rst_before_item_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_rst_before_item_test_c)
  extern function new(string name = "apb_unit_rst_before_item_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_rst_before_item_test_c::new(string name = "apb_unit_rst_before_item_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_rst_before_item_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.rst_pulse = 1'b1;
  repeat (2) @(posedge m_vif.clk);
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0080;
  seq.m_wdata = 32'h0;
  seq.m_check_response = 1'b1;
  fork
    seq.start(m_env.m_agent.sequencer_h);
  join_none
  repeat (2) @(posedge m_vif.clk);
  m_ctrl.rst_pulse = 1'b0;
  wait (seq.m_rsp != null);
  if (seq.m_rsp.status != APB_OK)
    `uvm_error("UNIT", $sformatf("rst_before_item_test: status=%0s expected APB_OK",
                                 seq.m_rsp.status.name()))
  check_match(seq.m_rsp, m_env.m_sb.last(), "rst_before_item_test");
  phase.drop_objection(this);
endtask

//==============================================================================
// G-22 / G-23: reset during setup and during access wait. Both must yield an
// APB_RESET_ABORT response, leave the bus idle, and publish no hybrid item.
//==============================================================================
class apb_unit_rst_setup_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_rst_setup_test_c)
  extern function new(string name = "apb_unit_rst_setup_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_rst_setup_test_c::new(string name = "apb_unit_rst_setup_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_rst_setup_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0090;
  seq.m_wdata = 32'h0;
  seq.m_check_response = 1'b0;
  fork
    seq.start(m_env.m_agent.sequencer_h);
  join_none
  // Wait until the setup phase appears on the bus, then pulse reset.
  @(posedge m_vif.clk);
  while (!(m_vif.psel && !m_vif.penable)) @(posedge m_vif.clk);
  m_ctrl.rst_pulse = 1'b1;
  repeat (2) @(posedge m_vif.clk);
  m_ctrl.rst_pulse = 1'b0;
  wait (seq.m_rsp != null);
  if (seq.m_rsp.status != APB_RESET_ABORT)
    `uvm_error("UNIT", $sformatf("rst_setup_test: status=%0s expected APB_RESET_ABORT",
                                 seq.m_rsp.status.name()))
  if (m_env.m_sb.count() != 0)
    `uvm_error("UNIT", $sformatf("rst_setup_test: monitor published %0d items, expected 0",
                                 m_env.m_sb.count()))
  phase.drop_objection(this);
endtask

class apb_unit_rst_access_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_rst_access_test_c)
  extern function new(string name = "apb_unit_rst_access_test_c", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_rst_access_test_c::new(string name = "apb_unit_rst_access_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_unit_rst_access_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.wait_cycles = 100;
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_0094;
  seq.m_wdata = 32'h0;
  seq.m_check_response = 1'b0;
  fork
    seq.start(m_env.m_agent.sequencer_h);
  join_none
  // Wait until the access phase appears on the bus, then pulse reset.
  @(posedge m_vif.clk);
  while (!(m_vif.psel && m_vif.penable)) @(posedge m_vif.clk);
  m_ctrl.rst_pulse = 1'b1;
  repeat (2) @(posedge m_vif.clk);
  m_ctrl.rst_pulse = 1'b0;
  wait (seq.m_rsp != null);
  if (seq.m_rsp.status != APB_RESET_ABORT)
    `uvm_error("UNIT", $sformatf("rst_access_test: status=%0s expected APB_RESET_ABORT",
                                 seq.m_rsp.status.name()))
  if (m_env.m_sb.count() != 0)
    `uvm_error("UNIT", $sformatf("rst_access_test: monitor published %0d items, expected 0",
                                 m_env.m_sb.count()))
  phase.drop_objection(this);
endtask

//==============================================================================
// G-24 / G-25: passive agent observing an external harness master. The
// passive agent must contain no driver/sequencer and must publish exactly the
// transfers the external master drove, without altering any master signal.
//==============================================================================
class apb_unit_passive_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_passive_test_c)
  virtual apb_if m_ext_vif;
  extern function new(string name = "apb_unit_passive_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task ext_write(bit [15:0] addr, bit [31:0] data);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_passive_test_c::new(string name = "apb_unit_passive_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_passive_test_c::build_phase(uvm_phase phase);
  if (!uvm_config_db#(apb_unit_cfg_c)::get(this, "", "apb_unit_cfg", m_cfg))
    `uvm_fatal("CONFIG_ERROR", "passive_test: cannot find apb_unit_cfg")
  m_cfg.role = UVM_PASSIVE;
  if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_ext_vif", m_ext_vif))
    `uvm_fatal("CONFIG_ERROR", "passive_test: cannot find apb_ext_vif in config db")
  m_cfg.apb_vif = m_ext_vif;
  super.build_phase(phase);
endfunction

// External master drive: raw nonblocking drives on the observed bus. The
// passive agent has no driver, so this task is the only master.
task apb_unit_passive_test_c::ext_write(bit [15:0] addr, bit [31:0] data);
  @(posedge m_ext_vif.clk);
  m_ext_vif.psel   <= 1'b1;
  m_ext_vif.penable <= 1'b0;
  m_ext_vif.pwrite  <= 1'b1;
  m_ext_vif.paddr   <= addr;
  m_ext_vif.pwdata  <= data;
  @(posedge m_ext_vif.clk);
  m_ext_vif.penable <= 1'b1;
  do @(posedge m_ext_vif.clk); while (!m_ext_vif.pready);
  m_ext_vif.psel   <= 1'b0;
  m_ext_vif.penable <= 1'b0;
  m_ext_vif.pwrite  <= 1'b0;
  m_ext_vif.paddr   <= '0;
  m_ext_vif.pwdata  <= '0;
endtask

task apb_unit_passive_test_c::run_phase(uvm_phase phase);
  apb_transfer_t mon;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  m_ctrl.rd_data = 32'h55AA_AA55;
  if (m_env.m_agent.driver_h != null || m_env.m_agent.sequencer_h != null)
    `uvm_error("UNIT", "passive_test: passive agent created a driver or sequencer")
  ext_write(16'h00A0, 32'h1122_3344);
  repeat (2) @(posedge m_ext_vif.clk);
  if (m_ext_vif.psel !== 1'b0 || m_ext_vif.penable !== 1'b0)
    `uvm_error("UNIT", "passive_test: bus not idle after external master released it")
  if (m_env.m_sb.count() != 1)
    `uvm_error("UNIT", $sformatf("passive_test: monitor items=%0d expected 1",
                                 m_env.m_sb.count()))
  else begin
    mon = m_env.m_sb.last();
    if (mon.pwrite != 1'b1 || mon.addr != 16'h00A0 || mon.wdata != 32'h1122_3344)
      `uvm_error("UNIT", $sformatf("passive_test: observed transfer mismatch: %s",
                                   mon.convert2string()))
    if (mon.status != APB_OK)
      `uvm_error("UNIT", $sformatf("passive_test: observed status=%0s", mon.status.name()))
  end
  phase.drop_objection(this);
endtask

//==============================================================================
// F-18 / G-26: factory override smoke. Overriding apb_monitor_c must change
// which class the agent builds, and the overridden monitor must still
// function (publish transfers).
//==============================================================================
class apb_unit_override_monitor_c extends apb_monitor_c;
  `uvm_component_utils(apb_unit_override_monitor_c)
  static int m_created = 0;
  extern function new(string name = "apb_unit_override_monitor_c", uvm_component parent = null);
endclass

function apb_unit_override_monitor_c::new(string name = "apb_unit_override_monitor_c",
                                          uvm_component parent = null);
  super.new(name, parent);
  m_created++;
endfunction

class apb_unit_factory_override_test_c extends apb_unit_base_test_c;
  `uvm_component_utils(apb_unit_factory_override_test_c)
  extern function new(string name = "apb_unit_factory_override_test_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass

function apb_unit_factory_override_test_c::new(string name = "apb_unit_factory_override_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_factory_override_test_c::build_phase(uvm_phase phase);
  apb_monitor_c::type_id::set_type_override(apb_unit_override_monitor_c::get_type(), 1);
  super.build_phase(phase);
endfunction

task apb_unit_factory_override_test_c::run_phase(uvm_phase phase);
  apb_write_sequence_c seq;
  phase.raise_objection(this);
  #1;
  wait_rst_deasserted();
  if (apb_unit_override_monitor_c::m_created == 0)
    `uvm_error("UNIT", "factory_override_test: overridden monitor was not created")
  seq = apb_write_sequence_c::type_id::create("wr_seq");
  seq.m_addr  = 32'h0000_00B0;
  seq.m_wdata = 32'h0;
  seq.m_check_response = 1'b1;
  seq.start(m_env.m_agent.sequencer_h);
  if (seq.m_rsp.status != APB_OK)
    `uvm_error("UNIT", $sformatf("factory_override_test: status=%0s", seq.m_rsp.status.name()))
  if (m_env.m_sb.count() != 1)
    `uvm_error("UNIT", $sformatf("factory_override_test: monitor items=%0d expected 1",
                                 m_env.m_sb.count()))
  phase.drop_objection(this);
endtask
