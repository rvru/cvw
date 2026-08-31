# -------------------------------------------------------------------
# Toolchain and Paths
# -------------------------------------------------------------------
RISCV_PREFIX         ?= riscv64-unknown-elf
RISCV_GCC_FROM_PATH  := $(shell command -v $(RISCV_PREFIX)-gcc 2>/dev/null)
GCC_TOOLCHAIN        ?= $(if $(RISCV_GCC_FROM_PATH),$(patsubst %/bin/$(RISCV_PREFIX)-gcc,%,$(RISCV_GCC_FROM_PATH)),/opt/homebrew)

CC         = $(GCC_TOOLCHAIN)/bin/$(RISCV_PREFIX)-gcc
WALLY_CC   = $(if $(RISCV_GCC_FROM_PATH),$(RISCV_GCC_FROM_PATH),$(GCC_TOOLCHAIN)/bin/$(RISCV_PREFIX)-gcc)
OBJDUMP    = $(GCC_TOOLCHAIN)/bin/$(RISCV_PREFIX)-objdump
SIZE       = $(GCC_TOOLCHAIN)/bin/$(RISCV_PREFIX)-size
RISCV_SIZE_FROM_PATH := $(shell command -v $(RISCV_PREFIX)-size 2>/dev/null)
WALLY_SIZE = $(if $(RISCV_SIZE_FROM_PATH),$(RISCV_SIZE_FROM_PATH),$(GCC_TOOLCHAIN)/bin/$(RISCV_PREFIX)-size)

STARBUG_LLVM_BUILD_RS ?= /rs23/lnm7/open_hw/starbug-llvm/llvm-project/build-starbug-make
STARBUG_LLVM_BUILD_WS ?= $(abspath ../../../../../starbug-llvm/llvm-project/build-starbug-make)
STARBUG_LLVM_BUILD    ?= $(if $(wildcard $(STARBUG_LLVM_BUILD_RS)/bin/clang),$(STARBUG_LLVM_BUILD_RS),$(STARBUG_LLVM_BUILD_WS))
STARBUG_CC           ?= $(STARBUG_LLVM_BUILD)/bin/clang
STARBUG_SIZE         ?= $(STARBUG_LLVM_BUILD)/bin/llvm-size
STARBUG_GCC          ?= $(if $(RISCV_GCC_FROM_PATH),$(RISCV_GCC_FROM_PATH),$(GCC_TOOLCHAIN)/bin/$(RISCV_PREFIX)-gcc)
STARBUG_SYSROOT      ?= $(shell $(STARBUG_GCC) -print-sysroot)
STARBUG_GCC_INC      ?= $(shell $(STARBUG_GCC) -print-file-name=include)
STARBUG_LINKER       ?= $(STARBUG_GCC)

BENCHMARK ?= $(notdir $(CURDIR))

RISCV_COMMON_DIR   := ../../common
EMBENCH_COMMON_DIR := ../common
CMSIS_LIB_DIR      := $(EMBENCH_COMMON_DIR)/lib
CMSIS_INC_DIR      := $(CMSIS_LIB_DIR)/include
VLIW_ASM_DIR       := $(EMBENCH_COMMON_DIR)/vliw_asm
VLIW_FILTERING_ASM_DIR := $(VLIW_ASM_DIR)/filtering
VLIW_BASIC_ASM_DIR := $(VLIW_ASM_DIR)/basic
VLIW_COMPLEX_ASM_DIR := $(VLIW_ASM_DIR)/complex
VLIW_TRANSFORM_ASM_DIR := $(VLIW_ASM_DIR)/transform
VLIW_ASM_SANITIZER := $(EMBENCH_COMMON_DIR)/sanitize_vliw_asm.py

CMSIS_SRC_DIRS := \
	$(CMSIS_LIB_DIR)/src/BasicMathFunctions \
	$(CMSIS_LIB_DIR)/src/CommonTables \
	$(CMSIS_LIB_DIR)/src/ComplexMathFunctions \
	$(CMSIS_LIB_DIR)/src/FilteringFunctions \
	$(CMSIS_LIB_DIR)/src/TransformFunctions

VPATH := . $(EMBENCH_COMMON_DIR) $(RISCV_COMMON_DIR) $(CMSIS_SRC_DIRS)

# -------------------------------------------------------------------
# ISA / ABI
# -------------------------------------------------------------------
ARCH             ?= rv32imafc_zicsr
ABI              ?= ilp32
STARBUG_TARGET   ?= riscv32-unknown-elf
STARBUG_CPU      ?= starbug-vliw
STARBUG_ARCH     ?= $(ARCH)
STARBUG_GCC_ARCH ?= $(ARCH)
STARBUG_ABI      ?= $(ABI)

# -------------------------------------------------------------------
# Common Flags
# -------------------------------------------------------------------
override COMMON_OPT := -O3
COMMON_WARN     ?= -Wall -Wno-unused-function -Wno-format
BENCH_CPPFLAGS  ?=
BENCH_FAST_MATH ?= -ffast-math

COMMON_INCLUDES := -I. -I$(EMBENCH_COMMON_DIR) -I$(CMSIS_INC_DIR) -I$(RISCV_COMMON_DIR)
COMMON_CFLAGS   := $(COMMON_OPT) -gdwarf-2 -mcmodel=medany -nostdlib -static \
	-std=gnu17 $(BENCH_FAST_MATH) -fno-math-errno \
	-ffunction-sections -fdata-sections $(COMMON_WARN) $(COMMON_INCLUDES) $(BENCH_CPPFLAGS)
GCC_ONLY_CFLAGS := -fno-tree-loop-distribute-patterns

WALLY_CFLAGS    := $(COMMON_CFLAGS) $(GCC_ONLY_CFLAGS) -march=$(ARCH) -mabi=$(ABI)
WALLY_LINKFLAGS := -T$(RISCV_COMMON_DIR)/test.ld -Wl,-gc-sections
WALLY_LIBS      ?= -lm -lgcc

STARBUG_MLLVM ?= \
	-mllvm -starbug-vliw-force-unroll=false \
	-mllvm -starbug-vliw-enable-machine-pipeliner=false \
	-mllvm -starbug-vliw-emit-single-hints=false

STARBUG_EXTRA ?= $(EXTRA)
STARBUG_BACKEND_FLAGS := $(STARBUG_MLLVM) $(STARBUG_EXTRA)
STARBUG_CFLAGS := $(COMMON_CFLAGS) --target=$(STARBUG_TARGET) -march=$(STARBUG_ARCH) \
	-mcpu=$(STARBUG_CPU) -mabi=$(STARBUG_ABI) \
	-isystem $(STARBUG_SYSROOT)/include -isystem $(STARBUG_GCC_INC)
STARBUG_GCC_CFLAGS := $(COMMON_CFLAGS) $(GCC_ONLY_CFLAGS) -march=$(STARBUG_GCC_ARCH) -mabi=$(STARBUG_ABI)
STARBUG_LINKFLAGS := -march=$(STARBUG_GCC_ARCH) -mabi=$(STARBUG_ABI) -mcmodel=medany \
	-nostdlib -static -T$(RISCV_COMMON_DIR)/test.ld -Wl,-gc-sections \
	--sysroot=$(STARBUG_SYSROOT)
STARBUG_LIBS ?= -lm -lgcc

# -------------------------------------------------------------------
# Sources
# -------------------------------------------------------------------
BENCH_C_SRCS   := $(sort $(wildcard *.c))
SUPPORT_C_SRCS := $(EMBENCH_COMMON_DIR)/main.c $(EMBENCH_COMMON_DIR)/snr.c $(EMBENCH_COMMON_DIR)/boardsupport.c $(EMBENCH_COMMON_DIR)/errno_compat.c
EMPTY_C_SRCS   := $(EMBENCH_COMMON_DIR)/main.c $(EMBENCH_COMMON_DIR)/empty_test_main.c $(EMBENCH_COMMON_DIR)/boardsupport.c $(EMBENCH_COMMON_DIR)/errno_compat.c
CMSIS_C_SRCS   := $(sort $(foreach dir,$(CMSIS_SRC_DIRS),$(wildcard $(dir)/*.c)))

STARBUG_BUILD_DIR   := .build-starbug
STARBUG_BENCH_OBJS  := $(addprefix $(STARBUG_BUILD_DIR)/,$(addsuffix .o,$(notdir $(BENCH_C_SRCS:.c=) $(SUPPORT_C_SRCS:.c=) $(CMSIS_C_SRCS:.c=))))
STARBUG_EMPTY_OBJS  := $(addprefix $(STARBUG_BUILD_DIR)/,$(addsuffix .o,$(notdir $(EMPTY_C_SRCS:.c=))))
STARBUG_CRT_OBJ     := $(STARBUG_BUILD_DIR)/crt.o
STARBUG_SYSCALLS_OBJ := $(STARBUG_BUILD_DIR)/syscalls.o

SCALAR_WALLY_ELF := $(BENCHMARK)_scalar_wally.elf
EMPTY_WALLY_ELF  := $(BENCHMARK)_empty_wally.elf
VLIW_WALLY_ELF   := $(BENCHMARK)_vliw_wally.elf
STARBUG_ELF      := $(BENCHMARK)_starbug.elf
EMPTY_STARBUG_ELF := $(BENCHMARK)_empty_starbug.elf

VLIW_ASM_SRCS       ?=
VLIW_OVERRIDE_C_SRCS ?=
VLIW_CMSIS_C_SRCS   := $(filter-out $(VLIW_OVERRIDE_C_SRCS),$(CMSIS_C_SRCS))

GCC_SEED_ASM_FLAGS := $(COMMON_OPT) -march=$(ARCH) -mabi=$(ABI) -mcmodel=medany \
	-std=gnu17 $(BENCH_FAST_MATH) -fno-math-errno $(GCC_ONLY_CFLAGS) \
	-fverbose-asm -funroll-loops -funroll-all-loops -fpeel-loops -ftracer \
	-frename-registers -fweb -fomit-frame-pointer \
	-fno-asynchronous-unwind-tables -fno-unwind-tables -fno-exceptions \
	-fno-stack-protector $(COMMON_WARN) $(COMMON_INCLUDES) $(BENCH_CPPFLAGS)

# -------------------------------------------------------------------
# Phony Targets
# -------------------------------------------------------------------
BUNDLE_CHECK ?= /rs23/lnm7/open_hw/starbug-llvm/tools/starbug_bundle_check.py

.PHONY: all scalar-wally empty-wally vliw-wally starbug-compile empty-starbug seed-vliw-asm dump clean verify verify-vliw verify-starbug

all: scalar-wally empty-wally starbug-compile empty-starbug

scalar-wally: $(SCALAR_WALLY_ELF)

empty-wally: $(EMPTY_WALLY_ELF)

vliw-wally: $(VLIW_WALLY_ELF)

starbug-compile: $(STARBUG_ELF)

empty-starbug: $(EMPTY_STARBUG_ELF)

seed-vliw-asm:

# -------------------------------------------------------------------
# Wally / GCC builds
# -------------------------------------------------------------------
$(SCALAR_WALLY_ELF): $(BENCH_C_SRCS) $(SUPPORT_C_SRCS) $(CMSIS_C_SRCS) $(RISCV_COMMON_DIR)/crt.S $(RISCV_COMMON_DIR)/syscalls.c
	$(WALLY_CC) $(WALLY_CFLAGS) $(WALLY_LINKFLAGS) \
		$(RISCV_COMMON_DIR)/crt.S $(BENCH_C_SRCS) $(SUPPORT_C_SRCS) $(CMSIS_C_SRCS) $(RISCV_COMMON_DIR)/syscalls.c \
		$(WALLY_LIBS) -o $@
	$(WALLY_SIZE) $@

$(EMPTY_WALLY_ELF): $(EMPTY_C_SRCS) $(RISCV_COMMON_DIR)/crt.S $(RISCV_COMMON_DIR)/syscalls.c
	$(WALLY_CC) $(WALLY_CFLAGS) $(WALLY_LINKFLAGS) \
		$(RISCV_COMMON_DIR)/crt.S $(EMPTY_C_SRCS) $(RISCV_COMMON_DIR)/syscalls.c \
		$(WALLY_LIBS) -o $@
	$(WALLY_SIZE) $@

$(VLIW_WALLY_ELF): $(BENCH_C_SRCS) $(SUPPORT_C_SRCS) $(VLIW_CMSIS_C_SRCS) $(VLIW_ASM_SRCS) $(RISCV_COMMON_DIR)/crt.S $(RISCV_COMMON_DIR)/syscalls.c
	$(WALLY_CC) $(WALLY_CFLAGS) $(WALLY_LINKFLAGS) \
		$(RISCV_COMMON_DIR)/crt.S $(BENCH_C_SRCS) $(SUPPORT_C_SRCS) $(VLIW_CMSIS_C_SRCS) -x assembler $(VLIW_ASM_SRCS) -x none $(RISCV_COMMON_DIR)/syscalls.c \
		$(WALLY_LIBS) -o $@
	$(WALLY_SIZE) $@

# -------------------------------------------------------------------
# Starbug / Clang builds
# -------------------------------------------------------------------
$(STARBUG_BUILD_DIR):
	mkdir -p $@

$(STARBUG_BUILD_DIR)/%.o: %.c | $(STARBUG_BUILD_DIR)
	$(STARBUG_CC) $(STARBUG_CFLAGS) $(STARBUG_BACKEND_FLAGS) -c $< -o $@

$(STARBUG_CRT_OBJ): $(RISCV_COMMON_DIR)/crt.S | $(STARBUG_BUILD_DIR)
	$(STARBUG_CC) $(STARBUG_CFLAGS) $(STARBUG_BACKEND_FLAGS) -c $< -o $@

$(STARBUG_SYSCALLS_OBJ): $(RISCV_COMMON_DIR)/syscalls.c | $(STARBUG_BUILD_DIR)
	$(STARBUG_GCC) $(STARBUG_GCC_CFLAGS) -c $< -o $@

$(STARBUG_ELF): $(STARBUG_CRT_OBJ) $(STARBUG_SYSCALLS_OBJ) $(STARBUG_BENCH_OBJS)
	$(STARBUG_LINKER) $(STARBUG_LINKFLAGS) $^ $(STARBUG_LIBS) -o $@
	$(STARBUG_SIZE) $@

$(EMPTY_STARBUG_ELF): $(STARBUG_CRT_OBJ) $(STARBUG_SYSCALLS_OBJ) $(STARBUG_EMPTY_OBJS)
	$(STARBUG_LINKER) $(STARBUG_LINKFLAGS) $^ $(STARBUG_LIBS) -o $@
	$(STARBUG_SIZE) $@

# -------------------------------------------------------------------
# Utility Targets
# -------------------------------------------------------------------
dump: $(SCALAR_WALLY_ELF) $(EMPTY_WALLY_ELF) $(VLIW_WALLY_ELF) $(STARBUG_ELF) $(EMPTY_STARBUG_ELF)
	$(OBJDUMP) -D $(SCALAR_WALLY_ELF) > $(SCALAR_WALLY_ELF).dump
	$(OBJDUMP) -D $(EMPTY_WALLY_ELF) > $(EMPTY_WALLY_ELF).dump
	$(OBJDUMP) -D $(VLIW_WALLY_ELF) > $(VLIW_WALLY_ELF).dump
	$(OBJDUMP) -D $(STARBUG_ELF) > $(STARBUG_ELF).dump
	$(OBJDUMP) -D $(EMPTY_STARBUG_ELF) > $(EMPTY_STARBUG_ELF).dump

# Nothing checks a hand-written bundle. The hints in common/vliw_asm/*.S are
# inserted by hand and the seeding script only strips comments, so a branch in a
# worker lane or a RAW pair inside a bundle is a silent wrong answer that still
# links, still runs and (given a tolerance-based SNR check) may still say PASS.
# Run the same verifier over both the hand-scheduled and the compiled binary.
# Run both, then report: a failure in one variant must not hide the other.
verify:
	@rc=0; $(MAKE) --no-print-directory verify-vliw || rc=1; \
	$(MAKE) --no-print-directory verify-starbug || rc=1; \
	exit $$rc

verify-vliw: $(VLIW_WALLY_ELF)
	python3 $(BUNDLE_CHECK) $<

verify-starbug: $(STARBUG_ELF)
	python3 $(BUNDLE_CHECK) $<

clean:
	rm -rf $(STARBUG_BUILD_DIR) *.elf *.dump

define REGISTER_VLIW_SEED
.PHONY: seed-$(1)
seed-$(1):
	@mkdir -p $$(dir $(1))
	@tmp_file=$$$$(mktemp); \
	$$(WALLY_CC) -S $(2) -o $$$$tmp_file $$(GCC_SEED_ASM_FLAGS); \
	python3 $$(VLIW_ASM_SANITIZER) --input $$$$tmp_file --output $(1) --source $(2) --benchmarks "$(3)"; \
	rm -f $$$$tmp_file

seed-vliw-asm: seed-$(1)
endef
