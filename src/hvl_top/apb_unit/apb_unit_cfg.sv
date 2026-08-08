/**
 * @brief Standalone APB unit-test environment configuration.
 *
 * Binds the harness virtual interfaces and lets a test override the agent
 * timing policy (max wait cycles) or select a passive observation role before
 * the environment builds its child components.
 */
class apb_unit_cfg_c extends uvm_object;
  `uvm_object_utils(apb_unit_cfg_c)

  virtual apb_if          apb_vif;
  virtual apb_unit_ctrl_if ctrl_vif;
  int unsigned            max_wait_cycles = 64;
  uvm_active_passive_enum role = UVM_ACTIVE;
  bit                     has_monitor = 1'b1;

  extern function new(string name = "apb_unit_cfg_c");
  extern function void validate();
endclass

function apb_unit_cfg_c::new(string name = "apb_unit_cfg_c");
  super.new(name);
endfunction

function void apb_unit_cfg_c::validate();
  if (apb_vif == null)
    `uvm_fatal(get_type_name(), $sformatf("%s: apb_vif is null", get_type_name()))
  if (ctrl_vif == null)
    `uvm_fatal(get_type_name(), $sformatf("%s: ctrl_vif is null", get_type_name()))
endfunction
