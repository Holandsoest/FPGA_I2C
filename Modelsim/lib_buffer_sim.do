# The project folder location
set PROJECT_DIR C:/Users/Wolf/Dropbox/Projecten/FPGA_I2C


# Compilation options
set USER_DEFINED_VHDL_COMPILE_OPTIONS -2008


# Create the libraries that we need to use
vlib work 
vlib lib_tb
vlib lib_buffer 


# Compile the files
# DUT C
vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $PROJECT_DIR/VHDL/lib_buffer/AXI_buffer.vhd     -work lib_buffer
# IP compilation
# TB compilation
vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $PROJECT_DIR/VHDL/lib_tb/clock_generator.vhd    -work lib_tb
vcom $USER_DEFINED_VHDL_COMPILE_OPTIONS $PROJECT_DIR/VHDL/lib_buffer/AXI_buffer_tb.vhd  -work lib_buffer


# Set the top-level simulation or testbench module/entity name, and call it with the options required.
set TOP_LEVEL_NAME lib_buffer.AXI_buffer_tb
eval vsim $TOP_LEVEL_NAME


# Run the simulation.
do lib_buffer_wave.do
run -a


# Report success to the shell.
#exit -code 0
