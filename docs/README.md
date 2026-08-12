# 100G Ethernet MAC Documentation

Read these guides in order. They describe the current pure-Verilog RTL and
SystemVerilog/UVM verification environment.

| Guide | Purpose |
|---|---|
| [Architecture](architecture.md) | Data flow, clocks, resets, and directories. |
| [Interfaces](interfaces.md) | AXI, MAC/RS, APB, and packet-marker rules. |
| [RTL coding](rtl_coding_guidelines.md) | Synthesizable Verilog conventions. |
| [UVM coding](uvm_coding_guidelines.md) | Agents, sequences, tests, and logs. |
| [Verification](verification_guide.md) | Checking and transaction flow. |
| [Tests](test_guide.md) | Creating and reviewing tests. |
| [Simulation and debug](simulation_debug_guide.md) | WSL, Questa, Visualizer, and triage. |
| [Git workflow](git_workflow.md) | Branches, commits, and review. |

## Quick start

```bash
cd /mnt/d/Qsemiai/VLSI/Documents/Protocols/Ethernet/100g/repo/mac_100g/sim/Questasim
make compile
make run TEST=mac_sanity_test_c
```

For interactive waveform debug, run `make visualizer TEST=mac_sanity_test_c`.

Remember: a stream beat transfers only when `valid` and `ready` are both `1`
on a rising clock edge.
