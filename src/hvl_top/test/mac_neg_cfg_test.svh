/**
 * @brief Negative configuration tests (UTL-086/087).
 *
 * Each test intentionally creates an invalid configuration and expects
 * build-phase validation to abort the simulation with a single actionable
 * fatal message that names the offending item.
 */

/**
 * @brief Negative test: an active AXI agent whose virtual interface is left
 *        null must fail configuration validation.
 *
 * UTL-086: the base config path binds every agent VIF from mac_tb_cfg_c;
 * this test unbinds the active AXI VIF so axi_agent_cfg_c::validate()
 * reports "vif=null" as the sole fatal.
 */
class axi_null_vif_negative_test_c extends mac_base_test_c;
  `uvm_component_utils(axi_null_vif_negative_test_c)

  extern function new(string name = "axi_null_vif_negative_test_c",
                      uvm_component parent = null);
  extern virtual function void set_env_config();
endclass

function axi_null_vif_negative_test_c::new(
    string name = "axi_null_vif_negative_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void axi_null_vif_negative_test_c::set_env_config();
  super.set_env_config();
  axi_active_agent_cfgs[0].vif = null;
endfunction

/**
 * @brief Negative test: an agent count that does not match its config array
 *        size must fail environment validation.
 *
 * UTL-087: mac_env_cfg_c::validate() reports the axi_passive size/count
 * mismatch as the sole fatal before any agent is created.
 */
class axi_count_mismatch_negative_test_c extends mac_base_test_c;
  `uvm_component_utils(axi_count_mismatch_negative_test_c)

  extern function new(string name = "axi_count_mismatch_negative_test_c",
                      uvm_component parent = null);
  extern virtual function void set_env_config();
endclass

function axi_count_mismatch_negative_test_c::new(
    string name = "axi_count_mismatch_negative_test_c", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void axi_count_mismatch_negative_test_c::set_env_config();
  super.set_env_config();
  env_cfg_h.axi_passive_agent_cfgs = new[env_cfg_h.num_axi_passive_agents + 1];
endfunction
