######################################################################
#
# File name : tb_serializer_simulate.do
# Created on: Mon May 08 14:52:21 +0800 2023
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vsim -voptargs="+acc" -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.tb_serializer xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {tb_serializer_wave.do}

view wave
view structure
view signals

do {tb_serializer.udo}

run 1000ns
