class mac_env_cfg_c extends uvm_object;
  `uvm_object_utils(mac_env_cfg_c)

  bit has_function_coverage = 0;

  bit has_scoreboard = 1;

  bit has_axi_agents = 1;

  bit has_rs_agents = 1;

  bit has_virtual_sequencer = 1;

  axi_agent_cfg_c axi_active_agent_cfgs[];
  axi_agent_cfg_c axi_passive_agent_cfgs[];

  rs_agent_cfg_c rs_active_agent_cfgs[];
  rs_agent_cfg_c rs_passive_agent_cfgs[];


  int num_axi_active_agents = 1;
  int num_axi_passive_agents = 1;

  int num_rs_active_agents = 1;
  int num_rs_passive_agents = 1;

  int num_duts = 1;





  extern function new(string name = "mac_env_cfg_c");
  extern function void validate();

endclass


function mac_env_cfg_c::new(string name = "mac_env_cfg_c");
  super.new(name);
endfunction

/**
 * @brief Validates the environment configuration before child components
 *        are created (UTL-084).
 *
 * Checks that every agent-count field has a matching non-empty config
 * array of exactly the declared size, that no array entry is null, and
 * that each entry's declared identity (is_active) matches the array it
 * lives in. All problems are collected and reported in a single
 * actionable fatal message.
 */
function void mac_env_cfg_c::validate();
  string problems;

  if (num_axi_active_agents < 0)
    problems = {problems, $sformatf(" num_axi_active_agents=%0d<0",
                                    num_axi_active_agents)};
  if (num_axi_passive_agents < 0)
    problems = {problems, $sformatf(" num_axi_passive_agents=%0d<0",
                                    num_axi_passive_agents)};
  if (num_rs_active_agents < 0)
    problems = {problems, $sformatf(" num_rs_active_agents=%0d<0",
                                    num_rs_active_agents)};
  if (num_rs_passive_agents < 0)
    problems = {problems, $sformatf(" num_rs_passive_agents=%0d<0",
                                    num_rs_passive_agents)};

  // A dynamic array cannot be compared with null; a never-allocated
  // array reports size() == 0 in Questa, so a size/count mismatch below
  // also catches the null case.
  if (axi_active_agent_cfgs.size() != num_axi_active_agents)
    problems = {problems, $sformatf(" axi_active size=%0d != num=%0d",
                                    axi_active_agent_cfgs.size(),
                                    num_axi_active_agents)};

  if (axi_passive_agent_cfgs.size() != num_axi_passive_agents)
    problems = {problems, $sformatf(" axi_passive size=%0d != num=%0d",
                                    axi_passive_agent_cfgs.size(),
                                    num_axi_passive_agents)};

  if (rs_active_agent_cfgs.size() != num_rs_active_agents)
    problems = {problems, $sformatf(" rs_active size=%0d != num=%0d",
                                    rs_active_agent_cfgs.size(),
                                    num_rs_active_agents)};

  if (rs_passive_agent_cfgs.size() != num_rs_passive_agents)
    problems = {problems, $sformatf(" rs_passive size=%0d != num=%0d",
                                    rs_passive_agent_cfgs.size(),
                                    num_rs_passive_agents)};

  foreach (axi_active_agent_cfgs[i]) begin
    if (axi_active_agent_cfgs[i] == null)
      problems = {problems, $sformatf(" axi_active_cfgs[%0d]=null", i)};
    else if (axi_active_agent_cfgs[i].is_active != UVM_ACTIVE)
      problems = {problems, $sformatf(" axi_active_cfgs[%0d] is %0s",
                                      i, axi_active_agent_cfgs[i].is_active.name())};
  end
  foreach (axi_passive_agent_cfgs[i]) begin
    if (axi_passive_agent_cfgs[i] == null)
      problems = {problems, $sformatf(" axi_passive_cfgs[%0d]=null", i)};
    else if (axi_passive_agent_cfgs[i].is_active != UVM_PASSIVE)
      problems = {problems, $sformatf(" axi_passive_cfgs[%0d] is %0s",
                                      i, axi_passive_agent_cfgs[i].is_active.name())};
  end
  foreach (rs_active_agent_cfgs[i]) begin
    if (rs_active_agent_cfgs[i] == null)
      problems = {problems, $sformatf(" rs_active_cfgs[%0d]=null", i)};
    else if (rs_active_agent_cfgs[i].is_active != UVM_ACTIVE)
      problems = {problems, $sformatf(" rs_active_cfgs[%0d] is %0s",
                                      i, rs_active_agent_cfgs[i].is_active.name())};
  end
  foreach (rs_passive_agent_cfgs[i]) begin
    if (rs_passive_agent_cfgs[i] == null)
      problems = {problems, $sformatf(" rs_passive_cfgs[%0d]=null", i)};
    else if (rs_passive_agent_cfgs[i].is_active != UVM_PASSIVE)
      problems = {problems, $sformatf(" rs_passive_cfgs[%0d] is %0s",
                                      i, rs_passive_agent_cfgs[i].is_active.name())};
  end

  if (problems != "")
    `uvm_fatal(get_type_name(),
               $sformatf("%s: invalid configuration:%0s", get_type_name(), problems))
endfunction
