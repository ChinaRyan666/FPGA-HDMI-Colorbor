######################################################################
#
# File name : hdmi_colorbar_top_simulate.do
# Created on: Tue Apr 25 16:08:08 +0800 2023
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vsim -voptargs="+acc" -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.hdmi_colorbar_top xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {hdmi_colorbar_top_wave.do}

view wave
view structure
view signals

do {hdmi_colorbar_top.udo}

run 1000ns
