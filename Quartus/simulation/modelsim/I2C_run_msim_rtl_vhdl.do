transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlib lib_buffer
vmap lib_buffer lib_buffer
vcom -2008 -work lib_buffer {C:/Users/Wolf/Dropbox/Projecten/FPGA_I2C/VHDL/lib_buffer/AXI_buffer.vhd}

