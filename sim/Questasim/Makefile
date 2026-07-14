## =====================================================================
## Questa simulation Makefile for MAC design
## Run from: sim/run/  (paths are resolved via mac_compile.f, which
## already contains full relative paths + +incdir entries)
##
## Running plain `make` (no target) prints help.
## =====================================================================

## --------------------------- Tools ---------------------------------------
VLIB   = vlib
VMAP   = vmap
VLOG   = vlog
VOPT   = vopt
VSIM   = vsim
VCOVER = vcover

## --------------------------- Config ---------------------------------------
## Override from the command line, e.g.:
##   make run TOP=other_top FILELIST=other.f
WORK      = work
TOP       = mac_top
OPT_TOP   = $(TOP)_opt
FILELIST  = mac_compile.f

VLOG_OPTS = -sv +acc +cover
VOPT_OPTS = +acc
VSIM_OPTS = -voptargs=+acc

## --------------------------- Coverage config -------------------------------
COV_DB      = mac_cov.ucdb
COV_HTML    = cov_html_report
VLOG_COV_OPTS = $(VLOG_OPTS) +cover=bcesfx
VOPT_COV_OPTS = $(VOPT_OPTS) +cover
VSIM_COV_OPTS = $(VSIM_OPTS) -coverage -do "coverage save -onexit $(COV_DB); run -all; exit"

## Files/dirs removed by `make clean` — extend this list as new
## artifact types get generated
CLEAN_TARGETS = $(WORK) transcript vsim.wlf *.log *.ucdb $(OPT_TOP) $(COV_HTML)

.PHONY: help all lib \
        compile compile_opt run run_opt gui gui_opt \
        compile_cov run_cov gui_cov cover_report \
        clean

## --------------------------- Default / Help --------------------------------

## Plain `make` prints help instead of building anything
help:
	@echo "";
	@echo "-----------------------------------------------------------------";
	@echo "Usage: make <target> [VAR=value ...]";
	@echo "-----------------------------------------------------------------";
	@echo "";
	@echo "Standard flow:";
	@echo "  make compile      - compile sources (no optimization)";
	@echo "  make compile_opt  - compile + build optimized sim image";
	@echo "  make run          - batch-mode simulation (unoptimized)";
	@echo "  make run_opt      - batch-mode simulation (optimized)";
	@echo "  make gui          - open Questa GUI (unoptimized)";
	@echo "  make gui_opt      - open Questa GUI (optimized)";
	@echo "";
	@echo "Coverage flow:";
	@echo "  make compile_cov  - compile sources with coverage enabled";
	@echo "  make run_cov      - batch-mode sim, saves coverage to $(COV_DB)";
	@echo "  make gui_cov      - open Questa GUI with coverage enabled";
	@echo "  make cover_report - generate HTML report from $(COV_DB)";
	@echo "";
	@echo "Housekeeping:";
	@echo "  make clean        - remove generated files";
	@echo "";
	@echo "Common overrides:";
	@echo "  make compile FILELIST=my_other.f";
	@echo "  make run TOP=some_other_top";
	@echo "-----------------------------------------------------------------";
	@echo "";

## --------------------------- Standard flow ---------------------------------

## Create and map the work library
lib:
	$(VLIB) $(WORK)
	$(VMAP) work $(WORK)

## Compile sources without optimization
## (all file paths + incdirs come from $(FILELIST) itself)
compile: lib
	$(VLOG) $(VLOG_OPTS) -f $(FILELIST)

## Compile then build an optimized simulation snapshot
compile_opt: compile
	$(VOPT) $(VOPT_OPTS) $(WORK).$(TOP) -o $(OPT_TOP)

## Batch-mode simulation (no GUI), unoptimized
run: compile
	$(VSIM) $(VSIM_OPTS) $(WORK).$(TOP) -do "run -all; exit"

## Batch-mode simulation (no GUI), optimized
run_opt: compile_opt
	$(VSIM) $(OPT_TOP) -do "run -all; exit"

## Interactive GUI, unoptimized
gui: compile
	$(VSIM) $(VSIM_OPTS) $(WORK).$(TOP)

## Interactive GUI, optimized
gui_opt: compile_opt
	$(VSIM) $(OPT_TOP)

## --------------------------- Coverage flow ---------------------------------

## Compile sources with coverage instrumentation
compile_cov: lib
	$(VLOG) $(VLOG_COV_OPTS) -f $(FILELIST)

## Batch-mode simulation with coverage collection, saved to $(COV_DB)
run_cov: compile_cov
	$(VSIM) $(VSIM_COV_OPTS) $(WORK).$(TOP)

## Interactive GUI with coverage enabled
gui_cov: compile_cov
	$(VSIM) $(VSIM_OPTS) -coverage $(WORK).$(TOP)

## Generate an HTML coverage report from the saved coverage database
cover_report:
	$(VCOVER) report -html $(COV_DB) -htmldir $(COV_HTML) -details

## --------------------------- Housekeeping -----------------------------------

## Remove all generated simulation artifacts
## (rm -rf works on Linux/macOS/WSL/Git-Bash; not native cmd.exe)
clean:
	rm -rf $(CLEAN_TARGETS)