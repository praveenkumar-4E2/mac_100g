## =====================================================================
## Questa simulation Makefile for MAC design
##
## New here? Just run:   make
## It prints this help — nothing gets built by accident.
##
## Run from: sim/run/  (paths are resolved via mac_compile.f, which
## already contains full relative paths + +incdir entries)
## =====================================================================

## --------------------------- Tools -----------------------------------
VLIB   = vlib
VMAP   = vmap
VLOG   = vlog
VOPT   = vopt
VSIM   = vsim
VCOVER = vcover

## --------------------------- Project config ---------------------------
## Override any of these from the command line, e.g.:
##   make run TOP=other_top FILELIST=other.f
WORK      = work
TOP       = mac_tb
OPT_TOP   = $(TOP)_opt
FILELIST  = mac_compile.f

VLOG_OPTS = -sv +acc
VOPT_OPTS = +acc
VSIM_OPTS = -voptargs=+acc

## --------------------------- Test selection -----------------------------
## Override per run, e.g.:
##   make run TEST=mac_smoke_test VERBOSITY=UVM_HIGH SEED=12345
ifndef TEST
override TEST = mac_base_test
endif

ifndef VERBOSITY
override VERBOSITY = UVM_MEDIUM
endif

ifndef SEED
override SEED = random
endif

## Every test run gets its own folder: run_<TEST>/
## Keeps logs/waveforms/coverage from different tests from overwriting
## each other, and makes it obvious what's what.
RUN_DIR    = run_$(TEST)
RUN_LOG    = $(RUN_DIR)/$(TEST).log
RUN_WLF    = $(RUN_DIR)/waveform.wlf

## --------------------------- Coverage config -----------------------------
## Coverage flags live ONLY here — the standard flow above stays
## instrumentation-free, so day-to-day compiles/runs are lighter and faster.
COV_DB        = $(RUN_DIR)/$(TEST)_cov.ucdb
COV_HTML      = $(RUN_DIR)/cov_html_report
VLOG_COV_OPTS = $(VLOG_OPTS) +cover=bcesfx
VOPT_COV_OPTS = $(VOPT_OPTS) +cover
VSIM_COV_OPTS = $(VSIM_OPTS) -coverage -do "coverage save -onexit $(COV_DB); run -all; exit"

## --------------------------- Regression config ----------------------------
## A regression list is just a text file with one test name per line
## (blank lines and lines starting with # are ignored). Example:
##   mac_smoke_test
##   mac_reset_test
##   # mac_stress_test   <- disabled, kept for reference
TESTLIST = regression.list

## Files/dirs removed by `make clean`
CLEAN_TARGETS = $(WORK) transcript vsim.wlf *.log *.ucdb $(OPT_TOP) run_*

.PHONY: help all lib \
        check compile compile_opt run run_opt gui gui_opt \
        compile_cov compile_opt_cov run_cov run_opt_cov gui_cov cover_report \
        regression clean

## --------------------------- Default / Help ------------------------------

## Plain `make` prints help instead of building anything
help:
	@echo "";
	@echo "======================================================================";
	@echo " MAC design simulation - Makefile quick guide";
	@echo "======================================================================";
	@echo "";
	@echo "I just want to check my code compiles (fastest option):";
	@echo "  make check";
	@echo "";
	@echo "I want to compile the design normally:";
	@echo "  make compile";
	@echo "";
	@echo "I want to run the default test:";
	@echo "  make run";
	@echo "";
	@echo "I want to run a SPECIFIC test:";
	@echo "  make run TEST=mac_smoke_test";
	@echo "  make run TEST=mac_smoke_test VERBOSITY=UVM_HIGH SEED=12345";
	@echo "  (each test's logs/waveform go into their own run_<TEST>/ folder)";
	@echo "";
	@echo "I want to run a test with coverage collection:";
	@echo "  make run_cov TEST=mac_smoke_test";
	@echo "  make cover_report TEST=mac_smoke_test   # HTML report afterwards";
	@echo "";
	@echo "I want to open the Questa GUI to debug:";
	@echo "  make gui TEST=mac_smoke_test";
	@echo "";
	@echo "I want to run a whole list of tests (regression):";
	@echo "  make regression TESTLIST=regression.list";
	@echo "";
	@echo "I want to clean everything and start fresh:";
	@echo "  make clean";
	@echo "";
	@echo "----------------------------------------------------------------------";
	@echo "Full target reference";
	@echo "----------------------------------------------------------------------";
	@echo "  check          - fastest syntax/elaboration-only compile check";
	@echo "  compile        - normal compile (no optimization)";
	@echo "  compile_opt    - compile + build optimized sim image";
	@echo "  run            - batch-mode simulation (unoptimized)";
	@echo "  run_opt        - batch-mode simulation (optimized)";
	@echo "  gui            - open Questa GUI (unoptimized)";
	@echo "  gui_opt        - open Questa GUI (optimized)";
	@echo "  compile_cov    - compile with coverage instrumentation";
	@echo "  compile_opt_cov- compile + optimize, with coverage";
	@echo "  run_cov        - batch-mode sim + save coverage";
	@echo "  run_opt_cov    - optimized batch-mode sim + save coverage";
	@echo "  gui_cov        - GUI with coverage enabled";
	@echo "  cover_report   - build HTML coverage report for TEST";
	@echo "  regression     - run every test listed in TESTLIST";
	@echo "  clean          - remove all generated files";
	@echo "";
	@echo "Variables you can override (VAR=value after any target):";
	@echo "  TEST=$(TEST)  VERBOSITY=$(VERBOSITY)  SEED=$(SEED)";
	@echo "  FILELIST=$(FILELIST)  TOP=$(TOP)  TESTLIST=$(TESTLIST)";
	@echo "======================================================================";
	@echo "";

## --------------------------- Standard flow --------------------------------

## Create and map the work library
lib:
	$(VLIB) $(WORK)
	$(VMAP) work $(WORK)

## Fast development loop: compile only, just to catch syntax/UVM errors.
## No waveform/coverage overhead - use this while writing/debugging code.
check: lib
	@echo ">> Quick compile check (no simulation, no waveform, no coverage)";
	$(VLOG) -sv -f $(FILELIST)
	@echo ">> Compile check PASSED - no errors.";

## Full compile without optimization
## (all file paths + incdirs come from $(FILELIST) itself)
compile: lib
	$(VLOG) $(VLOG_OPTS) -f $(FILELIST)

## Compile then build an optimized simulation snapshot
compile_opt: compile
	$(VOPT) $(VOPT_OPTS) $(WORK).$(TOP) -o $(OPT_TOP)

## Batch-mode simulation (no GUI), unoptimized
run: compile
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_OPTS) $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG) -wlf $(RUN_WLF) \
	  -do "run -all; exit"
	@echo ">> Test '$(TEST)' finished. Log: $(RUN_LOG)"

## Batch-mode simulation (no GUI), optimized
run_opt: compile_opt
	mkdir -p $(RUN_DIR)
	$(VSIM) $(OPT_TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG) -wlf $(RUN_WLF) \
	  -do "run -all; exit"
	@echo ">> Test '$(TEST)' finished. Log: $(RUN_LOG)"

## Interactive GUI, unoptimized
gui: compile
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_OPTS) $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG)

## Interactive GUI, optimized
gui_opt: compile_opt
	mkdir -p $(RUN_DIR)
	$(VSIM) $(OPT_TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG)

## --------------------------- Coverage flow --------------------------------

## Compile sources with coverage instrumentation
compile_cov: lib
	$(VLOG) $(VLOG_COV_OPTS) -f $(FILELIST)

## Compile with coverage + build optimized coverage sim image
compile_opt_cov: compile_cov
	$(VOPT) $(VOPT_COV_OPTS) $(WORK).$(TOP) -o $(OPT_TOP)

## Batch-mode simulation with coverage collection, saved under run_<TEST>/
run_cov: compile_cov
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_COV_OPTS) $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG)
	@echo ">> Coverage saved: $(COV_DB)"

## Batch-mode simulation, optimized + coverage
run_opt_cov: compile_opt_cov
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_COV_OPTS) $(OPT_TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG)
	@echo ">> Coverage saved: $(COV_DB)"

## Interactive GUI with coverage enabled
gui_cov: compile_cov
	mkdir -p $(RUN_DIR)
	$(VSIM) $(VSIM_OPTS) -coverage $(WORK).$(TOP) \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	  -l $(RUN_LOG)

## Generate an HTML coverage report for the current TEST
cover_report:
	$(VCOVER) report -html $(COV_DB) -htmldir $(COV_HTML) -details
	@echo ">> Report: $(COV_HTML)/index.html"

## --------------------------- Regression ------------------------------------

## Run every test listed in $(TESTLIST) (one test name per line,
## '#' comments and blank lines ignored). Compiles once, then loops.
regression: compile
	@if [ ! -f $(TESTLIST) ]; then \
	  echo "ERROR: testlist file '$(TESTLIST)' not found."; exit 1; \
	fi
	@echo ">> Running regression from $(TESTLIST)";
	@fail=0; \
	for t in $$(grep -v '^\s*#' $(TESTLIST) | grep -v '^\s*$$'); do \
	  echo ""; \
	  echo ">> ---- Running test: $$t ----"; \
	  mkdir -p run_$$t; \
	  $(VSIM) $(VSIM_OPTS) $(WORK).$(TOP) \
	    +UVM_TESTNAME=$$t +UVM_VERBOSITY=$(VERBOSITY) -sv_seed $(SEED) \
	    -l run_$$t/$$t.log -wlf run_$$t/waveform.wlf \
	    -do "run -all; exit"; \
	  if grep -q "UVM_FATAL\|UVM_ERROR" run_$$t/$$t.log; then \
	    echo ">> FAIL: $$t (see run_$$t/$$t.log)"; fail=1; \
	  else \
	    echo ">> PASS: $$t"; \
	  fi; \
	done; \
	echo ""; \
	if [ $$fail -eq 1 ]; then \
	  echo ">> Regression finished WITH FAILURES."; exit 1; \
	else \
	  echo ">> Regression finished, all tests PASSED."; \
	fi

## --------------------------- Housekeeping -----------------------------------

## Remove all generated simulation artifacts, including all run_* folders
## (rm -rf works on Linux/macOS/WSL/Git-Bash; not native cmd.exe)
clean:
	rm -rf $(CLEAN_TARGETS)