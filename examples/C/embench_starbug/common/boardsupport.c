/* SPDX-License-Identifier: GPL-3.0-or-later */

#include <stdint.h>

#include "boardsupport.h"

static uint32_t start_cycle;
static uint32_t stop_cycle;

static inline uint32_t read_cycle(void) {
  uint32_t cycle;
  asm volatile("csrr %0, mcycle" : "=r"(cycle));
  return cycle;
}

void init_board(void) {}

void __attribute__((noinline)) start_trigger(void) {
  asm volatile("" ::: "memory");
  start_cycle = read_cycle();
  asm volatile("" ::: "memory");
}

void __attribute__((noinline)) stop_trigger(void) {
  asm volatile("" ::: "memory");
  stop_cycle = read_cycle();
  asm volatile("" ::: "memory");
}

int __attribute__((noinline)) get_ccnt(void) {
  return (int)(stop_cycle - start_cycle);
}
