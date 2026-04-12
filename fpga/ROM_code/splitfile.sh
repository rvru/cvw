#!/bin/bash
set -euo pipefail

#######################################################################
# splitfile.sh
#
# Written: Jacob Pease jacob.pease@okstate.edu 7/22/2024
#
# Purpose: Used to split boot.mem into two sections for FPGA
#
# A component of the Wally configurable RISC-V project.
#
# Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#######################################################################

file_name=${1:?Usage: $0 <memfile> [bit_width]}
bit_width=${2:-32}

if [[ ! -f "$file_name" ]]; then
  echo "Error: memfile '$file_name' not found" >&2
  exit 1
fi

if (( bit_width <= 0 || bit_width % 8 != 0 )); then
  echo "Error: bit width must be a positive multiple of 8, got ${bit_width}" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
linker_file="${script_dir}/linker1000.x"

if [[ ! -f "$linker_file" ]]; then
  echo "Error: linker script '$linker_file' not found" >&2
  exit 1
fi

extract_linker_const() {
  local name="$1"
  local value

  value=$(sed -nE "s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*([^;]+);.*/\\1/p" "$linker_file" | head -n 1)

  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return 0
  fi

  return 1
}

extract_first_available() {
  local value
  for name in "$@"; do
    if value=$(extract_linker_const "$name"); then
      printf '%s' "$value"
      return 0
    fi
  done

  echo "Error: could not find any of these symbols in ${linker_file}: $*" >&2
  exit 1
}

# Support both old and new linker symbol names.
# Prefer the numeric definitions first so we do not accidentally pick up an
# alias such as IROM_BASE = BOOTROM_BASE; and then feed a symbol name into bash
# arithmetic expansion.
rom_base=$(( $(extract_first_available BOOTROM_BASE IROM_BASE) ))
ram_base=$(( $(extract_first_available UNCORE_RAM_BASE DTIM_BASE) ))

bytes_per_word=$(( bit_width / 8 ))
split_lines=$(( (ram_base - rom_base) / bytes_per_word ))

if (( ram_base < rom_base )); then
  echo "Error: RAM base (0x$(printf '%x' "$ram_base")) is below ROM base (0x$(printf '%x' "$rom_base"))" >&2
  exit 1
fi

if (( (ram_base - rom_base) % bytes_per_word != 0 )); then
  echo "Error: split boundary is not aligned to word width" >&2
  echo "  rom_base  = 0x$(printf '%x' "$rom_base")" >&2
  echo "  ram_base  = 0x$(printf '%x' "$ram_base")" >&2
  echo "  word size = ${bytes_per_word} bytes" >&2
  exit 1
fi

if (( split_lines < 0 )); then
  echo "Error: derived split point is negative (${split_lines})" >&2
  exit 1
fi

total_lines=$(wc -l < "$file_name")

head -n "$split_lines" "$file_name" > boot.mem

if (( total_lines > split_lines )); then
  tail -n "$(( total_lines - split_lines ))" "$file_name" > data.mem
else
  : > data.mem
fi

echo "Split ${file_name}:"
echo "  ROM base   : 0x$(printf '%x' "$rom_base")"
echo "  RAM base   : 0x$(printf '%x' "$ram_base")"
echo "  Word bytes : ${bytes_per_word}"
echo "  Boot lines : ${split_lines}"
echo "  Total lines: ${total_lines}"
