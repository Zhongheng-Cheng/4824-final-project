##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################

ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJCOPY = riscv objcopy
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJCOPY = riscv64-unknown-elf-objcopy
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif

VCS = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -kdb -lca -debug_access+all -cm line+fsm+tgl+branch+assert

LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v



##--- Directories Setting --------------

SYNTH_DIR = ./synth

VERILOG_DIR = verilog
TEST_DIR = ../test


TEST_MODULES_DIR = $(TEST_DIR)



##--- Modules Files Setting --------------

export ROB = verilog/rob.sv
export FREELIST = verilog/freelist.sv verilog/ps.sv
export ARCH = verilog/arch.sv
export RS = verilog/rs.sv verilog/ps.sv
export PRF = verilog/prf.sv
export MAPTABLE = verilog/maptable.sv
export FETCH = verilog/fetch.sv
export DISPATCH = verilog/dispatch.sv verilog/decoder.sv
export ISSUE = verilog/issue.sv
export FU = verilog/fu.sv verilog/alu.sv verilog/brcond.sv \
	verilog/fu_alu.sv verilog/mult_stage.sv verilog/mult.sv
export COMPLETE = verilog/complete.sv
export RETIRE = verilog/retire.sv
export ICACHE = verilog/icache.sv
export SQ = verilog/sq.sv verilog/ps.sv

PIPELINETEST = $(TEST_DIR)/pipeline_testbench.sv
export PIPELINE = $(DISPATCH) $(RS) $(ROB) $(FETCH) \
	$(ARCH) $(PRF) $(ISSUE) $(FU) $(COMPLETE) $(RETIRE) \
	$(FREELIST) $(ICACHE) $(MAPTABLE) verilog/pipeline.sv
 
# SIMULATION CONFIG

HEADERS     = $(wildcard *.svh)


#------SYNTHESIS CONFIG----------------------------

export $(wildcard *.svh)
export CLOCK_NET_NAME = clock
export RESET_NET_NAME = reset
export CLOCK_PERIOD   = 12	


################################################################################
## RULES
################################################################################

# Visual debugger:
%.vis: %.out
	visual_debugger/debugger

.PHONY: vis

output:
	mkdir -p output

%.out: simv output
	./simv +FILENAME=$* | tee output/$@
.PHONY: %.out

# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

#----Simulation------------------------------:

sim:	simv
	./simv | tee sim_program.out

simv:	$(HEADERS) $(PIPELINE) $(PIPELINETEST)
	$(VCS) $^ -o simv

.PHONY: sim

# Debugging-------------------

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

verdi_syn:	syn_simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./syn_simv -gui=verdi

clean:
	rm -rf *simv *simv.daidir csrc vcs.key *.out *.key *simv.vdb .fsm.sch.verilog.xml
	rm -rf vis_simv vis_simv.daidir test_results.out
	rm -rf dve* inter.vpd DVEfiles
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out visual_debugger/pipeline.out writeback.out vc_hdrs.h
	rm -f *.elf *.dump debug_bin #.mem
	rm -rf verdi* novas* *fsdb*
	rm -rf output/

nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/*.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl
