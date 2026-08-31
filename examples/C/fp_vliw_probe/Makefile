TARGET = fp_vliw_probe

RISCV_PREFIX ?= riscv64-unknown-elf
CC = $(RISCV_PREFIX)-gcc
OBJDUMP = $(RISCV_PREFIX)-objdump
SIZE = $(RISCV_PREFIX)-size

COMMON_DIR = ../common
ARCH = rv32imafc_zicsr
ABI = ilp32

CFLAGS = -O0 -gdwarf-2 -march=$(ARCH) -mabi=$(ABI) -mcmodel=medany -Wall \
	-nostdlib -static -std=gnu17 -ffunction-sections -fdata-sections \
	-fno-tree-loop-distribute-patterns
CPPFLAGS =
ifneq ($(PROBE_ONLY),)
CPPFLAGS += -DPROBE_ONLY=$(PROBE_ONLY)
endif
LDFLAGS = -T$(COMMON_DIR)/test.ld -Wl,-gc-sections

SRCS = fp_vliw_probe_main.c fp_vliw_probe.S $(COMMON_DIR)/crt.S $(COMMON_DIR)/syscalls.c
ELF = $(TARGET).elf

.PHONY: all dump clean

all: $(ELF)

$(ELF): $(SRCS) Makefile
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(SRCS) -lgcc -o $@
	$(SIZE) $@

dump: $(ELF)
	$(OBJDUMP) -S -D $(ELF) > $(ELF).objdump

clean:
	rm -f $(ELF) $(ELF).objdump
