/* Copyright EPFL contributors.
 * Licensed under the Apache License, Version 2.0, see LICENSE for details.
 * SPDX-License-Identifier: Apache-2.0
 */

OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv",
        "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  FLASH (rx)      : ORIGIN = 0x40000000, LENGTH = 0x01000000
  ram0  (rwxai)   : ORIGIN = 0x00000000, LENGTH = 0x00000C800
  ram1  (rwxai)   : ORIGIN = 0x00000C800, LENGTH = 0x00003800
  ram_il (rwxai)  : ORIGIN = 0x00010000, LENGTH = 0x00020000
}

/*
 * This linker script try to put data in ram1 and code
 * in ram0.
*/

SECTIONS
{
  /* we want a fixed entry point */
  PROVIDE(__boot_address = 0x180);

  /* stack and heap related settings */
  __stack_size = DEFINED(__stack_size) ? __stack_size : 0x800;
  PROVIDE(__stack_size = __stack_size);
  __heap_size = DEFINED(__heap_size) ? __heap_size : 0x800;

  /* Read-only sections, merged into text segment: */
  /* TODO: this triggers "main.elf: not enough room for program headers"
    when linking. How to fix it? */
  /* PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x10000)); . = SEGMENT_START("text-segment", 0x10000) + SIZEOF_HEADERS; */

  /* We don't do any dynamic linking so we remove everything related to it */
/*
  .interp         : { *(.interp) }
  .note.gnu.build-id : { *(.note.gnu.build-id) }
  .hash           : { *(.hash) }
  .gnu.hash       : { *(.gnu.hash) }
  .dynsym         : { *(.dynsym) }
  .dynstr         : { *(.dynstr) }
  .gnu.version    : { *(.gnu.version) }
  .gnu.version_d  : { *(.gnu.version_d) }
  .gnu.version_r  : { *(.gnu.version_r) }
  .rela.dyn       :
    {
      *(.rela.init)
      *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
      *(.rela.fini)
      *(.rela.rodata .rela.rodata.* .rela.gnu.linkonce.r.*)
      *(.rela.data .rela.data.* .rela.gnu.linkonce.d.*)
      *(.rela.tdata .rela.tdata.* .rela.gnu.linkonce.td.*)
      *(.rela.tbss .rela.tbss.* .rela.gnu.linkonce.tb.*)
      *(.rela.ctors)
      *(.rela.dtors)
      *(.rela.got)
      *(.rela.sdata .rela.sdata.* .rela.gnu.linkonce.s.*)
      *(.rela.sbss .rela.sbss.* .rela.gnu.linkonce.sb.*)
      *(.rela.sdata2 .rela.sdata2.* .rela.gnu.linkonce.s2.*)
      *(.rela.sbss2 .rela.sbss2.* .rela.gnu.linkonce.sb2.*)
      *(.rela.bss .rela.bss.* .rela.gnu.linkonce.b.*)
      PROVIDE_HIDDEN (__rela_iplt_start = .);
      *(.rela.iplt)
      PROVIDE_HIDDEN (__rela_iplt_end = .);
    }
  .rela.plt       :
    {
      *(.rela.plt)
    }
*/

  /* interrupt vectors */
  .vectors (ORIGIN(ram0)):
  {
    PROVIDE(__vector_start = .);
    KEEP(*(.vectors));
  } >ram0 AT >FLASH

  /* Fill memory up to __boot_address */
  .fill               :
  {
      FILL(0xDEADBEEF);
      . = ORIGIN(ram0) + (__boot_address) - 1;
      BYTE(0xEE)
  } >ram0 AT >FLASH

  /* crt0 init code */
  .init (__boot_address):
  {
      KEEP (*(SORT_NONE(.init)))
      KEEP (*(.text.start))
  } >ram0 AT >FLASH

  /* More dynamic linking sections */
/*
  .plt            : { *(.plt) }
  .iplt           : { *(.iplt) }
*/

  /* the bulk of the program: main, libc, functions etc. */
  .text               : ALIGN_WITH_INPUT
  {
    . = ALIGN(4);
    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    . = ALIGN(4);
  } >ram0 AT >FLASH

  .power_manager      : ALIGN(4096)
  {
     PROVIDE(__power_manager_start = .);
     . += 256;
  } >ram0

  /* not used by RISC-V*/
  .fini               :
  {
    KEEP (*(SORT_NONE(.fini)))
  } >ram0 AT >FLASH

  /* define a global symbol at end of code */
  PROVIDE(__etext = .);
  PROVIDE(_etext = .);
  PROVIDE(etext = .);

  /* read-only data sections */
  .rodata             :
  {
    *(.rodata .rodata.* .gnu.linkonce.r.*)
  } >ram1 AT >FLASH
  .rodata1            :
  {
    *(.rodata1)
  } >ram1 AT >FLASH

  /* second level sbss and sdata, I don't think we need this */
  /* .sdata2         : {*(.sdata2 .sdata2.* .gnu.linkonce.s2.*)} */
  /* .sbss2          : { *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*) } */

  /* gcc language agnostic exception related sections (try-catch-finally) */
  .eh_frame_hdr       :
  {
    *(.eh_frame_hdr) *(.eh_frame_entry .eh_frame_entry.*)
  } >ram0 AT >FLASH
  .eh_frame           : ONLY_IF_RO
  {
    KEEP (*(.eh_frame)) *(.eh_frame.*)
  } >ram0 AT >FLASH
  .gcc_except_table   : ONLY_IF_RO
  {
    *(.gcc_except_table .gcc_except_table.*)
  } >ram0 AT >FLASH
  .gnu_extab   : ONLY_IF_RO
  {
    *(.gnu_extab*)
  } >ram0 AT >FLASH
  /* These sections are generated by the Sun/Oracle C++ compiler.  */
  /*
  .exception_ranges   : ONLY_IF_RO { *(.exception_ranges
  .exception_ranges*) }
  */
  /* Adjust the address for the data segment.  We want to adjust up to
     the same address within the page on the next page up.  */
  . = DATA_SEGMENT_ALIGN (CONSTANT (MAXPAGESIZE), CONSTANT (COMMONPAGESIZE));

  /* Exception handling  */
  .eh_frame           : ONLY_IF_RW
  {
    KEEP (*(.eh_frame)) *(.eh_frame.*)
  } >ram0 AT >FLASH
  .gnu_extab          : ONLY_IF_RW
  {
    *(.gnu_extab)
  } >ram0 AT >FLASH
  .gcc_except_table   : ONLY_IF_RW
  {
    *(.gcc_except_table .gcc_except_table.*)
  } >ram0 AT >FLASH
  .exception_ranges   : ONLY_IF_RW
  {
    *(.exception_ranges .exception_ranges*)
  } >ram0 AT >FLASH

  /* Thread Local Storage sections  */
  .tdata    :
  {
    PROVIDE_HIDDEN (__tdata_start = .);
    *(.tdata .tdata.* .gnu.linkonce.td.*)
  } >ram1 AT >FLASH
  .tbss     :
  {
    *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon)
  } >ram1 AT >FLASH

  /* initialization and termination routines */
  .preinit_array     :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } >ram1 AT >FLASH
  .init_array       :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
  } >ram1 AT >FLASH
  .fini_array       :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } >ram1 AT >FLASH
  .ctors            :
  {
    /* gcc uses crtbegin.o to find the start of
       the constructors, so we make sure it is
       first.  Because this is a wildcard, it
       doesn't matter if the user does not
       actually link against crtbegin.o; the
       linker won't look for a file to match a
       wildcard.  The wildcard also means that it
       doesn't matter which directory crtbegin.o
       is in.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*crtbegin?.o(.ctors))
    /* We don't want to include the .ctor section from
       the crtend.o file until after the sorted ctors.
       The .ctor section from the crtend file contains the
       end of ctors marker and it must be last */
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  } >ram0 AT >FLASH
  .dtors          :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*crtbegin?.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } >ram0 AT >FLASH

  /* .jcr            : { KEEP (*(.jcr)) } */
  /* .data.rel.ro : { *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*) } */
  /* .dynamic        : { *(.dynamic) } */
  . = DATA_SEGMENT_RELRO_END (0, .);

  /* This is the initialized data section
  The program executes knowing that the data is in the RAM
  but the loader puts the initial values in the FLASH (inidata).
  It is one task of the startup to copy the initial values from FLASH to RAM. */
  .data             : ALIGN_WITH_INPUT
  {
      . = ALIGN(4);
      _ram_start = .;    /* create a global symbol at ram start for garbage collector */
      . = ALIGN(4);
      __DATA_BEGIN__ = .;
      *(.data .data.* .gnu.linkonce.d.*)
      SORT(CONSTRUCTORS)
      . = ALIGN(4);
  } >ram1 AT >FLASH
  .data1            : ALIGN_WITH_INPUT
  {
    . = ALIGN(4);
    *(.data1)
    . = ALIGN(4);
  } >ram1 AT >FLASH

  /* We want the small data sections together, so single-instruction offsets
     can access them all, and initialized data all before uninitialized, so
     we can shorten the on-disk segment size.  */
  .sdata              : ALIGN_WITH_INPUT
  {
    . = ALIGN(4);
    _sidata = LOADADDR(.data);
    _sdata = .;        /* create a global symbol at data start; used by startup code in order to initialise the .data section in RAM */
    __SDATA_BEGIN__ = .;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    . = ALIGN(4);
  } >ram1 AT >FLASH

  _edata = .; PROVIDE (edata = .);  /* define a global symbol at data end; used by startup code in order to initialise the .data section in RAM */

  /* zero initialized sections */
  __bss_start = .; /* define a global symbol at bss start; used by startup code */
  .sbss             :
  {
    . = ALIGN(4);
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    . = ALIGN(4);
  } >ram1 AT >FLASH
  .bss              :
  {
    . = ALIGN(4);
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
    /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.
      FIXME: Why do we need it? When there is no .bss section, we don't
      pad the .data section.  */
    . = ALIGN(. != 0 ? 32 / 8 : 1);
  } >ram1 AT >FLASH
  . = ALIGN(32 / 8);
  . = SEGMENT_START("ldata-segment", .);
  . = ALIGN(32 / 8);
  __BSS_END__ = .;
  __bss_end = .;         /* define a global symbol at bss end; used by startup code */

  /* The compiler uses this to access data in the .sdata, .data, .sbss and .bss
    sections with fewer instructions (relaxation). This reduces code size. */
  __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
          MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));
  _end = .; PROVIDE (end = .);
  . = DATA_SEGMENT_END (.);

  /* this is to define the start of the heap, and make sure we have a minimum size */
  .heap          :
  {
      PROVIDE(__heap_start = .);
      . = __heap_size;
      PROVIDE(__heap_end = .);
  } >ram1

  /* stack: we should consider putting this further to the top of the address
  space */
  .stack         : ALIGN(16) /* this is a requirement of the ABI(?) */
  {
      PROVIDE(__stack_start = .);
      . = __stack_size;
      PROVIDE(_sp = .);
      PROVIDE(__stack_end = .);
      PROVIDE(__freertos_irq_stack_top = .);
  } >ram1

% if ram_numbanks_cont > 1 and ram_numbanks_il > 0:
  /* Data mapped to the interleaved memory banks */
  .data_interleaved :
  {
  } >ram_il AT >FLASH
% endif

  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line .debug_line.* .debug_line_end ) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
  /* DWARF 3 */
  .debug_pubtypes 0 : { *(.debug_pubtypes) }
  .debug_ranges   0 : { *(.debug_ranges) }
  /* DWARF Extension.  */
  .debug_macro    0 : { *(.debug_macro) }
  .debug_addr     0 : { *(.debug_addr) }
  .gnu.attributes 0 : { KEEP (*(.gnu.attributes)) }
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}
