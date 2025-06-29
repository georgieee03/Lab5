# Makefile for MIPS Pipelined Processor Verification

# Default target
all: run

# Tool setup
VCS = vcs -full64 -sverilog -ntb_opts uvm -debug_access+all +define+SYNOPSYS +acc
VERDI = verdi -sv -f filelist.f &

# Compilation target – produces the simulator executable
simv:
	$(VCS) -f filelist.f -l comp.log

# Simulation target
run: simv
	./simv -l sim.log +ntb_random_seed=1

# Run with a specific seed
run-seed: simv
	./simv -l sim.log +ntb_random_seed=$(SEED)

# GUI target
gui: simv
	$(VERDI)

# Clean target
clean:
	rm -rf AN.DB DVEfiles/ csrc/ simv* *.vdb *.key *.log* urgReport/ *.h 

.PHONY: clean run run-seed gui 