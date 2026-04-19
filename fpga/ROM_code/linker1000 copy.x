OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Address map for the current adrdec mask-style decoder:
 *   match = &((addr ~^ BASE) | RANGE)
 * BASE must be aligned to (RANGE+1) for intuitive contiguous regions.
 *
 * Chosen map:
 *   IROM (execute-only): 0x0000_1000 - 0x0000_1FFF  (RESET at 0x1000)
 *   DTIM (read/write):   0x0000_3000 - 0x0000_1FFF
 */
IROM_BASE  = 0x00001000;
IROM_LIMIT = 0x00003000;
DTIM_BASE  = 0x00003000;
DTIM_LIMIT = 0x00005000;

SECTIONS
{
  /* Starting at 0x1000 to match IROM location */
  . = IROM_BASE;

  .text :
  {
    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.init)    /* Ensure init code is here */
    *(.text .text.* .gnu.linkonce.t.*)
    *(.fini)
  }

  __IROM_end = .;
  ASSERT(__IROM_end <= IROM_LIMIT,
         "IROM overflow: .text exceeds 0x1fff; image no longer fits before DTIM at 0x4000")

  /* Data segment — must be in DTIM (0x4000+), not IROM.
   * The IROM is instruction-fetch-only hardware; data loads/stores in IROM
   * stall the AHB bus permanently because uncore.sv has no HREADY response for HSELIROM. */
  . = DTIM_BASE;
  _data_start = .;
  .rodata :
  {
    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
  }
  .data :
  {
    *(.data .data.* .gnu.linkonce.d.*)
    CONSTRUCTORS
  }

  /* Small data section and Global Pointer */
  .sdata :
  {
    __SDATA_BEGIN__ = .;
    PROVIDE(__global_pointer$ = . + 0x800);
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }
  _edata = .;
  PROVIDE(edata = .);

  /* Thread Local Storage */
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

  /* BSS (Zero-initialized data) */
  . = ALIGN(0x10);
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

  __DTIM_end = .;
  ASSERT(__DTIM_end <= DTIM_LIMIT,
         "DTIM overflow: .text exceeds 0x1fff; image no longer fits")

  _end = .;
  PROVIDE(end = .);

  /* Discard unnecessary sections */
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) *(.interp) }
}