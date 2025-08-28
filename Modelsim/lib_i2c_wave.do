onerror {resume}
quietly WaveActivateNextPane {} 0

# verbosity [0..1] to either log less or more objects
set verbose 0

# Shared

if {verbose == 1}{  add wave -noupdate                 -group Shared -divider "Control" -height 5   }
if {verbose == 1}{  add wave -noupdate -radix unsigned -group Shared i2c_tb/C_clk_frequency         }
if {verbose == 1}{  add wave -noupdate -radix time     -group Shared i2c_tb/C_clk_period            }
if {verbose == 1}{  add wave -noupdate -radix unsigned -group Shared i2c_tb/C_i2c_clk_frequency     }
if {verbose == 1}{  add wave -noupdate -radix time     -group Shared i2c_tb/C_i2c_clk_period        }
                    add wave -noupdate                 -group Shared i2c_tb/reset
                    add wave -noupdate                 -group Shared i2c_tb/clk

                    add wave -noupdate                 -group Shared -divider "I2C" -height 5
                    add wave -noupdate                 -group Shared i2c_tb/I2C_SDA
                    add wave -noupdate                 -group Shared i2c_tb/I2C_SCL

# MASTER 1

                    add wave -noupdate                 -group Master1 -divider "From AXI-buffers" -height 5
if {verbose == 1}{  add wave -noupdate                 -group Master1 -color "yellow" i2c_tb/M1/O_data_in_ready         }
if {verbose == 1}{  add wave -noupdate                 -group Master1 -color "blue"   i2c_tb/M1/I_data_in_valid         }
if {verbose == 1}{  add wave -noupdate -radix hex      -group Master1 -color "blue"   i2c_tb/M1/I_data_in               }
                    add wave -noupdate -radix hex      -group Master1 -color "purple" i2c_tb/M1/S_data_in
                    add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_data_in_hasdata
                    add wave -noupdate                 -group Master1 -divider "To AXI-buffers" -height 5
                    add wave -noupdate                 -group Master1 -color "blue"   i2c_tb/M1/I_data_out_ready
                    add wave -noupdate                 -group Master1 -color "yellow" i2c_tb/M1/O_data_out_valid
                    add wave -noupdate -radix hex      -group Master1 -color "yellow" i2c_tb/M1/O_data_out
                    add wave -noupdate -radix hex      -group Master1 -color "purple" i2c_tb/M1/S_data_out

                    add wave -noupdate                 -group Master1 -divider "I2C" -height 5
                    add wave -noupdate -radix hex      -group Master1 -color "yellow" i2c_tb/M1/O_I2C_SDA
                    add wave -noupdate -radix hex      -group Master1 -color "yellow" i2c_tb/M1/O_I2C_SCL
                    add wave -noupdate -radix hex      -group Master1 -color "blue"   i2c_tb/M1/I_I2C_SDA
                    add wave -noupdate -radix hex      -group Master1 -color "blue"   i2c_tb/M1/I_I2C_SCL

                    add wave -noupdate                 -group Master1 -divider "Other signals" -height 5
                    add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_i2c_clock_counter
                    add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_i2c_data_counter_this
if {verbose == 1}{  add wave -noupdate -radix unsigned -group Master1 -color "gray" i2c_tb/M1/S_i2c_data_counter_next   }
                    add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_i2c_NACK_retry_counter
if {verbose == 1}{  add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_start_ready           }
if {verbose == 1}{  add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_start_done            }
if {verbose == 1}{  add wave -noupdate -radix unsigned -group Master1 -color "purple" i2c_tb/M1/S_start_timer           }
if {verbose == 1}{  add wave -noupdate                 -group Master1 -color "purple" i2c_tb/M1/S_started               }

# SLAVE 1

                    add wave -noupdate                 -group Slave1 -color "yellow" i2c_tb/S1/O_I2C_SDA
                    add wave -noupdate                 -group Slave1 -divider "To AXI-registers" -height 5
                    add wave -noupdate                 -group Slave1 -color "blue"   i2c_tb/S1/I_data_out_ready
                    add wave -noupdate                 -group Slave1 -color "yellow" i2c_tb/S1/O_data_out_valid
                    add wave -noupdate -radix hex      -group Slave1 -color "yellow" i2c_tb/S1/O_data_out
                    add wave -noupdate                 -group Slave1 -divider "From AXI-registers" -height 5
                    add wave -noupdate                 -group Slave1 -color "yellow" i2c_tb/S1/O_data_response_ready
                    add wave -noupdate                 -group Slave1 -color "blue"   i2c_tb/S1/I_data_response_valid
                    add wave -noupdate -radix hex      -group Slave1 -color "blue"   i2c_tb/S1/I_data_response
                    add wave -noupdate                 -group Slave1 -divider "Internal signals." -height 5
                    add wave -noupdate -radix hex      -group Slave1 -color "purple" i2c_tb/S1/S_i2c_state
                    add wave -noupdate -radix hex      -group Slave1 -color "purple" i2c_tb/S1/S_i2c_incoming_data
if {verbose == 1}{  add wave -noupdate -radix hex      -group Slave1 -color "gray"   i2c_tb/S1/S_i2c_incoming_data_flip     }
                    add wave -noupdate -radix hex      -group Slave1 -color "purple" i2c_tb/S1/S_i2c_incoming_data_counter
                    add wave -noupdate -radix hex      -group Slave1 -color "purple" i2c_tb/S1/S_i2c_inactivity_counter
                    add wave -noupdate                 -group Slave1 -color "purple" i2c_tb/S1/S_i2c_sda_address_match
                    add wave -noupdate                 -group Slave1 -color "purple" i2c_tb/S1/S_i2c_sda_data_match
                    add wave -noupdate                 -group Slave1 -color "purple" i2c_tb/S1/S_i2c_sda_response
                    add wave -noupdate                 -group Slave1 -color "purple" i2c_tb/S1/RS1_responses
                    add wave -noupdate                 -group Slave1 -color "purple" i2c_tb/S1/S_responding

# End of waves
# Configure layout

TreeUpdate [SetDefaultTree]
wave cursor add -time 171425ns -name "Start" -lock 1
wave cursor add -time 216425ns -name "End"   -lock 1
quietly wave cursor active 1
configure wave -namecolwidth 185
configure wave -valuecolwidth 55
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
update

# End of file, return to the *sim.do
