/**
 * @brief Standalone APB unit-test environment.
 *
 * Builds one APB agent (active or passive per apb_unit_cfg_c) plus a
 * scoreboard that subscribes to the monitor. The agent configuration is
 * derived from apb_unit_cfg_c and set at a descendant-only scope so the
 * driver/monitor/checker all receive the same immutable object. In passive
 * mode the same monitor/scoreboard verify transfers driven by an external
 * harness master.
 */
class apb_unit_env_c extends uvm_env;
  `uvm_component_utils(apb_unit_env_c)

  apb_unit_cfg_c      m_cfg;
  apb_agent_cfg_c     m_agent_cfg;
  apb_agent_c         m_agent;
  apb_unit_scoreboard_c m_sb;

  extern function new(string name = "apb_unit_env_c", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
endclass

function apb_unit_env_c::new(string name = "apb_unit_env_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_env_c::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(apb_unit_cfg_c)::get(this, "", "apb_unit_cfg", m_cfg)) begin
    `uvm_fatal("CONFIG_ERROR",
               $sformatf("%s: cannot find apb_unit_cfg in config db", get_type_name()))
  end
  m_cfg.validate();

  m_agent_cfg = apb_agent_cfg_c::type_id::create("apb_agent_cfg");
  m_agent_cfg.m_vif                     = m_cfg.apb_vif;
  m_agent_cfg.m_is_active               = m_cfg.role;
  m_agent_cfg.m_has_monitor             = m_cfg.has_monitor;
  m_agent_cfg.m_max_wait_cycles         = m_cfg.max_wait_cycles;
  // Unit tests assert outcomes themselves; the checker's unexpected-slave-
  // error policy stays informational so a deliberate PSLVERR test cannot fail
  // the run via severity counts.
  m_agent_cfg.m_fail_on_unexpected_slverr = 1'b0;
  uvm_config_db#(apb_agent_cfg_c)::set(this, "m_agent*", "apb_agent_cfg", m_agent_cfg);

  m_agent = apb_agent_c::type_id::create("m_agent", this);
  m_sb    = apb_unit_scoreboard_c::type_id::create("m_sb", this);
endfunction

function void apb_unit_env_c::connect_phase(uvm_phase phase);
  m_agent.monitor_h.ap.connect(m_sb.analysis_export);
endfunction
