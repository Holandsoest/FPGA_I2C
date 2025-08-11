onerror {resume}
quietly WaveActivateNextPane {} 0



add wave -noupdate                 -group Shared -divider "Control" -height 5
add wave -noupdate -radix unsigned -group Shared i2c_tb/C_clk_frequency
add wave -noupdate -radix time     -group Shared i2c_tb/C_clk_period
add wave -noupdate -radix unsigned -group Shared i2c_tb/C_i2c_clk_frequency
add wave -noupdate                 -group Shared i2c_tb/reset
add wave -noupdate                 -group Shared i2c_tb/clk

add wave -noupdate                 -group Shared -divider "I2C" -height 5
add wave -noupdate                 -group Shared i2c_tb/I2C_SDA
add wave -noupdate                 -group Shared i2c_tb/I2C_SCL



add wave -noupdate                 -group Master1 -divider "In  side (to axi bus)" -height 5
add wave -noupdate                 -group Master1 -color "yellow" i2c_tb/M1/O_data_in_ready
add wave -noupdate                 -group Master1 -color "blue"   i2c_tb/M1/I_data_in_valid
add wave -noupdate -radix hex      -group Master1 -color "blue"   i2c_tb/M1/I_data_in
#add wave -noupdate                 -group Master1 -color "blue"   i2c_tb/M1/I_data_out_ready
#add wave -noupdate                 -group Master1 -color "yellow" i2c_tb/M1/O_data_out_valid
#add wave -noupdate -radix hex      -group Master1 -color "yellow" i2c_tb/M1/O_data_out

add wave -noupdate                 -group Master1 -divider "Out side (to i2c bus)" -height 5
add wave -noupdate -radix hex      -group Master1 -color "yellow" i2c_tb/M1/O_I2C_SDA
add wave -noupdate -radix hex      -group Master1 -color "yellow" i2c_tb/M1/O_I2C_SCL
#add wave -noupdate -radix hex      -group Master1 -color "blue"   i2c_tb/M1/I_I2C_SDA
#add wave -noupdate -radix hex      -group Master1 -color "blue"   i2c_tb/M1/I_I2C_SCL

add wave -noupdate                 -group Master1 -divider "Signals" -height 5
add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_i2c_clock_counter
add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_i2c_data_counter_this
add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_i2c_data_counter_next
add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_start_ready
add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_start_done
add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_start_timer
add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_started
add wave -noupdate -radix hex      -group Master1 -color "purple" i2c_tb/M1/S_data_in
add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_data_in_hasdata
#add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_data_out
#add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_data_out_hasdata
#add wave -noupdate -radix hex      -group Master1 -color "purple" i2c_tb/M1/S_latest_device_address





TreeUpdate [SetDefaultTree]
wave cursor add -time 105ns -name "Start" -lock 1
quietly wave cursor active 1
configure wave -namecolwidth 185
configure wave -valuecolwidth 65
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
wave zoom range 105 {650000 ns}
update
