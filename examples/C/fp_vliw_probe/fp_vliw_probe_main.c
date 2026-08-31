#include <stdint.h>
#include <stdio.h>

extern uint32_t scalar_fadd_baseline(void);
extern uint32_t scalar_fmul_baseline(void);
extern uint32_t bundle_int_then_scalar_fadd(void);
extern uint32_t bundle_int_then_scalar_fmul(void);
extern uint32_t slot0_fadd_hint_relaxed(void);
extern uint32_t slot1_fadd_hint_relaxed(void);
extern uint32_t slot2_fadd_hint_relaxed(void);
extern uint32_t slot0_fmul_hint_relaxed(void);
extern uint32_t slot1_fmul_hint_relaxed(void);
extern uint32_t slot2_fmul_hint_relaxed(void);
extern uint32_t dual_fp_slot0_fadd_slot1_fmul_ret_slot0(void);
extern uint32_t dual_fp_slot0_fadd_slot1_fmul_ret_slot1(void);
extern uint32_t slot0_fsw_slot1_fadd_store(void);
extern uint32_t slot0_fsw_slot1_fadd_result(void);
extern uint32_t slot0_fsw_slot1_fmul_store(void);
extern uint32_t slot0_fsw_slot1_fmul_result(void);
extern uint32_t slot1_fadd_then_scalar_fadd_nogap(void);
extern uint32_t slot1_fmul_then_scalar_fadd_nogap(void);
extern uint32_t two_bundle_fadd_chain(void);
extern uint32_t two_bundle_fmul_chain(void);
extern uint32_t fp_load_base_from_bundled_addi_highreg(void);
extern uint32_t fp_store_prev_result_in_hinted_bundle_highreg(void);
extern uint32_t bundle_slot2_counter_fp_gap_value(void);
extern uint32_t bundle_slot1_fp_store_base_window_flags(void);
extern uint32_t arm_mult_style8_scalarized_exact(void);
extern uint32_t arm_mult_style8_addi_hint_only(void);
extern uint32_t arm_mult_style8_store_hint_only(void);
extern uint32_t arm_mult_style8_all_hints(void);
extern uint32_t arm_mult_style16_scalarized_exact(void);
extern uint32_t arm_mult_style16_all_hints(void);
extern uint32_t bundle_slot2_counter_fp_gap_value_drained(void);
extern uint32_t bundle_slot1_fp_store_base_window_flags_drained(void);
extern uint32_t arm_mult_style8_store_hint_only_shifted(void);
extern uint32_t bundle_slot1_a2_readback_drained(void);
extern uint32_t arm_mult_style8_addi_hint_only_shifted(void);
extern uint32_t bundle_slot1_a2_visible_same_gap(void);
extern uint32_t bundle_slot1_int_store_base_window_flags_drained(void);
extern uint32_t bundle_int_3wide_lane_mask(void);

typedef uint32_t (*probe_fn_t)(void);

struct probe_case {
  const char *name;
  probe_fn_t fn;
  uint32_t expected;
};

static const struct probe_case kProbeCases[] = {
    {"scalar_fadd_baseline", scalar_fadd_baseline, 0x40400000u},
    {"scalar_fmul_baseline", scalar_fmul_baseline, 0x41000000u},
    {"bundle_int_then_scalar_fadd", bundle_int_then_scalar_fadd, 0x40400000u},
    {"bundle_int_then_scalar_fmul", bundle_int_then_scalar_fmul, 0x41000000u},
    {"slot0_fadd_hint_relaxed", slot0_fadd_hint_relaxed, 0x40400000u},
    {"slot1_fadd_hint_relaxed", slot1_fadd_hint_relaxed, 0x40400000u},
    {"slot2_fadd_hint_relaxed", slot2_fadd_hint_relaxed, 0x40400000u},
    {"slot0_fmul_hint_relaxed", slot0_fmul_hint_relaxed, 0x41000000u},
    {"slot1_fmul_hint_relaxed", slot1_fmul_hint_relaxed, 0x41000000u},
    {"slot2_fmul_hint_relaxed", slot2_fmul_hint_relaxed, 0x41000000u},
    {"dual_fp_slot0_fadd_slot1_fmul_ret_slot0", dual_fp_slot0_fadd_slot1_fmul_ret_slot0, 0x40400000u},
    {"dual_fp_slot0_fadd_slot1_fmul_ret_slot1", dual_fp_slot0_fadd_slot1_fmul_ret_slot1, 0x41000000u},
    {"slot0_fsw_slot1_fadd_store", slot0_fsw_slot1_fadd_store, 0x40800000u},
    {"slot0_fsw_slot1_fadd_result", slot0_fsw_slot1_fadd_result, 0x40400000u},
    {"slot0_fsw_slot1_fmul_store", slot0_fsw_slot1_fmul_store, 0x40800000u},
    {"slot0_fsw_slot1_fmul_result", slot0_fsw_slot1_fmul_result, 0x41000000u},
    {"slot1_fadd_then_scalar_fadd_nogap", slot1_fadd_then_scalar_fadd_nogap, 0x40e00000u},
    {"slot1_fmul_then_scalar_fadd_nogap", slot1_fmul_then_scalar_fadd_nogap, 0x41100000u},
    {"two_bundle_fadd_chain", two_bundle_fadd_chain, 0x40e00000u},
    {"two_bundle_fmul_chain", two_bundle_fmul_chain, 0x41100000u},
    {"fp_load_base_from_bundled_addi_highreg", fp_load_base_from_bundled_addi_highreg, 0x40000000u},
    {"fp_store_prev_result_in_hinted_bundle_highreg", fp_store_prev_result_in_hinted_bundle_highreg, 0x40000000u},
    {"bundle_slot2_counter_fp_gap_value", bundle_slot2_counter_fp_gap_value, 0u},
    {"bundle_slot1_fp_store_base_window_flags", bundle_slot1_fp_store_base_window_flags, 2u},
    {"arm_mult_style8_scalarized_exact", arm_mult_style8_scalarized_exact, 0u},
    {"arm_mult_style8_addi_hint_only", arm_mult_style8_addi_hint_only, 0u},
    {"arm_mult_style8_store_hint_only", arm_mult_style8_store_hint_only, 0u},
    {"arm_mult_style8_all_hints", arm_mult_style8_all_hints, 0u},
    {"arm_mult_style16_scalarized_exact", arm_mult_style16_scalarized_exact, 0u},
    {"arm_mult_style16_all_hints", arm_mult_style16_all_hints, 0u},
    {"bundle_slot2_counter_fp_gap_value_drained", bundle_slot2_counter_fp_gap_value_drained, 0u},
    {"bundle_slot1_fp_store_base_window_flags_drained", bundle_slot1_fp_store_base_window_flags_drained, 2u},
    {"arm_mult_style8_store_hint_only_shifted", arm_mult_style8_store_hint_only_shifted, 0u},
    {"bundle_slot1_a2_readback_drained", bundle_slot1_a2_readback_drained, 64u},
    {"arm_mult_style8_addi_hint_only_shifted", arm_mult_style8_addi_hint_only_shifted, 0u},
    {"bundle_slot1_a2_visible_same_gap", bundle_slot1_a2_visible_same_gap, 64u},
    {"bundle_slot1_int_store_base_window_flags_drained", bundle_slot1_int_store_base_window_flags_drained, 2u},
    {"bundle_int_3wide_lane_mask", bundle_int_3wide_lane_mask, 7u},
};

int main(void) {
  unsigned failures = 0;
  unsigned total = sizeof(kProbeCases) / sizeof(kProbeCases[0]);
#ifdef PROBE_ONLY
  unsigned start = (unsigned)PROBE_ONLY;
  unsigned end = start + 1;
#else
  unsigned start = 0;
  unsigned end = total;
#endif

  if (start >= total) {
#ifdef PROBE_ONLY
    return 99;
#else
    printf("fp vliw probe\n");
    printf("hint cases use c.li x0,N as bundle markers on starbug.\n");
    printf("rv32gc should treat those as no-op hints.\n");
    printf("bad probe index %d total=%d\n", (int)start, (int)total);
#endif
    return 99;
  }

#ifndef PROBE_ONLY
  printf("fp vliw probe\n");
  printf("hint cases use c.li x0,N as bundle markers on starbug.\n");
  printf("rv32gc should treat those as no-op hints.\n");
#endif

  for (unsigned i = start; i < end; ++i) {
#ifndef PROBE_ONLY
    printf("run %d %s\n", (int)i, kProbeCases[i].name);
#endif
    uint32_t got = kProbeCases[i].fn();
    int pass = (got == kProbeCases[i].expected);
    failures += (unsigned)!pass;
#ifdef PROBE_ONLY
    printf("probe %d %s got=%08lx expected=%08lx %s\n",
           (int)i,
           kProbeCases[i].name,
           (unsigned long)got,
           (unsigned long)kProbeCases[i].expected,
           pass ? "PASS" : "FAIL");
#else
    printf("%d %s got=%08lx expected=%08lx %s\n",
           (int)i,
           kProbeCases[i].name,
           (unsigned long)got,
           (unsigned long)kProbeCases[i].expected,
           pass ? "PASS" : "FAIL");
#endif
  }

#ifndef PROBE_ONLY
  printf("summary: %d/%d failed\n", (int)failures, (int)(end - start));
#endif
  return (int)failures;
}
