/* SPDX-License-Identifier: Apache-2.0 */

int *__errno(void) {
  static int errno_value;
  return &errno_value;
}
