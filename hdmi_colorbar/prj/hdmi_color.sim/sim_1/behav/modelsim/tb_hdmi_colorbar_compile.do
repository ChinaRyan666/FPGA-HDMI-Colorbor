######################################################################
#
# File name : tb_hdmi_colorbar_compile.do
# Created on: Tue Jun 06 15:50:14 +0800 2023
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog  -incr -sv -work xpm  "+incdir+../../../../hdmi_color.gen/sources_1/ip/clk_wiz_0" \
"D:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom  -93 -work xpm  \
"D:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog  -incr -work xil_defaultlib  "+incdir+../../../../hdmi_color.gen/sources_1/ip/clk_wiz_0" \
"../../../../hdmi_color.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../hdmi_color.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \
"../../../../../rtl/asyn_rst_syn.v" \
"../../../../../rtl/dvi_encoder.v" \
"../../../../../rtl/dvi_transmitter_top.v" \
"../../../../../rtl/hdmi_colorbar_top.v" \
"../../../../../rtl/serializer_10_to_1.v" \
"../../../../../rtl/video_display.v" \
"../../../../../rtl/video_driver.v" \
"../../../../../sim/tb_hdmi_colorbar.v" \

# compile glbl module
vlog -work xil_defaultlib "glbl.v"

quit -force
