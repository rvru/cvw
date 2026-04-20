OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

BOOTROM_BASE = 0x00010000;
BOOTROM_LIMIT = 0x00020000;

UNCORE_RAM_BASE = 0x00020000;
UNCORE_RAM_LIMIT = 0x00030000;

/* compatibility aliases for old tooling */
IROM_BASE = BOOTROM_BASE;
IROM_LIMIT = BOOTROM_LIMIT;
DTIM_BASE = UNCORE_RAM_BASE;
DTIM_LIMIT = UNCORE_RAM_LIMIT;

SECTIONS
{
  /* Reset vector is in Boot ROM */
  . = BOOTROM_BASE;

  .text :
  {
    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.init)
    *(.text .text.* .gnu.linkonce.t.*)
    *(.fini)
  }

  __text_end = .;
  ASSERT(__text_end <= BOOTROM_LIMIT,
         "BOOTROM overflow: .text does not fit in boot ROM")

  /* Put read/write data in RAM */
  . = UNCORE_RAM_BASE;

  .rodata :
  {
    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2)
    *(.srodata .srodata.*)
  }

  .data :
  {
    _data_start = .;
    *(.data .data.* .gnu.linkonce.d.*)
    CONSTRUCTORS
    _edata = .;
  }

  .sdata :
  {
    __SDATA_BEGIN__ = .;
    PROVIDE(__global_pointer$ = . + 0x800);
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  .tdata :
  {
    _tdata_begin = .;
    *(.tdata .tdata.* .gnu.linkonce.td.*)
    _tdata_end = .;
  }

  .tbss :
  {
    *(.tbss .tbss.* .gnu.linkonce.tb.*)
    *(.tcommon)
    _tbss_end = .;
  }

  . = ALIGN(16);
  __bss_start = .;

  .sbss :
  {
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }

  .bss :
  {
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
  }

  _end = .;
  ASSERT(_end <= UNCORE_RAM_LIMIT,
         "RAM overflow: data/bss does not fit in uncore RAM")

  PROVIDE(end = .);

  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) *(.interp) }
}