CEXT          := c
CPPEXT        := cpp
AEXT          := s
SEXT          := S
SRCEXT        := \([$(CEXT)$(AEXT)$(SEXT)]\|$(CPPEXT)\)
OBJEXT        := o
DEPEXT        := d
SRCDIR        := .
BUILDDIR      := OBJ
TARGETDIR     := bin
.DEFAULT_GOAL := all

# 1. Require romCode only for specific targets (e.g., all, Arty, Arty_imc)
CHECK_TARGETS := all Arty Arty_imc $(TARGETDIR)/boot.memfile
ifneq ($(filter $(CHECK_TARGETS),$(MAKECMDGOALS)),)
    ifndef romCode
        $(error romCode is not set. Usage: make romCode=your_value (romCode should be a folder located in ../loadable_programs/))
    endif
endif

LOADABLE_DIR  := ../loadable_programs/$(romCode)

# 2. Search for sources in both directories.
# Follow symlinks so benchmark wrappers like loadable_programs/fft are included.
ROOT_SOURCES  := $(shell find -L $(SRCDIR) -type f ! -name '._*' \
                   \( -name '*.$(CEXT)' -o -name '*.$(AEXT)' -o -name '*.$(SEXT)' -o -name '*.$(CPPEXT)' \) | sort)
ifdef romCode
LOADABLE_SOURCES := $(shell find -L $(LOADABLE_DIR) -type f ! -name '._*' \
                   \( -name '*.$(CEXT)' -o -name '*.$(AEXT)' -o -name '*.$(SEXT)' -o -name '*.$(CPPEXT)' \) | sort 2>/dev/null)
else
LOADABLE_SOURCES :=
endif
SOURCES       := $(ROOT_SOURCES) $(LOADABLE_SOURCES)

# 3. Object mapping.
# Prefix loadable-program objects with romCode so benchmark data files do not
# collide when switching between different romCode values.
ROOT_OBJECTS  := $(ROOT_SOURCES:.$(CEXT)=.$(OBJEXT))
ROOT_OBJECTS  := $(ROOT_OBJECTS:.$(AEXT)=.$(OBJEXT))
ROOT_OBJECTS  := $(ROOT_OBJECTS:.$(SEXT)=.$(OBJEXT))
ROOT_OBJECTS  := $(ROOT_OBJECTS:.$(CPPEXT)=.$(OBJEXT))
ROOT_OBJECTS  := $(addprefix $(BUILDDIR)/, $(notdir $(ROOT_OBJECTS)))

ifdef romCode
LOADABLE_OBJECTS := $(LOADABLE_SOURCES:.$(CEXT)=.$(OBJEXT))
LOADABLE_OBJECTS := $(LOADABLE_OBJECTS:.$(AEXT)=.$(OBJEXT))
LOADABLE_OBJECTS := $(LOADABLE_OBJECTS:.$(SEXT)=.$(OBJEXT))
LOADABLE_OBJECTS := $(LOADABLE_OBJECTS:.$(CPPEXT)=.$(OBJEXT))
LOADABLE_OBJECTS := $(addprefix $(BUILDDIR)/$(romCode)_, $(notdir $(LOADABLE_OBJECTS)))
else
LOADABLE_OBJECTS :=
endif

OBJECTS       := $(ROOT_OBJECTS) $(LOADABLE_OBJECTS)

# Include generated header dependencies when they exist.
-include $(OBJECTS:.$(OBJEXT)=.$(DEPEXT))

# 4. VPATH allows Make to find the raw source files regardless of which directory they are in
vpath %.$(CEXT)   $(SRCDIR) $(LOADABLE_DIR)
vpath %.$(CPPEXT) $(SRCDIR) $(LOADABLE_DIR)
vpath %.$(AEXT)   $(SRCDIR) $(LOADABLE_DIR)
vpath %.$(SEXT)   $(SRCDIR) $(LOADABLE_DIR)

# --- Standard Variables ---
TARGET        := $(TARGETDIR)/boot
MARCH         := -march=rv32imac_zicsr
MABI          := -mabi=ilp32
LINK_FLAGS    := $(MARCH) $(MABI) -nostartfiles
LIBS          := -lm
LINKER        := linker1000.x
ELF2HEX_BITWIDTH := 32

SYSTEMCLOCK   ?= 20000000
MAXSDCCLOCK   ?= 5000000
EXT_MEM_BASE  ?= 0x80000000
EXT_MEM_RANGE ?= 0x10000000

override CFLAGS += $(MARCH) $(MABI) -mcmodel=medany -O2 -g \
                   -DSYSTEMCLOCK=${SYSTEMCLOCK} -DMAXSDCCLOCK=${MAXSDCCLOCK} \
                   -DEXT_MEM_BASE=${EXT_MEM_BASE} -DEXT_MEM_RANGE=${EXT_MEM_RANGE}

CC := riscv64-unknown-elf-gcc

# --- Targets ---

all: directories $(TARGET).memfile

Arty_imc: XILINX_PART := xc7a100tcsg324-1
Arty_imc: all
	@echo "Built for Part: $(XILINX_PART)"

directories:
	@mkdir -p $(TARGETDIR)
	@mkdir -p $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR) $(TARGETDIR)

# --- Compiler Rules (Using vpath) ---

$(BUILDDIR)/%.$(OBJEXT): %.$(CEXT)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<
	@$(CC) $(CFLAGS) $(INC) -MM -MT $@ $< > $(BUILDDIR)/$*.$(DEPEXT)

$(BUILDDIR)/%.$(OBJEXT): %.$(AEXT)
	$(CC) $(CFLAGS) -c -o $@ $<
	@echo $@: $< > $(BUILDDIR)/$*.$(DEPEXT)

$(BUILDDIR)/%.$(OBJEXT): %.$(SEXT)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<
	@echo $@: $< > $(BUILDDIR)/$*.$(DEPEXT)

$(BUILDDIR)/$(romCode)_%.$(OBJEXT): $(LOADABLE_DIR)/%.$(CEXT)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<
	@$(CC) $(CFLAGS) $(INC) -MM -MT $@ $< > $(BUILDDIR)/$(romCode)_$*.$(DEPEXT)

$(BUILDDIR)/$(romCode)_%.$(OBJEXT): $(LOADABLE_DIR)/%.$(AEXT)
	$(CC) $(CFLAGS) -c -o $@ $<
	@echo $@: $< > $(BUILDDIR)/$(romCode)_$*.$(DEPEXT)

$(BUILDDIR)/$(romCode)_%.$(OBJEXT): $(LOADABLE_DIR)/%.$(SEXT)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<
	@echo $@: $< > $(BUILDDIR)/$(romCode)_$*.$(DEPEXT)

# --- Linker and Post-Processing ---

$(TARGET): $(OBJECTS)
	$(CC) $(LINK_FLAGS) -g -o $(TARGET) $(OBJECTS) $(LIBS) -T ${LINKER}

$(TARGET).memfile: $(TARGET)
	riscv64-unknown-elf-objdump -d $< > $<.objdump
	cp $<.objdump ../src/boot.objdump
	riscv64-unknown-elf-elf2hex --bit-width $(ELF2HEX_BITWIDTH) --input $< --output $@
	./splitfile.sh $@ $(ELF2HEX_BITWIDTH)
	mv boot.mem ../src/boot.mem
	mv data.mem ../src/data.mem

.PHONY: all clean directories Arty_imc
