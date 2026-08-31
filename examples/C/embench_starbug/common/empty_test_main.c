/* SPDX-License-Identifier: GPL-3.0-or-later */

#include <stdint.h>
#include <stdio.h>

#include "boardsupport.h"

int __attribute__((used)) test_main(int argc __attribute__((unused)),
                                    char *argv[] __attribute__((unused))) {
  uint32_t ccnt;

  start_trigger();
  stop_trigger();
  ccnt = get_ccnt();

  printf("TEST PASS\nCCNT = %u\n", ccnt);
  return 0;
}
