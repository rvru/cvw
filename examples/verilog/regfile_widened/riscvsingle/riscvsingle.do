# regfile.do
# Compile and simulate regfile_widened + regfile_tb

# Clean work library
vlib work
vmap work work

# Compile DUT and testbench
vlog regfile_widened.sv
vlog regfile_tb.sv

# Optimize
vopt +acc work.regfile_tb -o regfile_opt

# Simulate
vsim regfile_opt

# -----------------------------
# Add waveforms
# -----------------------------
add wave -divider "Clock & Reset"
add wave /regfile_tb/clk
add wave /regfile_tb/reset

add wave -divider "Write Ports"
add wave /regfile_tb/we3
add wave /regfile_tb/we6
add wave /regfile_tb/we9
add wave /regfile_tb/we12
add wave /regfile_tb/a3
add wave /regfile_tb/a6
add wave /regfile_tb/a9
add wave /regfile_tb/a12
add wave /regfile_tb/wd3
add wave /regfile_tb/wd6
add wave /regfile_tb/wd9
add wave /regfile_tb/wd12

add wave -divider "Read Ports"
add wave /regfile_tb/a1
add wave /regfile_tb/a2
add wave /regfile_tb/a4
add wave /regfile_tb/a5
add wave /regfile_tb/a7
add wave /regfile_tb/a8
add wave /regfile_tb/rd1
add wave /regfile_tb/rd2
add wave /regfile_tb/rd4
add wave /regfile_tb/rd5
add wave /regfile_tb/rd7
add wave /regfile_tb/rd8

add wave -divider "Internal Register File"
add wave -radix decimal /regfile_tb/dut/rf*

# Run simulation
run 500

# Open wave viewer
view wave
