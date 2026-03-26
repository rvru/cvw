TARGET = forwarding_probe

RISCV_PREFIX ?= riscv64-unknown-elf
CC = $(RISCV_PREFIX)-gcc
OBJDUMP = $(RISCV_PREFIX)-objdump
SIZE = $(RISCV_PREFIX)-size

COMMON_DIR = ../common
ARCH = rv32gc
ABI = ilp32

CFLAGS = -O0 -gdwarf-2 -march=$(ARCH) -mabi=$(ABI) -mcmodel=medany -Wall \
	-nostdlib -static -fno-tree-loop-distribute-patterns
LDFLAGS = -T$(COMMON_DIR)/test.ld -I$(COMMON_DIR)

SRCS = forwarding_probe_main.c forwarding_probe.S $(COMMON_DIR)/crt.S $(COMMON_DIR)/syscalls.c
ELF = $(TARGET).elf

.PHONY: all dump clean

all: $(ELF)

$(ELF): $(SRCS) Makefile
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRCS) -lgcc -o $@
	$(SIZE) $@

dump: $(ELF)
	$(OBJDUMP) -S -D $(ELF) > $(ELF).objdump

clean:
	rm -f $(ELF) $(ELF).objdump
