# P1: Harden Configuration, Agent Topology, and APB Control

## Problem

Configuration is useful but globally scoped (`"*"`), the top uses direct APB tasks and fixed delays, and agent-top creates component names containing wildcard `*`. `mac_env_c::connect_phase` assumes every configured agent has a monitor.

## Proposal

1. Create agent instances as `active_agents[0]` / `passive_agents[0]`; use wildcard only in the config-db path.
2. Configure each VIF and config object at its destination hierarchy, not globally.
3. Add `direction`, timeout, ready-policy, status-check, coverage-enable, and reset-policy fields to agent/environment config.
4. Create an active APB agent (or a narrowly scoped APB configuration service) to perform configuration and capture a versioned configuration snapshot for predictors.
5. Make monitor presence explicit: either always instantiate monitors in checking environments or guard all connections and disallow scoreboard mode without a monitor.

## Acceptance Criteria

- Two instances can be configured without VIF cross-binding.
- Component topology contains no literal wildcard in component names.
- Tests can alter configuration through sequences, and predictor behavior uses the observed configuration version.
