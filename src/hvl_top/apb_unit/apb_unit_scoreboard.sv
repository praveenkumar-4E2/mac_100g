/**
 * @brief APB unit-test scoreboard.
 *
 * Stores a deep copy of every monitor-published transfer so tests can
 * compare the sequence response with the monitor observation (direction,
 * address, data, error, status, and wait count — the fields do_compare
 * covers). Subscribers never modify the published object.
 */
class apb_unit_scoreboard_c extends uvm_subscriber #(apb_transfer_t);
  `uvm_component_utils(apb_unit_scoreboard_c)

  apb_transfer_t m_items[$];

  extern function new(string name = "apb_unit_scoreboard_c", uvm_component parent = null);
  extern function void write(apb_transfer_t t);
  extern function int unsigned count();
  extern function apb_transfer_t last();
  extern function apb_transfer_t item(int unsigned i);
  extern function void clear();
endclass

function apb_unit_scoreboard_c::new(string name = "apb_unit_scoreboard_c",
                                    uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_unit_scoreboard_c::write(apb_transfer_t t);
  apb_transfer_t copy = apb_transfer_t::type_id::create("sb_copy");
  copy.copy(t);
  m_items.push_back(copy);
endfunction

function int unsigned apb_unit_scoreboard_c::count();
  return m_items.size();
endfunction

function apb_transfer_t apb_unit_scoreboard_c::last();
  if (m_items.size() == 0)
    return null;
  return m_items[m_items.size()-1];
endfunction

function apb_transfer_t apb_unit_scoreboard_c::item(int unsigned i);
  if (i >= m_items.size())
    return null;
  return m_items[i];
endfunction

function void apb_unit_scoreboard_c::clear();
  m_items.delete();
endfunction
