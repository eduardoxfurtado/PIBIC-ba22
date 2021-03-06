#---------------------------------------------------------------------
#
# Copyright (c) 2011-2012 CAST, Inc.
#
# Please review the terms of the license agreement before using this
# file.  If you are not an authorized user, please destroy this source
# code file and notify CAST immediately that you inadvertently received
# an unauthorized copy.
#--------------------------------------------------------------------
#
#  Project       : BA22
#
#  File          : modelsim.tcl
#
#  Purpose       : Compilation and Simulation script for ModelSim
#
#  Designer      : JS
#
#  QA Engineer   : NS
#
#  Creation Date : October 1, 2011
#
#  Last Update   : April 4, 2012
#
#  Version       : 1.02
#
#  Usage         : vsim -c -do modelsim_altera.tcl
#
#  File History  : March 28, 2012 (1.01) : Initial release
#
#----------------------------------------------------------------------
#
set CONFIG "de_fpu32_dfchip"
set TESTNAME "ba22-pic"

if {$argc > 1} {
  set CONFIG $1
  set TESTNAME $2
}

if {$CONFIG == ""} {
  puts stderr "CONFIG is not defined"
  exit 
}

if {$TESTNAME == ""} {
  puts stderr "TESTNAME is not defined"
  exit 
}

echo "Config: $CONFIG and Testcase: $TESTNAME"

set BA22_ROOT ..
set NETLIST_PATH $BA22_ROOT/netlist/altera_cycloneiv
set BA22_PATH $BA22_ROOT/src/synth/common/ba22
set MODELS_PATH $BA22_ROOT/src/synth/common/models
set WRAPPERS_PATH $BA22_ROOT/src/synth/common/wrappers
set BA22_CONFIG_PATH $BA22_ROOT/src/synth/config/$CONFIG
set FILELIST_PATH $BA22_CONFIG_PATH
set SIM_PATH $BA22_ROOT/src/sim
set TEST_PATH $BA22_ROOT/tests/$CONFIG

# ------------------------------
puts "Info : Creating library"
# ------------------------------
set HDL_LIBRARY work
vlib $HDL_LIBRARY

set INCDIR_VAR +incdir+$BA22_CONFIG_PATH+$BA22_PATH+$SIM_PATH
set INSTR_FILE $TEST_PATH/$TESTNAME/Debug/$TESTNAME.verilog

# ----------------------------------------------------
puts "Info : Compiling Altera CycloneIV files"
# ----------------------------------------------------
vlog -work $HDL_LIBRARY C:/altera/11.0/quartus/eda/sim_lib/cycloneiv_atoms.v
vlog -work $HDL_LIBRARY C:/altera/11.0/quartus/eda/sim_lib/cycloneive_atoms.v
vlog -work $HDL_LIBRARY C:/altera/11.0/quartus/eda/sim_lib/altera_mf.v
vlog -work $HDL_LIBRARY C:/altera/11.0/quartus/eda/sim_lib/altera_primitives.v

# ----------------------------------------------------
puts "Info : Compiling BA22 top level file"
# ----------------------------------------------------
vlog -work $HDL_LIBRARY $NETLIST_PATH/ba22_top.vo

# ----------------------------------------------------
puts "Info : Compiling QMEM and BA22 top qmem model files"
# ----------------------------------------------------
vlog -work $HDL_LIBRARY $INCDIR_VAR \
   $MODELS_PATH/tdpram8.v \
   $MODELS_PATH/tdpram32.v \
   $SIM_PATH/tdpram64_32.v \
   $MODELS_PATH/dpram8.v \
   $MODELS_PATH/sram8.v \
   $SIM_PATH/sram32.v \
   $MODELS_PATH/sram64.v \
   $MODELS_PATH/qmem_arbiter.v \
   $WRAPPERS_PATH/ba22_top_qmem.v


# -------------------------------------
puts "Info : Compiling testbench files"
# -------------------------------------
vlog -work $HDL_LIBRARY $INCDIR_VAR \
   $SIM_PATH/qmem_ctrl.v \
   $SIM_PATH/initram32.v \
   $SIM_PATH/c_clgen.v \
   $SIM_PATH/ahb_slave_behavioral.v \
   $SIM_PATH/monitor.v

vlog -work $HDL_LIBRARY $INCDIR_VAR $SIM_PATH/bench.v 

onbreak {
  echo "Resume macro at $now"
  resume
}

# -------------------------------------
puts "Info : Running Simulation"
# -------------------------------------
file copy -force $INSTR_FILE rom.verilog
vsim -novopt -t ps -L work -sdftyp /bench/i_ba22_top_qmem/i_ba22_top=$NETLIST_PATH/ba22_top_v.sdo -voptargs=+acc work.bench
#vsim -novopt -t ps -L work -voptargs=+acc work.bench
#do wave.do
add wave *

add wave i_dahbs/sz2sel/*
add wave i_dahbs/*
view structure

run -all
# run 700 us

# exit
