// Project-owned UVM RAL model for the MAC APB register boundary.  It models
// the published address map; register semantics remain the DUT's contract.
class mac_ral_reg_c extends uvm_reg;
  `uvm_object_utils(mac_ral_reg_c)
  uvm_reg_field value;
  extern function new(string name = "mac_ral_reg_c");
  extern virtual function void build();
endclass

function mac_ral_reg_c::new(string name = "mac_ral_reg_c");
  super.new(name, 32, UVM_NO_COVERAGE);
endfunction

function void mac_ral_reg_c::build();
  value = uvm_reg_field::type_id::create("value");
  value.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
endfunction

class mac_ral_block_c extends uvm_reg_block;
  `uvm_object_utils(mac_ral_block_c)
  mac_ral_reg_c registers[string];

  extern function new(string name = "mac_ral_block_c");
  extern virtual function void build();
  extern function mac_ral_reg_c add_register(string name, uvm_reg_addr_t address);
endclass

function mac_ral_block_c::new(string name = "mac_ral_block_c");
  super.new(name, UVM_NO_COVERAGE);
endfunction

function mac_ral_reg_c mac_ral_block_c::add_register(string name, uvm_reg_addr_t address);
  mac_ral_reg_c reg_h;
  reg_h = mac_ral_reg_c::type_id::create(name);
  reg_h.build();
  reg_h.configure(this);
  default_map.add_reg(reg_h, address, "RW");
  registers[name] = reg_h;
  return reg_h;
endfunction

function void mac_ral_block_c::build();
  default_map = create_map("apb_map", '0, 4, UVM_LITTLE_ENDIAN, 1);
  void'(add_register("version",              reg_map_pkg::REG_VERSION));
  void'(add_register("global_control",       reg_map_pkg::REG_GLOBAL_CONTROL));
  void'(add_register("mac_addr_low",         reg_map_pkg::REG_MAC_ADDR_LOW));
  void'(add_register("mac_addr_high",        reg_map_pkg::REG_MAC_ADDR_HIGH));
  void'(add_register("max_client_data",      reg_map_pkg::REG_MAX_CLIENT_DATA));
  void'(add_register("oversize_control",     reg_map_pkg::REG_OVERSIZE_CONTROL));
  void'(add_register("pause_control",        reg_map_pkg::REG_PAUSE_CONTROL));
  void'(add_register("pause_status",         reg_map_pkg::REG_PAUSE_STATUS));
  void'(add_register("rx_status",            reg_map_pkg::REG_RX_STATUS));
  void'(add_register("tx_status",            reg_map_pkg::REG_TX_STATUS));
  void'(add_register("interrupt_enable",     reg_map_pkg::REG_INTERRUPT_ENABLE));
  void'(add_register("interrupt_status",     reg_map_pkg::REG_INTERRUPT_STATUS));
  void'(add_register("rx_invalid_count",     reg_map_pkg::REG_RX_INVALID_COUNT));
  void'(add_register("rx_oversize_count",    reg_map_pkg::REG_RX_OVERSIZE_COUNT));
  void'(add_register("rx_unsupported_count", reg_map_pkg::REG_RX_UNSUPPORTED_COUNT));
  void'(add_register("pause_tx_config",      reg_map_pkg::REG_PAUSE_TX_CONFIG));
  void'(add_register("mac_speed_config",     reg_map_pkg::REG_MAC_SPEED_CONFIG));
  void'(add_register("max_frame_size",       reg_map_pkg::REG_MAX_FRAME_SIZE));
  void'(add_register("min_frame_size",       reg_map_pkg::REG_MIN_FRAME_SIZE));
  void'(add_register("frame_size_status",    reg_map_pkg::REG_FRAME_SIZE_STATUS));
  lock_model();
endfunction
