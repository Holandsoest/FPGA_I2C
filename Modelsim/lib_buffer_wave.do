onerror {resume}
quietly WaveActivateNextPane {} 0



add wave -noupdate -divider "Control" -height 5
add wave -noupdate -radix unsigned AXI_buffer_tb/clock_generator/G_clock_frequency
add wave -noupdate AXI_buffer_tb/reset
add wave -noupdate AXI_buffer_tb/clk

add wave -noupdate -divider "Buffers I" -height 5
add wave -noupdate AXI_buffer_tb/data_in_ready_1buf
add wave -noupdate AXI_buffer_tb/data_in_ready_9buf
add wave -noupdate AXI_buffer_tb/data_in_valid
add wave -noupdate -radix hex AXI_buffer_tb/data_in

add wave -noupdate -divider "Buffers O" -height 5
add wave -noupdate AXI_buffer_tb/data_out_ready
add wave -noupdate AXI_buffer_tb/data_out_valid_1buf
add wave -noupdate -radix hex AXI_buffer_tb/data_out_1buf
add wave -noupdate AXI_buffer_tb/data_out_valid_9buf
add wave -noupdate -radix hex AXI_buffer_tb/data_out_9buf


add wave -noupdate -divider "Buffers debug" -height 10
add wave -noupdate -group buffer_1 -divider "Control" -height 5
add wave -noupdate -radix unsigned -group buffer_1 /AXI_buffer_tb/one_buffer/GC_data_width
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/I_reset
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/I_clk

add wave -noupdate -group buffer_1 -divider "Buffer I" -height 5
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/O_data_in_ready
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/I_data_in_valid
add wave -noupdate -radix hex -group buffer_1 /AXI_buffer_tb/one_buffer/I_data_in

add wave -noupdate -group buffer_1 -divider "Buffer O" -height 5
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/I_data_out_ready
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/O_data_out_valid
add wave -noupdate -radix hex -group buffer_1 /AXI_buffer_tb/one_buffer/O_data_out

add wave -noupdate -group buffer_1 -divider "Buffer Signals" -height 5
add wave -noupdate -group buffer_1 /AXI_buffer_tb/one_buffer/S_ihasdata



TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
configure wave 
wave zoom range 0 {230 ns}
update
