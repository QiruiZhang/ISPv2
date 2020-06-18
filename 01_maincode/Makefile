#############################################################################################
## Makefile FOR MEMBER NODE VERILOG SIMULATION
##-------------------------------------------------------------------------------------------
## < USAGE >
##
##          make            : Compile & run without VPD dump
##          make vpd        : Compile & run with VPD dump
##          make check      : Comparison with golden-brick
##          make commit     : Make current output file a golden-brick
##          make report     : Print VCS warning/lint report
##
## < IMPORTANT > 
##
##      1. You need to set TYPE variable before running simulation.
##
##          You can directly edit TYPE variable in this file.
##
##              Valid Value     Description
##              -----------------------------------------
##                  BHV         Behavioral Simulation
##                  SYN         Post-Synthesis Simulation
##                  APR         Post-APR Simulation
##
##          Or you can also invoke Makefile with argument as shown below
##
##              make [recipe] TYPE=BHV      // Behavioral Simulation
##              make [recipe] TYPE=SYN      // Post-Synthesis Simulation
##              make [recipe] TYPE=APR      // Post-APR Simulation
##
##      2. You need to include the following path in your .cshrc file
##
##              /afs/eecs.umich.edu/vlsida/projects/m3_hdk/scripts/bin
##
##      3. You need to define the following variable in this Makefile,
##          before running simulations. See instructions above the variable definition.
##
##              LEAF_VERILOG_FILES
##
##      4. You need to prepare golden output files in order to use 'make check' and 'make commit'
##
##              Behavioral: $(GOLD_DIR)/$(TARGET).out.gold
##              Post-Synth: $(GOLD_DIR)/$(TARGET).syn.out.gold
##              Post-APR  : $(GOLD_DIR)/$(TARGET).apr.out.gold
##
##-------------------------------------------------------------------------------------------
## < UPDATE HISTORY >
##  Sep 29 2017 -   Recommited from previous Makefile in mm3_node (Yejoong Kim)
##                  Created LEAF_VERILOG_FILES to avoid redundancy
##                  Removed outdated 'vcd' generation recipe
##                  Removed NTC, RECREM options (may needed for TSMC90 standard cells)
##                  Added use of m3_removeTimeInfo for comparison with golden output
##  Jun 07 2018 -   Added 'commit', 'commit.syn', 'commit.apr' recipes
##  Jun 12 2018 -   Added TYPE variable and re-structured Makefile
##-------------------------------------------------------------------------------------------
## < AUTHOR > 
##  Yejoong Kim (yejoong@umich.edu)
##  Hyochan An 
#############################################################################################
P = 1
ROW = 480
COL = 792
NE_PRELOAD = 0
PRELOAD_SRAM_SRSW = 0

#####################
## Simulation Type ##
#####################
#-- See header section for valid values
TYPE    ?= APR

##################
## DUT and MBus ##
##################

LAYER   = CMP
TARGET  = CMPv1
MBUS_VER = r05
APR_VER = 1_0207

#################
## Directories ##
#################

CURRENT_PATH= $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
M3_HDK      = /afs/eecs.umich.edu/vlsida/projects/m3_hdk
M3_SDK      = /afs/eecs.umich.edu/vlsida/projects/m3_sdk
NET_DIR     = $(CURRENT_PATH)../../verilog
SYN_DIR     = /afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/CMPv1_git/synth/top
#APR_DIR     = /afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/CMPv1_git/apr/top/latest_output
APR_DIR     	= /afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/CMPv2_git/top_db/$(APR_VER)
GOLD_DIR    	= $(CURRENT_PATH)gold
MBUSTB_DIR  	= /afs/eecs.umich.edu/vlsida/projects/m3_hdk/IP/mbus/$(MBUS_VER)/mbus_testbench

###############
## VCS Flags ##
###############
VFLAGS_main =   +v2k +vc -sverilog +systemverilogext+sv  -timescale=1ns/1ps +vcs+lic+wait \
                +multisource_int_delays +plusarg_save +overlap -full64 -Mupdate -lca  +libext+.v+.vlib+.vh \
                 -cm_libs yv+celldefine  \
                +neg_tchk  \
				-debug_access+all -debug_pp \
				+noerrorIOPCWM +nowarnTFMPC \
				#+vcs+dumparrays +memcbk \
				#-cm line+cond+fsm+tgl  \
				#-P ${NOVAS_HOME}/share/PLI/VCS/LINUX64/novas.tab \
				#${NOVAS_HOME}/share/PLI/VCS/LINUX64/pli.a 
#+lint=all,noVCDE,noNS +warn=all -sdfretain
#-cm_hier $(TARGET).hier
                #-debug_access+pp+all 
##########################
## m3_genRptVcs Options ##
##########################
#-- List all the warnings/lint messages you can ignore

GENRPTVCS_FLAGS	=   -i2 VCDE \
					-i2 ZERO \
					-i2 OUDPE \
                    -i2 SDFCOM_SWC \
                    -i2 SDFCOM_UHICD \
			        -i2 BMII \
                    -i3 IWNF:FE_UNCONNECTED \
                    -i3 IWU:FE_UNCONNECTED \
                    -i3 VNGS:FE_UNCONNECTED \
                    -i3 TFIPC-L:\(OUTPUT\) \

########################
## Leaf Verilog Files ##
########################

# -- List all verilog files having non-synthesizable behavioral description, 
#    such as standard cell verilog model files, or custom block verilog models files.
#    Use -v.
LEAF_VERILOG_FILES   = 	-v \
						$(NET_DIR)/tcbn40lpbwp.v \
						$(NET_DIR)/tcbn40lpbwphvt.v \
						$(NET_DIR)/N40LP_std_cell_io.v \
						$(NET_DIR)/LC0P6TO1P2ISOLGFX1HVT.v\
						$(NET_DIR)/HEADER.v \
						$(NET_DIR)/ESD_PAD.v \
						$(NET_DIR)/CLK_GEN.v \
						$(NET_DIR)/Comparator_Top.v 
SRAM_BEHAVIORAL_FILES   =  \
						#$(NET_DIR)/common/clock_gating_ctrl.v\
						#$(NET_DIR)/common/SRAM_128x512.v\
						#$(NET_DIR)/common/SRAM_128x512_SW_behave.v\
						#$(NET_DIR)/common/SRAM_FSM_128x512.v\
						#$(NET_DIR)/common/SRAM_256x256.v\
						#$(NET_DIR)/common/SRAM_256x256_SW_behave.v\
						#$(NET_DIR)/common/SRAM_FSM_256x256.v\
						#$(NET_DIR)/common/SRAM_32x32.v\
						#$(NET_DIR)/common/SRAM_32x32_SW_behave.v\
						#$(NET_DIR)/common/SRAM_FSM_32x32.v\
						#$(NET_DIR)/common/SRAM_64x512.v\
						#$(NET_DIR)/common/SRAM_64x512_SW_behave.v\
						#$(NET_DIR)/common/SRAM_FSM_64x512.v
						#$(NET_DIR)/common/SRAM_128x512_behaviour_old.v\
						#$(NET_DIR)/common/SRAM_256x256_behaviour_old.v\
						#$(NET_DIR)/common/SRAM_32x32_behaviour_old.v  \
						#$(NET_DIR)/common/SRAM_64x512_behaviour_old.v 
SRAM_NETLIST_FILES   =  \
						$(NET_DIR)/common/SRAM_137x512_respin_behave.v \
						$(NET_DIR)/common/SRAM_274x256_respin_behave.v \
						$(NET_DIR)/common/SRAM_39x32_respin_behave.v \
						$(NET_DIR)/common/SRAM_72x512_respin_behave.v
TESTENV_FILES   =	 \
					$(CURRENT_PATH)IMAGER_LAYER.v \
					$(CURRENT_PATH)FLS_LAYER.v 

########################################
## Settings for Behavioral Simulation ##
########################################
ifeq      ($(TYPE), BHV)

#-- [BHV SIM] List all the directories that have verilog files whose filename is same as its module name
SEARCH_DIRS	    =	-y $(NET_DIR)/ \
				    -y $(NET_DIR)/mbus/ \
				    -y $(NET_DIR)/genRF/ \
                    -y $(MBUSTB_DIR) \
				    -y ./ \

FILE_LIST 	    =	-f $(NET_DIR)/flist.f 

#-- [BHV SIM] List all the directories that have 'include' files (e.g, def files)
INCLUDE_DIRS    =	+incdir+$(NET_DIR)/ \
				    +incdir+$(NET_DIR)/mbus/ \
                    +incdir+$(MBUSTB_DIR) \
				    +incdir+./ \

#-- [BHV SIM] List all the verilog files where verilog module names are not equal to its file name
VERILOG_FILES   =	$(NET_DIR)/$(TARGET)_def.v \
                    $(LEAF_VERILOG_FILES) \
					$(SRAM_BEHAVIORAL_FILES)

#-- [BHV SIM] File Name Prefix
PREFIX          =   $(TARGET)

#-- [BHV SIM] VCS Flags
VFLAGS          =   $(VFLAGS_main) +define+SIM+DEBUG+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)
VFLAGS_vpd      =   $(VFLAGS_main) +define+SIM+DEBUG+VPD_DUMP+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)
VFLAGS_fsdb     =   $(VFLAGS_main) +define+SIM+DEBUG+FSDB_DUMP+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)

############################################
## Settings for Post-Synthesis Simulation ##
############################################
else ifeq ($(TYPE), SYN)

#-- [SYN SIM] List all the directories that have testbenches (including MBus testbench files)
SEARCH_DIRS     =   -y $(MBUSTB_DIR) \

#-- [SYN SIM] List all the directories that have 'include' files that is included in testbenches (including MBus testbench files)
INCLUDE_DIRS    =   +incdir+$(NET_DIR) \
					+incdir+$(MBUSTB_DIR) \
                    +incdir+./ \

FILE_LIST 	    =    \
					$(SYN_DIR)/$(TARGET).nl.v 

#-- [SYN SIM] List all the files required for building a complete 'TARGET' system
VERILOG_FILES   =	$(LEAF_VERILOG_FILES) \
					$(SYN_DIR)/../NE/latest_output/NEURALENGINE_TOP.nl.v \
					$(SRAM_BEHAVIORAL_FILES)

#-- [SYN SIM] File Name Prefix
PREFIX          =   $(TARGET).syn

#-- [SYN SIM] VCS Flags
VFLAGS          =   $(VFLAGS_main) +define+SIM+SYN+DEBUG+SDF+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)
VFLAGS_vpd      =   $(VFLAGS_main) +define+SIM+SYN+DEBUG+SDF+VPD_DUMP+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)
VFLAGS_fsdb     =   $(VFLAGS_main) +define+SIM+SYN+DEBUG+SDF+FSDB_DUMP+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)

######################################
## Settings for Post-APR Simulation ##
######################################
else ifeq ($(TYPE), APR)

#-- [APR SIM] List all the directories that have testbenches (including MBus testbench files)
SEARCH_DIRS     =   -y $(MBUSTB_DIR) \
					-y ./ \

#-- [APR SIM] List all the directories that have 'include' files that is included in testbenches (including MBus testbench files)
INCLUDE_DIRS    =   +incdir+$(MBUSTB_DIR) \
					+incdir+./ \

FILE_LIST 	    =    /afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/CMPv2_git/top_db/$(APR_VER)/$(TARGET).apr.v \
					$(SRAM_NETLIST_FILES)

#-- [APR SIM] List all the files required for building a complete 'TARGET' system
VERILOG_FILES   =	$(LEAF_VERILOG_FILES) \
			$(APR_DIR)/../../apr/NE/latest_apr/NEURALENGINE_TOP.apr.v \

#-- [APR SIM] File Name Prefix
PREFIX          =   $(TARGET).apr

#-- [APR SIM] VCS Flags
VFLAGS          =   $(VFLAGS_main) +define+SIM+APR+SDF+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)
VFLAGS_vpd      =   $(VFLAGS_main) +define+SIM+APR+SDF+VPD_DUMP+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)
VFLAGS_fsdb     =   $(VFLAGS_main) +define+SIM+APR+SDF+FSDB_DUMP+PROGRAM=$(P)+NE_PRELOAD=$(NE_PRELOAD)+PRELOAD_SRAM_SRSW=$(PRELOAD_SRAM_SRSW)

endif

######################
## Makefile Recipes ##
######################

#-- Commands
VV              = vcs
SIMV            = ./simv -cm line+cond+fsm+tgl
URG             = urg -full64 -dir simv.vdb -report ./REPORTS/$(TARGET)/

#-- File names
ifeq ($(TYPE), APR)
LOG_FILE        =   $(PREFIX)_$(P).log
OUT_FILE        =   $(PREFIX)_$(P).out
RPT_FILE        =   $(PREFIX)_$(P).vcs.rpt
else
LOG_FILE        =   $(PREFIX)_$(P).log
OUT_FILE        =   $(PREFIX)_$(P).out
RPT_FILE        =   $(PREFIX)_$(P).vcs.rpt
endif

GOLD_FILE       =   $(GOLD_DIR)/$(PREFIX)_$(P).out.gold

#-- Recipes
all: $(TARGET)

soft :
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_0 -change MBUS_PROG_NUM_BYTES_0
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_1 -change MBUS_PROG_NUM_BYTES_1
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_2 -change MBUS_PROG_NUM_BYTES_2
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_3 -change MBUS_PROG_NUM_BYTES_3
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_4 -change MBUS_PROG_NUM_BYTES_4
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_5 -change MBUS_PROG_NUM_BYTES_5
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_6 -change MBUS_PROG_NUM_BYTES_6
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_7 -change MBUS_PROG_NUM_BYTES_7
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_8 -change MBUS_PROG_NUM_BYTES_8
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_9 -change MBUS_PROG_NUM_BYTES_9
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_10 -change MBUS_PROG_NUM_BYTES_10
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_11 -change MBUS_PROG_NUM_BYTES_11
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_12 -change MBUS_PROG_NUM_BYTES_12
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_13 -change MBUS_PROG_NUM_BYTES_13
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_14 -change MBUS_PROG_NUM_BYTES_14
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_15 -change MBUS_PROG_NUM_BYTES_15
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_16 -change MBUS_PROG_NUM_BYTES_16
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_17 -change MBUS_PROG_NUM_BYTES_17
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_18 -change MBUS_PROG_NUM_BYTES_18
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_19 -change MBUS_PROG_NUM_BYTES_19
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_20 -change MBUS_PROG_NUM_BYTES_20
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_21 -change MBUS_PROG_NUM_BYTES_21
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_22 -change MBUS_PROG_NUM_BYTES_22
	@ cd ./software && make
	@ m3_updateProgNumBytes $(TARGET)_prog_def.v -search MBUS_PROG_DATA_23 -change MBUS_PROG_NUM_BYTES_23

clean:
	rm -rf ./simv ./simv* ./csrc ./ucli.key ./vcs.prof ./inter.vpd ./DVEfiles ./vcs.key ./*.log REPORTS/* ./verdiLog ./novas.conf ./silotiLog  flist.sim.f $(TARGET)*.out ./$(TARGET)*.vcs.rpt ./novas.rc ./*vpd ./simv.vdb ./simv.daidir

compile:
	$(VV) $(VFLAGS)      -l $(LOG_FILE) $(VERILOG_FILES) $(TESTENV_FILES) $(SEARCH_DIRS) $(INCLUDE_DIRS) $(FILE_LIST) ./$(TARGET)_test.sv

compile.vpd:
	$(VV) $(VFLAGS_vpd)  -l $(LOG_FILE) $(VERILOG_FILES) $(TESTENV_FILES) $(SEARCH_DIRS) $(INCLUDE_DIRS) $(FILE_LIST) ./$(TARGET)_test.sv

compile.fsdb:
	$(VV) $(VFLAGS_fsdb) -l $(LOG_FILE) $(VERILOG_FILES) $(TESTENV_FILES) $(SEARCH_DIRS) $(INCLUDE_DIRS) $(FILE_LIST) ./$(TARGET)_test.sv

run: 
	$(SIMV) | tee $(OUT_FILE)

gui: 
	$(SIMV) -gui &

report:
	@ m3_genRptVcs -i $(LOG_FILE) -o $(RPT_FILE) $(GENRPTVCS_FLAGS)
	@ echo "";
	@ echo "[INFO] --- VCS Report ...";
	@ echo "";
	@ cat $(RPT_FILE)
	@ echo "";
	@ echo "[INFO] --- End of VCS Report ...";

coverage:
	$(URG)

check:
	@ m3_removeTimeInfo $(PREFIX)
	@ gvim -d $(GOLD_FILE) $(OUT_FILE).noTime

commit:
	@ cp -f $(GOLD_FILE) $(GOLD_FILE).bak
	@ cp -f $(OUT_FILE).noTime $(GOLD_FILE)

$(TARGET): compile run 

$(TARGET).vpd : compile.vpd run 


vpd: $(TARGET).vpd

ifeq ($(TYPE), APR)
$(TARGET)_$(APR_VER).fsdb: compile.fsdb run 
fsdb: $(TARGET)_$(APR_VER).fsdb
else
$(TARGET).fsdb: compile.fsdb run 
fsdb: $(TARGET).fsdb 
endif

check0: 
	@python find_err.py $(PREFIX)_0.out ERR
check1: 
	@python find_err.py $(PREFIX)_1.out ERR
	@python check_result.py 1
check2:
	@python find_err.py $(PREFIX)_2.out ERR
	@python check_result.py 2
check3:
	@python find_err.py $(PREFIX)_3.out ERR
	@python check_result.py 3
check4: 
	@python find_err.py $(PREFIX)_4.out ERR
	@python check_result.py 4
check5: 
	@python find_err.py $(PREFIX)_5.out ERR
check6: 
	@python find_err.py $(PREFIX)_6.out ERR
	@python check_result.py 6
check7:
	@python find_err.py $(PREFIX)_7.out ERR
	@python check_result.py 7
check8: 
	@python find_err.py $(PREFIX)_8.out ERR
	@python check_result.py 8
check9: 
	@python find_err.py $(PREFIX)_9.out ERR
check10: 
	@python find_err.py $(PREFIX)_10.out ERR
check11: 
	@python find_err.py $(PREFIX)_11.out ERR
check12:
	@python find_err.py $(PREFIX)_12.out ERR
	@python bit_compile.py c 8 30720
	@python compare_output.py c y_gold_fls_0.txt
check13:
	@python find_err.py $(PREFIX)_13.out ERR
	@python bit_compile.py d 12 46080 
	@python compare_output.py d g_gold_fls_1.txt
check14:
	@python find_err.py $(PREFIX)_14.out ERR
check15: 
	@python find_err.py $(PREFIX)_15.out ERR
check16: 
	@python find_err.py $(PREFIX)_16.out ERR
	@python check_result.py 16
check17: 
	@python find_err.py $(PREFIX)_17.out ERR
	@python check_result.py 17
check18: 
	@python find_err.py $(PREFIX)_18.out ERR
	@python check_result.py 18
verdi: 
	@ verdi -sverilog -2012 -autoalias $(TESTENV_FILES) $(VERILOG_FILES) $(SEARCH_DIRS) $(INCLUDE_DIRS) $(FILE_LIST) ./$(TARGET)_test.sv -top $(TARGET)_test & 		
#P=0 SFR SRAM; 1 REF FRAME; 2 CUR REF FRAME; 3 IMGIF DEBUG PATH; 4 MD FRAME; 5 MBUS; 6 SMALL FRM 4x4 TEST; 7 FULL TEST; 8 Changed MCB only; 9 MBUS debugging feature; 10 H264 DEBUGGIGN; 15 SRAM access;
.PHONY:   $(TARGET) $(TARGET).vpd compile compile.vpd run report check commit soft vd check0 check1 check2 check3 check4 check5 check6 check7
