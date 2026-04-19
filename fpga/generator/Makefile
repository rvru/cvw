dst := IP

all: ArtyA7

.PHONY: ArtyA7 vcu118 vcu108 genesys2 fpga32 starbug starbug-code

ArtyA7: export XILINX_PART := xc7a100tcsg324-1
ArtyA7: export XILINX_BOARD := digilentinc.com:arty-a7-100:part0:1.1
ArtyA7: export board := ArtyA7
ArtyA7: export version := ArtyA7
ArtyA7: export SYSTEMCLOCK := 20000000
ArtyA7: export MAXSDCCLOCK  :=  5000000
ArtyA7: FPGA_Arty

starbug: export XILINX_PART := xcvu095-ffva2104-2-e
starbug: export XILINX_BOARD := xilinx.com:vcu108:part0:1.7
starbug: export board := vcu108
starbug: export version := starbug
starbug: export SYSTEMCLOCK := 50000000
starbug: export MAXSDCCLOCK  := 12500000
starbug: FPGA_Starbug_VCU

fpga32: export XILINX_PART := xc7a100tcsg324-1
fpga32: export XILINX_BOARD := digilentinc.com:arty-a7-100:part0:1.1
fpga32: export board := ArtyA7
fpga32: export version := 32
fpga32: export SYSTEMCLOCK := 20000000
fpga32: export MAXSDCCLOCK  :=  5000000
fpga32: FPGA_Arty_32

vcu118: export XILINX_PART := xcvu9p-flga2104-2L-e
vcu118: export XILINX_BOARD := xilinx.com:vcu118:part0:2.4
vcu118: export board := vcu118
vcu118: export version := vcu118
vcu118: export SYSTEMCLOCK := 71000000
vcu118: export MAXSDCCLOCK  :=  1000000
vcu118: FPGA_VCU

vcu108: export XILINX_PART := xcvu095-ffva2104-2-e
vcu108: export XILINX_BOARD := xilinx.com:vcu108:part0:1.7
vcu108: export board := vcu108
vcu108: export version := vcu108
vcu108: export SYSTEMCLOCK := 50000000
vcu108: export MAXSDCCLOCK  := 12500000
vcu108: FPGA_VCU

genesys2: export XILINX_PART := xc7k325tffg900-2
genesys2: export XILINX_BOARD := digilentinc.com:genesys2:part0:1.1
genesys2: export board := genesys2
genesys2: export version := genesys2
genesys2: export SYSTEMCLOCK := 40000000
genesys2: export MAXSDCCLOCK  := 10000000
genesys2: FPGA_GENESYS2



check_code:
ifndef CODE
	$(error CODE is not set. Usage: make {TARGET} CODE=your_value (CODE should be a folder located in ../loadable_programs/))
else
	@echo "Generating using ROM code from ../loadable_programs/$(CODE)..."
endif

# variables computed from config
EXT_MEM_BASE = $(shell grep 'EXT_MEM_BASE' ../../config/deriv/fpga$(version)/config.vh | sed 's/.*=.*h\([[:alnum:]]*\);/0x\1/g')

EXT_MEM_RANGE = $(shell grep 'EXT_MEM_RANGE' ../../config/deriv/fpga$(version)/config.vh | sed 's/.*=.*h\([[:alnum:]]*\);/\1/g' | sed 's/\(.*\)/base=16;\1+1/g' | bc | sed 's/\(.*\)/0x\1/g')


.PHONY: FPGA_Arty FPGA_VCU FPGA_Arty_32
FPGA_Arty: PreProcessFiles IP_Arty zsbl
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log
FPGA_VCU: PreProcessFiles IP_VCU code
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log
FPGA_Arty_32: PreProcessFiles IP_Arty code
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log
FPGA_GENESYS2: PreProcessFiles IP_GENESYS2 zsbl
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log
FPGA_Starbug_VCU: PreProcessFiles IP_VCU code
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log

# Generate IP Blocks
.PHONY: IP_Arty IP_VCU
IP_VCU: $(dst)/sysrst.log \
	MEM_VCU \
	$(dst)/clkconverter.log \
	$(dst)/ahbaxibridge.log
IP_Arty: $(dst)/sysrst.log \
	MEM_Arty \
	$(dst)/mmcm.log \
	$(dst)/clkconverter.log \
	$(dst)/ahbaxibridge.log

IP_GENESYS2: $(dst)/sysrst.log \
	MEM_GENESYS2 \
	$(dst)/mmcm-genesys2.log \
	$(dst)/clkconverter.log \
	$(dst)/ahbaxibridge.log

# Generate Memory IP Blocks
.PHONY: MEM_VCU MEM_Arty
MEM_VCU:
	$(MAKE) $(dst)/ddr4-$(board).log
MEM_Arty:
	$(MAKE) $(dst)/ddr3-$(board).log

MEM_GENESYS2:
	$(MAKE) $(dst)/ddr3-$(board).log

# Copy files and make necessary modifications
.PHONY: PreProcessFiles
PreProcessFiles:
	$(MAKE) -C ../../sim deriv
	rm -rf ../src/CopiedFiles_do_not_add_to_repo/
	cp -r ../../src/ ../src/CopiedFiles_do_not_add_to_repo/
	cp -r ../../addins/verilog-ethernet/*/*.sv ../src/CopiedFiles_do_not_add_to_repo/rvvi
	cp -r ../../addins/verilog-ethernet/*/*/*/*.sv ../src/CopiedFiles_do_not_add_to_repo/rvvi
	mkdir ../src/CopiedFiles_do_not_add_to_repo/config/
	cp ../../config/deriv/fpga$(version)/config.vh ../src/CopiedFiles_do_not_add_to_repo/config/
	./insert_debug_comment.sh
	# This line allows the Bootloader to be loaded in a Block RAM on the FPGA
	sed -i "s/bit \[DATA_WIDTH-1:0\].*ROM.*/(\* rom_style=\"block\" \*) &/g" ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv
	sed -i 's/$$WALLY/\.\.\/\.\.\//g' ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv
	sed -i 's/$$WALLY/\.\.\/\.\.\//g' ../src/CopiedFiles_do_not_add_to_repo/generic/mem/ram1p1rwbe.sv

# build the Zero stage boot loader (ZSBL)
.PHONY: zsbl
zsbl:
	$(MAKE) -C ../zsbl clean
	SYSTEMCLOCK=$(SYSTEMCLOCK) EXT_MEM_BASE=$(EXT_MEM_BASE) EXT_MEM_RANGE=$(EXT_MEM_RANGE) $(MAKE) -C ../zsbl 


# for my testing, replace zsbl with my code
.PHONY: code check_code
code: check_code
	$(MAKE) -C ../ROM_code clean
	SYSTEMCLOCK=$(SYSTEMCLOCK) EXT_MEM_BASE=$(EXT_MEM_BASE) EXT_MEM_RANGE=$(EXT_MEM_RANGE) romCode=$(CODE) $(MAKE) -C ../ROM_code


# Generate Individual IP Blocks
$(dst)/%.log: %.tcl
	mkdir -p IP
	cd IP;\
	vivado -mode batch -source ../$*.tcl | tee $*.log

# Clean
.PHONY: cleanIP cleanLogs cleanFPGA cleanAll
cleanIP:
	rm -rf IP
cleanLogs:
	rm -rf  *.jou *.log
cleanFPGA:
	rm -rf WallyFPGA.* reports sim .Xil
cleanAll: cleanIP cleanLogs cleanFPGA

# Aliases
.PHONY: arty artya7 VCU118 VCU108
arty artya7: ArtyA7
VCU118: vcu118
VCU108: vcu108

.PHONY: vcu108-code
vcu108-code: vcu108

STARBUG_BENCH_DIR ?= ../../examples/C/starbug_benchmarks/$(CODE)

.PHONY: starbug-code
starbug-code: check_code
	$(MAKE) -C $(STARBUG_BENCH_DIR) clean
	$(MAKE) -C $(STARBUG_BENCH_DIR) vliw-wally
	$(MAKE) starbug CODE=$(CODE)
