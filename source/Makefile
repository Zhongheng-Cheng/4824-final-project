# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#
#

SOURCE = test_progs/rv32_insertion.s

CRT = crt.s
LINKERS = linker.lds
ASLINKERS = aslinker.lds

DEBUG_FLAG = -g
CFLAGS =  -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div 
OFLAGS = -O0
ASFLAGS = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align
OBJFLAGS = -SD -M no-aliases 
OBJDFLAGS = -SD -M numeric,no-aliases

##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################
ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif

GREP = grep -E --color=auto

################################
# ---- Module Testbenches ---- #
################################

# This section facilitates creating individual testbenches for your modules
# By using the following naming convention:
# - the source file: 'verilog/rob.sv'
# - declares a module: 'rob'
# - with testbench in: 'test/rob_test.sv'
# - added to TESTED_MODULES as: 'rob'
# - with dependencies: 'rob.simv', 'rob.cov', and 'synth/rob.vg'

# TODO: add more modules here
TESTED_MODULES = mult rob

# TODO: add verilog module dependencies here:
# (do not include header files)
# Helper function:
DEPS = $(1).simv $(1).cov synth/$(1).vg

MULT_DEPS = verilog/mult_stage.sv
$(call DEPS,mult): $(MULT_DEPS)

# No dependencies for the rob (TODO: add any you create)
ROB_DEPS =
$(call DEPS,rob): $(ROB_DEPS)

# This allows you to use the following make targets:
# make <module>.pass   <- greps for "@@@ Passed" or "@@@ Incorrect" in the output
# make <module>.out    <- run the testbench (via <module>.simv)
# make <module>.simv   <- compile the testbench executable
# make <module>.verdi  <- run in verdi (via <module>.simv)
# make <module>.syn.pass   <- greps for "@@@ Passed" or "@@@ Incorrect" in the output
# make <module>.syn.out    <- run the synthesized module on the testbench
# make <module>.syn.simv   <- compile the synthesized module with the testbench
# make synth/<module>.vg   <- synthesize the module
# make <module>.syn.verdi  <- run in verdi (via <module>.syn.simv)

# We have also added targets for checking testbench coverage:
# make <module>.coverage    <- print the coverage hierarchy report to the terminal
# make <module>.cov.verdi   <- open the coverage report in verdi
# make <module>.cov         <- compiles a coverage executable for the module and testbench
# make <module>.cov.vdb     <- runs the executable and creates the <module>.cov.vdb directory
# make <module>_cov_report  <- run urg to create human readable coverage reports

# The following Makefile targets heavily use pattern substitution and static pattern rules
# See these links if you're curious about how these work:
# - https://www.gnu.org/software/make/manual/html_node/Text-Functions.html
# - https://www.gnu.org/software/make/manual/html_node/Static-Usage.html
# - https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html

# You shouldn't need to change things below here

# ---- Running ---- #

# run compiled executables ('make %.out' is linked to 'make output/%.out' further below)
# using this syntax avoids overlapping with the 'make <my_program>.out' targets
$(TESTED_MODULES:%=output/%.out) $(TESTED_MODULES:%=output/%.syn.out): output/%.out: %.simv | output
	@$(call PRINT_COLOR, 5, running $<)
	./$< | tee $@
	@$(call PRINT_COLOR, 2, output is in $@)

# print in green or red passed or failed (must $display @@@ Passed or @@@ Incorrect)
%.pass: output/%.out
	@GREP_COLOR="01;31" $(GREP) -i '@@@ ?Incorrect' $< || \
	GREP_COLOR="01;32" $(GREP) -i '@@@ ?Passed' $<
.PHONY: %.pass

# run many types of things in verdi
%.verdi: %.simv
	@$(call PRINT_COLOR, 5, running $< with verdi )
	./$< -gui=verdi
.PHONY: %.verdi

# ---- Compiling Verilog ---- #

# the normal simulation executable will run your testbench on simulated modules
$(TESTED_MODULES:=.simv): %.simv: test/%_test.sv verilog/%.sv $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $(filter-out $(HEADERS),$^) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

# this also generates many other files, see the tcl script's introduction for info on each of them
synth/%.vg: verilog/%.sv $(TCL_SCRIPT) $(HEADERS)
	@$(call PRINT_COLOR, 5, synthesizing the $* module)
	@$(call PRINT_COLOR, 3, this might take a while...)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	# pipefail causes the command to exit on failure even though it's piping to tee
	set -o pipefail; cd synth && \
	MODULE=$* SOURCES="$(filter-out $(TCL_SCRIPT) $(HEADERS),$^)" \
	dc_shell-t -f $(notdir $(TCL_SCRIPT)) | tee $*_synth.out
	@$(call PRINT_COLOR, 6, finished synthesizing $@)

# the synthesis executable runs your testbench on the synthesized versions of your modules
$(TESTED_MODULES:=.syn.simv): %.syn.simv: test/%_test.sv synth/%.vg $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the synthesis executable $@)
	$(VCS) +define+SYNTH $(filter-out $(HEADERS),$^) $(LIB) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

# ---- Coverage targets ---- #

# This section adds targets to run module testbenches with coverage output

# VCS argument to both build and run for coverage
VCS_COVG = -cm line+fsm+cond+tgl+branch

$(TESTED_MODULES:=.cov): %.cov: test/%_test.sv verilog/%.sv $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the coverage executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $(VCS_COVG) $(filter-out $(HEADERS),$^) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

# Run the testbench to produce a *.vdb directory with coverage info
$(TESTED_MODULES:%=output/%.cov.out): output/%.cov.out: %.cov | output
	@$(call PRINT_COLOR, 5, running $<)
	./$< $(VCS_COVG) | tee output/$*.cov.out
	@$(call PRINT_COLOR, 2, created coverage dir $<.vdb and saved output to $@)

# A layer of indirection is needed to avoid re-making??? :/
%.cov.vdb: output/%.cov.out ;

# Use urg to generate human-readable report files in text mode (alternative is html)
$(TESTED_MODULES:=_cov_report): %_cov_report: %.cov.vdb | output
	@$(call PRINT_COLOR, 5, outputting coverage report in $@)
	urg -format text -dir $< -report $@
	@$(call PRINT_COLOR, 2, coverage report is in $@)

# view the coverage hierarchy report
$(TESTED_MODULES:=.coverage): %.coverage: %_cov_report
	@$(call PRINT_COLOR, 2, printing coverage hierarchy - see $< for more)
	cat $</hierarchy.txt

# open the coverage info in verdi
$(TESTED_MODULES:=.cov.verdi): %.cov.verdi: %.cov.vdb
	@$(call PRINT_COLOR, 5, opening verdi for $* coverage)
	./$< -gui=verdi -cov -covdir $<

.PHONY: %.coverage %.cov.verdi

####################################
# ---- Executable Compilation ---- #
####################################

# NOTE: the executables are not the only things you need to compile
# you must also create a programs/*.mem file for each program you run
# which will be loaded into test/mem.sv by the testbench on startup
# To run a program on simv or syn_simv, see the program execution section
# This is done automatically with 'make <my_program>.out'

HEADERS = verilog/sys_defs.svh \
          verilog/ISA.svh

# TESTBENCH = test/pipeline_test.sv \
#             test/pipeline_print.c \
#             test/mem.sv

TESTBENCH = test/CDB_test.sv


# you could simplify this line with $(wildcard verilog/*.sv) - but the manual way is more explicit
# SOURCES = verilog/pipeline.sv \
#           verilog/regfile.sv \
#           verilog/icache.sv \
#           verilog/mult.sv \
#           verilog/mult_stage.sv \


SOURCES = verilog/data_structures/CDB.sv


SYNTH_FILES = synth/pipeline.vg

# the normal simulation executable will run your testbench on the original modules
simv: $(TESTBENCH) $(SOURCES) $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $(filter-out $(HEADERS),$^) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

# NOTE: this has been changed to avoid conflicting with the module %.vg rule
# this also generates many other files, see the tcl script's introduction for info on each of them
synth/pipeline.vg: $(SOURCES) $(TCL_SCRIPT) $(HEADERS)
	@$(call PRINT_COLOR, 5, synthesizing the pipeline)
	@$(call PRINT_COLOR, 3, this might take a while...)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	# pipefail causes the command to exit on failure even though it's piping to tee
	set -o pipefail; cd synth && \
	MODULE=pipeline SOURCES="$(SOURCES)" \
	dc_shell-t -f $(notdir $(TCL_SCRIPT)) | tee pipeline_synth.out
	@$(call PRINT_COLOR, 6, finished synthesizing $@)

# the synthesis executable runs your testbench on the synthesized versions of your modules
syn_simv: $(TESTBENCH) $(SYNTH_FILES) $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the synthesis executable $@)
	$(VCS) +define+SYNTH $(filter-out $(HEADERS),$^) $(LIB) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

# a phony target to view the slack in the *.rep synthesis report file
slack:
	$(GREP) "slack" synth/*.rep
.PHONY: slack

########################################
# ---- Program Memory Compilation ---- #
########################################

# this section will compile programs into .mem files to be loaded into memory
# you start with either an assembly or C program in the programs/ directory
# those compile into a .elf link file via the riscv assembler or compiler
# then that link file is converted to a .mem hex file

# find the test program files and separate them based on suffix of .s or .c
# filter out files that aren't themselves programs
NON_PROGRAMS = $(CRT)
ASSEMBLY = $(filter-out $(NON_PROGRAMS),$(wildcard programs/*.s))
C_CODE   = $(filter-out $(NON_PROGRAMS),$(wildcard programs/*.c))

# concatenate ASSEMBLY and C_CODE to list every program
PROGRAMS = $(ASSEMBLY:%.s=%) $(C_CODE:%.c=%)

# NOTE: this is Make's pattern substitution syntax
# see: https://www.gnu.org/software/make/manual/html_node/Text-Functions.html#Text-Functions
# this reads as: $(var:pattern=replacement)
# a percent sign '%' in pattern is as a wildcard, and can be reused in the replacement
# if you don't include the percent it automatically attempts to replace just the suffix of the input

# C and assembly compilation files. These link and setup the runtime for the programs
CRT        = programs/crt.s
LINKERS    = programs/linker.lds
ASLINKERS  = programs/aslinker.lds

# make elf files from assembly code
%.elf: %.s $(ASLINKERS)
	@$(call PRINT_COLOR, 5, compiling assembly file $<)
	$(GCC) $(ASFLAGS) $< -T $(ASLINKERS) -o $@

# make elf files from C source code
%.elf: %.c $(CRT) $(LINKERS)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $< -T $(LINKERS) -o $@

# C programs can also be compiled in debug mode, this is solely meant for use in the .dump files below
%.debug.elf: %.c $(CRT) $(LINKERS)
	@$(call PRINT_COLOR, 5, compiling debug C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $< -T $(LINKERS) -o $@
	$(GCC) $(DEBUG_FLAG) $(CFLAGS) $(OFLAGS) $(CRT) $< -T $(LINKERS) -o $@

# declare the .elf files as intermediate files.
# Make will automatically rm intermediate files after they're used in a recipe
# and it won't remake them until their sources are updated or they're needed again
.INTERMEDIATE: %.elf

# turn any elf file into a hex memory file ready for the testbench
%.mem: %.elf
	$(ELF2HEX) --bit-width 64 --input $< --output $@
	@$(call PRINT_COLOR, 6, created memory file $@)
	@$(call PRINT_COLOR, 3, NOTE: to see RISC-V assembly run: '"make $*.dump"')
	@$(call PRINT_COLOR, 3, for \*.c sources also try: '"make $*.debug.dump"')

# compile all programs in one command (use 'make -j' to run multithreaded)
compile_all: $(PROGRAMS:=.mem)
.PHONY: compile_all

########################
# ---- Dump Files ---- #
########################

# when debugging a program, the dump files will show you the disassembled RISC-V
# assembly code that your processor is actually running

# this creates the <my_program>.debug.elf targets, which can be used in: 'make <my_program>.debug.dump_*'
# these are useful for the C sources because the debug flag makes the assembly more understandable
# because it includes some of the original C operations and function/variable names

DUMP_PROGRAMS = $(ASSEMBLY:.c=) $(C_CODE:.c=.debug)

# 'make <my_program>.dump' will create both files at once!
./%.dump: programs/%.dump_x programs/%.dump_abi ;
.PHONY: ./%.dump
# Tell tell Make to treat the .dump_* files as "precious" and not to rm them as intermediaries to %.dump
.PRECIOUS: %.dump_x %.dump_abi

# use the numberic x0-x31 register names
%.dump_x: %.elf
	@$(call PRINT_COLOR, 5, disassembling $<)
	$(OBJDUMP) $(OBJDFLAGS) $< > $@
	@$(call PRINT_COLOR, 6, created numeric dump file $@)

# use the Application Binary Interface register names (sp, a0, etc.)
%.dump_abi: %.elf
	@$(call PRINT_COLOR, 5, disassembling $<)
	$(OBJDUMP) $(OBJFLAGS) $< > $@
	@$(call PRINT_COLOR, 6, created abi dump file $@)

# create all dump files in one command (use 'make -j' to run multithreaded)
dump_all: $(DUMP_PROGRAMS:=.dump_x) $(DUMP_PROGRAMS:=.dump_abi)
.PHONY: dump_all

###############################
# ---- Program Execution ---- #
###############################

# run one of the executables (simv/syn_simv) using the chosen program
# e.g. 'make sampler.out' does the following from a clean directory:
#   1. compiles simv
#   2. compiles programs/sampler.s into its .elf and then .mem files (in programs/)
#   3. runs ./simv +MEMORY=programs/sampler.mem +WRITEBACK=output/sampler.wb +PIPELINE=output/sampler.ppln > output/sampler.out
#   4. which creates the sampler.out, sampler.wb, and sampler.ppln files in output/
# the same can be done for synthesis by doing 'make sampler.syn.out'
# which will also create .syn.wb and .syn.ppln files in output/

# targets built in the 'output/' directory should create output/ if it doesn't exist
# (it's deleted entirely by 'make nuke')
# NOTE: place it after the pipe "|" as an order-only pre-requisite
output:
	mkdir -p output

OUTPUTS = $(PROGRAMS:programs/%=output/%)

# run a program and produce output files
$(OUTPUTS:=.out): output/%.out: programs/%.mem simv | output
	@$(call PRINT_COLOR, 5, running simv on $<)
	./simv +MEMORY=$< +WRITEBACK=$(@D)/$*.wb +PIPELINE=$(@D)/$*.ppln > $@
	@$(call PRINT_COLOR, 6, finished running simv on $<)
	@$(call PRINT_COLOR, 2, output is in $@ $(@D)/$*.wb and $(@D)/$*.ppln)
# NOTE: this uses a 'static pattern rule' to match a list of known targets to a pattern
# and then generates the correct rule based on the pattern, where % and $* match
# so for the target 'output/sampler.out' the % matches 'sampler' and depends on programs/sampler.mem
# see: https://www.gnu.org/software/make/manual/html_node/Static-Usage.html
# $(@D) is an automatic variable for the directory of the target, in this case, 'output'

# this does the same as simv, but adds .syn to the output files and compiles syn_simv instead
# run synthesis with: 'make <my_program>.syn.out'
$(OUTPUTS:=.syn.out): output/%.syn.out: programs/%.mem syn_simv | output
	@$(call PRINT_COLOR, 5, running syn_simv on $<)
	@$(call PRINT_COLOR, 3, this might take a while...)
	./syn_simv +MEMORY=$< +WRITEBACK=$(@D)/$*.syn.wb +PIPELINE=$(@D)/$*.syn.ppln > $@
	@$(call PRINT_COLOR, 6, finished running syn_simv on $<)
	@$(call PRINT_COLOR, 2, output is in $@ $(@D)/$*.syn.wb and $(@D)/$*.syn.ppln)

# Allow us to type 'make <my_program>.out' instead of 'make output/<my_program>.out'
./%.out: output/%.out ;
.PHONY: ./%.out

# Declare that creating a %.out file also creates both %.wb and %.ppln files
%.wb %.ppln: %.out ;

# run all programs in one command (use 'make -j' to run multithreaded)
simulate_all: simv compile_all $(OUTPUTS:=.out)
simulate_all_syn: syn_simv compile_all $(OUTPUTS:=.syn.out)
.PHONY: simulate_all simulate_all_syn

###################
# ---- Verdi ---- #
###################

# run verdi on a program with: 'make <my_program>.verdi' or 'make <my_program>.syn.verdi'

# this creates a directory verdi will use if it doesn't exist yet
verdi_dir:
	mkdir -p /tmp/$${USER}470
.PHONY: verdi_dir

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

%.verdi: programs/%.mem simv novas.rc verdi_dir
	./simv -gui=verdi +MEMORY=$< +WRITEBACK=/dev/null +PIPELINE=/dev/null

%.syn.verdi: programs/%.mem syn_simv novas.rc verdi_dir
	./syn_simv -gui=verdi +MEMORY=$< +WRITEBACK=/dev/null +PIPELINE=/dev/null

.PHONY: %.verdi

#############################
# ---- Visual Debugger ---- #
#############################

# this is the visual debugger for project 3, an extremely helpful tool, try it out!
# compile and run the visual debugger on a program with:
# 'make <my_program>.vis'

# Don't ask me why we spell VisUal TestBenchER like this...
VTUBER = test/vtuber_test.sv \
         test/vtuber.cpp \
		 test/mem.sv

VISFLAGS = -lncurses

vis_simv: $(HEADERS) $(VTUBER) $(SOURCES)
	@$(call PRINT_COLOR, 5, compiling visual debugger testbench)
	$(VCS) $(VISFLAGS) $^ -o vis_simv
	@$(call PRINT_COLOR, 6, finished compiling visual debugger testbench)

%.vis: programs/%.mem vis_simv
	./vis_simv +MEMORY=$<
	@$(call PRINT_COLOR, 6, Fullscreen your terminal for the best VTUBER experience!)
.PHONY: %.vis

#####################
# ---- Cleanup ---- #
#####################

# You should only clean your directory if you think something has built incorrectly
# or you want to prepare a clean directory for e.g. git (first check your .gitignore).
# Please avoid cleaning before every build. The point of a makefile is to
# automatically determine which targets have dependencies that are modified,
# and to re-build only those as needed; avoiding re-building everything everytime.

# 'make clean' removes build/output files, 'make nuke' removes all generated files
# 'make clean' does not remove .mem or .dump files
# clean_* commands remove certain groups of files

clean: clean_exe clean_run_files
	@$(call PRINT_COLOR, 6, note: clean is split into multiple commands you can call separately: $^)

# removes all extra synthesis files and the entire output directory
# use cautiously, this can cause hours of recompiling in project 4
nuke: clean clean_output clean_synth clean_programs
	@$(call PRINT_COLOR, 6, note: nuke is split into multiple commands you can call separately: $^)

clean_exe:
	@$(call PRINT_COLOR, 3, removing compiled executable files)
	rm -rf *simv *.daidir csrc *.key   # created by simv/syn_simv/vis_simv
	rm -rf *.vdb *.vpd vc_hdrs.h       # created by simv/syn_simv/vis_simv
	rm -rf *.cov *cov_report cm.log    # coverage files
	rm -rf verdi* novas* *fsdb*        # verdi files
	rm -rf dve* inter.vpd DVEfiles     # old DVE debugger

clean_run_files:
	@$(call PRINT_COLOR, 3, removing per-run outputs)
	rm -rf output/*.out output/*.wb output/*.ppln

clean_synth:
	@$(call PRINT_COLOR, 1, removing synthesis files)
	cd synth && rm -rf *.vg *_svsim.sv *.res *.rep *.ddc *.chk *.syn *.out *.db *.svf *.mr *.pvl command.log

clean_output:
	@$(call PRINT_COLOR, 1, removing entire output directory)
	rm -rf output/

clean_programs:
	@$(call PRINT_COLOR, 3, removing program memory files)
	rm -rf programs/*.mem
	@$(call PRINT_COLOR, 3, removing dump files)
	rm -rf programs/*.dump*

.PHONY: clean nuke clean_%

######################
# ---- Printing ---- #
######################

# this is a GNU Make function with two arguments: PRINT_COLOR(color: number, msg: string)
# it does all the color printing throughout the makefile
PRINT_COLOR = if [ -t 0 ]; then tput setaf $(1) ; fi; echo $(2); if [ -t 0 ]; then tput sgr0; fi
# colors: 0:black, 1:red, 2:green, 3:yellow, 4:blue, 5:magenta, 6:cyan, 7:white
# other numbers are valid, but aren't specified in the tput man page

# Make functions are called like this:
# $(call PRINT_COLOR,3,Hello World!)
# NOTE: adding '@' to the start of a line avoids printing the command itself, only the output
=======

VCS = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -debug_pp -cm line+tgl
URG = urg -dir simv.vdb -format text
VCS_COV = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -debug_pp -cm line+tgl
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# SIMULATION CONFIG

HEADERS     = $(wildcard *.svh)
TESTBENCH   = testbench/testbench.sv
TESTBENCH  += testbench/mem.sv
TESTBENCH  += $(wildcard testbench/*.c)
PIPEFILES   = $(wildcard verilog/*.sv)
SIMFILES    = $(PIPEFILES)

# Modify here to test single module
MODULE_TESTBENCH = test/reservation_station_testbench.sv
MODULE_SIMFILES = verilog/data_structure/reservation_station.sv
MODULE_HEADER = verilog/sys_defs.svh
MODULE_TCL = null
MODULE_SYN = null
MODULE_PRINT = null


# SYNTHESIS CONFIG
SYNTH_DIR = ./synth

export HEADERS
export PIPEFILES

export PIPELINE_NAME = pipeline

PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv

# Passed through to .tcl scripts:
export CACHE_NAME = icache
export CLOCK_NET_NAME = clk
export RESET_NET_NAME = reset
export CLOCK_PERIOD   = 24	# TODO: You will need to make match SYNTH_CLOCK_PERIOD in sys_defs
                                #       and make this more aggressive

################################################################################
## RULES
################################################################################
cvg:	$(MODULE_HEADER) $(MODULE_SIMFILES) $(MODULE_TESTBENCH) 
	$(VCS_COV) $^ -o simv
	./simv -cm line+tgl
	$(URG)
# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

# Simulation:

sim:	simv
	./simv | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv

test:	module_simv
	./module_simv | tee program.out

module_dve_syn: module_syn_simv 
	./module_syn_simv -gui &


module_simv:	$(MODULE_HEADER) $(MODULE_SIMFILES) $(MODULE_TESTBENCH)
	$(VCS) $(MODULE_HEADER) $(MODULE_TESTBENCH) $(MODULE_SIMFILES) -o module_simv

module_dve:	$(MODULE_HEADER) $(MODULE_SIMFILES) $(MODULE_TESTBENCH) 
	$(VCS) +memcbk $(MODULE_HEADER) $(MODULE_TESTBENCH) $(MODULE_SIMFILES) -o module_dve -R -gui

module_syn_simv: $(MODULE_HEADER) $(MODULE_SYN) $(MODULE_TESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o module_syn_simv 

module_syn: module_syn_simv
		 ./module_syn_simv | tee module_program.out

$(MODULE_SYN): $(MODULE_HEADER) $(MODULE_SIMFILES) $(MODULE_TCL)
		dc_shell-t -f $(MODULE_TCL) | tee synth.out

.PHONY: sim

# Programs

compile: $(CRT) $(LINKERS)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
	$(GCC) $(CFLAGS) $(DEBUG_FLAG) $(CRT) $(SOURCE) -T $(LINKERS) -o program.debug.elf
assemble: $(ASLINKERS)
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf 
	cp program.elf program.debug.elf
disassemble: program.debug.elf
	riscv objcopy --set-section-flags .bss=contents,alloc,readonly program.debug.elf
	$(OBJDUMP) $(OBJFLAGS) program.debug.elf > program.dump
	$(OBJDUMP) $(OBJDFLAGS) program.debug.elf > program.debug.dump
	rm program.debug.elf
hex: program.elf
	$(ELF2HEX) 8 8192 program.elf > program.mem

program: compile disassemble hex
	@:

debug_program:
	gcc -lm -g -std=gnu11 -DDEBUG $(SOURCE) -o debug_bin
assembly: assemble disassemble hex
	@:


# Synthesis

$(PIPELINE): $(SIMFILES) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PIPELINE_NAME).tcl | tee $(PIPELINE_NAME)_synth.out
	echo -e -n 'H\n1\ni\n`timescale 1ns/100ps\n.\nw\nq\n' | ed $(PIPELINE)

syn:	syn_simv 
	./syn_simv | tee syn_program.out

syn_simv:	$(HEADERS) $(SYNFILES) $(TESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o syn_simv 

.PHONY: syn

# Debugging

dve:	sim
	./simv -gui &

dve_syn: syn_sim 
	./syn_simv -gui &

.PHONY: dve dve_syn 

clean:
	rm -rf *simv *simv.daidir csrc vcs.key program.out *.key
	rm -rf vis_simv vis_simv.daidir
	rm -rf dve* inter.vpd DVEfiles module_dve module_dve.daidir module_syn_dve.daidir
	rm -rf syn_simv syn_simv.daidir syn_program.out
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	rm -f *.elf *.dump *.mem debug_bin

nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/*.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl
	rm -rf *.chk *.rep *.ddc *.vg

