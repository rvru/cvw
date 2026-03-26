#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

extern uint32_t pre_slot0_store_no_gap(void);
extern uint32_t pre_slot0_store_gap_before_hint(void);
extern uint32_t pre_slot0_rs1_no_gap(void);
extern uint32_t pre_slot0_rs1_gap_before_hint(void);
extern uint32_t pre_slot0_rs2_no_gap(void);
extern uint32_t pre_slot0_rs2_gap_before_hint(void);
extern uint32_t pre_slot0_store_chain_no_gap(void);
extern uint32_t pre_slot0_store_chain_gap_before_hint(void);
extern uint32_t slot1_to_scalar_rs1_no_gap(void);
extern uint32_t slot1_to_scalar_rs1_gap_after_bundle(void);
extern uint32_t lane1_to_scalar_rs1_regreg_no_gap(void);
extern uint32_t lane1_to_scalar_rs1_regreg_gap_after_bundle(void);
extern uint32_t lane1_to_scalar_rs2_regreg_no_gap(void);
extern uint32_t lane1_to_scalar_rs2_regreg_gap_after_bundle(void);
extern uint32_t slot2_to_scalar_store_no_gap(void);
extern uint32_t slot2_to_scalar_store_gap_after_bundle(void);
extern uint32_t lane2_to_scalar_rs1_regreg_no_gap(void);
extern uint32_t lane2_to_scalar_rs1_regreg_gap_after_bundle(void);
extern uint32_t lane2_to_scalar_rs2_regreg_no_gap(void);
extern uint32_t lane2_to_scalar_rs2_regreg_gap_after_bundle(void);
extern uint32_t post_bundle_two_stores_no_gap(void);
extern uint32_t post_bundle_two_stores_gap_after_bundle(void);
extern uint32_t dual_lane_dual_source_no_gap(void);
extern uint32_t dual_lane_dual_source_gap_after_bundle(void);
extern uint32_t triple_store_path_no_gap(void);
extern uint32_t triple_store_path_gap_before_hint(void);
extern uint32_t snippet_shape_no_gap(void);
extern uint32_t snippet_shape_gap_before_hint(void);
extern uint32_t snippet_shape_loop16_no_gap(void);
extern uint32_t snippet_shape_loop16_gap_before_hint(void);
extern uint32_t two_bundle_dual_consumer_hint(void);
extern uint32_t two_bundle_dual_consumer_scalarized(void);
extern uint32_t two_bundle_snippet_hint(void);
extern uint32_t two_bundle_snippet_scalarized(void);
extern uint32_t two_bundle_branch_hint(void);
extern uint32_t two_bundle_branch_scalarized(void);

typedef uint32_t (*probe_fn_t)(void);

struct probe_case {
  const char *name;
  probe_fn_t fn;
  uint32_t expected;
};

static const struct probe_case kProbeCases[] = {
    {"pre_slot0_store_no_gap", pre_slot0_store_no_gap, 15},
    {"pre_slot0_store_gap_before_hint", pre_slot0_store_gap_before_hint, 15},
    {"pre_slot0_rs1_no_gap", pre_slot0_rs1_no_gap, 19},
    {"pre_slot0_rs1_gap_before_hint", pre_slot0_rs1_gap_before_hint, 19},
    {"pre_slot0_rs2_no_gap", pre_slot0_rs2_no_gap, 5},
    {"pre_slot0_rs2_gap_before_hint", pre_slot0_rs2_gap_before_hint, 5},
    {"pre_slot0_store_chain_no_gap", pre_slot0_store_chain_no_gap, 33},
    {"pre_slot0_store_chain_gap_before_hint", pre_slot0_store_chain_gap_before_hint, 33},
    {"slot1_to_scalar_rs1_no_gap", slot1_to_scalar_rs1_no_gap, 19},
    {"slot1_to_scalar_rs1_gap_after_bundle", slot1_to_scalar_rs1_gap_after_bundle, 19},
    {"lane1_to_scalar_rs1_regreg_no_gap", lane1_to_scalar_rs1_regreg_no_gap, 13},
    {"lane1_to_scalar_rs1_regreg_gap_after_bundle", lane1_to_scalar_rs1_regreg_gap_after_bundle, 13},
    {"lane1_to_scalar_rs2_regreg_no_gap", lane1_to_scalar_rs2_regreg_no_gap, 13},
    {"lane1_to_scalar_rs2_regreg_gap_after_bundle", lane1_to_scalar_rs2_regreg_gap_after_bundle, 13},
    {"slot2_to_scalar_store_no_gap", slot2_to_scalar_store_no_gap, 15},
    {"slot2_to_scalar_store_gap_after_bundle", slot2_to_scalar_store_gap_after_bundle, 15},
    {"lane2_to_scalar_rs1_regreg_no_gap", lane2_to_scalar_rs1_regreg_no_gap, 5},
    {"lane2_to_scalar_rs1_regreg_gap_after_bundle", lane2_to_scalar_rs1_regreg_gap_after_bundle, 5},
    {"lane2_to_scalar_rs2_regreg_no_gap", lane2_to_scalar_rs2_regreg_no_gap, 5},
    {"lane2_to_scalar_rs2_regreg_gap_after_bundle", lane2_to_scalar_rs2_regreg_gap_after_bundle, 5},
    {"post_bundle_two_stores_no_gap", post_bundle_two_stores_no_gap, 0x00000d05u},
    {"post_bundle_two_stores_gap_after_bundle", post_bundle_two_stores_gap_after_bundle, 0x00000d05u},
    {"dual_lane_dual_source_no_gap", dual_lane_dual_source_no_gap, 18},
    {"dual_lane_dual_source_gap_after_bundle", dual_lane_dual_source_gap_after_bundle, 18},
    {"triple_store_path_no_gap", triple_store_path_no_gap, 0x000d2105u},
    {"triple_store_path_gap_before_hint", triple_store_path_gap_before_hint, 0x000d2105u},
    {"snippet_shape_no_gap", snippet_shape_no_gap, 0x0f0d2105u},
    {"snippet_shape_gap_before_hint", snippet_shape_gap_before_hint, 0x0f0d2105u},
    {"snippet_shape_loop16_no_gap", snippet_shape_loop16_no_gap, 0xf0d21050u},
    {"snippet_shape_loop16_gap_before_hint", snippet_shape_loop16_gap_before_hint, 0xf0d21050u},
    {"two_bundle_dual_consumer_hint", two_bundle_dual_consumer_hint, 0x080f0005u},
    {"two_bundle_dual_consumer_scalarized", two_bundle_dual_consumer_scalarized, 0x080f0005u},
    {"two_bundle_snippet_hint", two_bundle_snippet_hint, 0x0f002105u},
    {"two_bundle_snippet_scalarized", two_bundle_snippet_scalarized, 0x0f002105u},
    {"two_bundle_branch_hint", two_bundle_branch_hint, 18},
    {"two_bundle_branch_scalarized", two_bundle_branch_scalarized, 18},
};

int main(void) {
  unsigned failures = 0;
  unsigned total = sizeof(kProbeCases) / sizeof(kProbeCases[0]);

  printf("forwarding probe\n");
  printf("no_gap cases require the immediate bypass path; gap cases shift the same dependency by one cycle.\n");
  printf("all hint-bearing cases in this probe activate more than one lane, and several cases make the consumer a store.\n");
  printf("two_bundle_* cases specifically test a real bundle immediately followed by another real bundle or a scalarized control case.\n");

  for (unsigned i = 0; i < total; ++i) {
    uint32_t got = kProbeCases[i].fn();
    int pass = (got == kProbeCases[i].expected);
    failures += (unsigned)!pass;
    printf("%-38s got=0x%08" PRIx32 " expected=0x%08" PRIx32 " %s\n",
           kProbeCases[i].name,
           got,
           kProbeCases[i].expected,
           pass ? "PASS" : "FAIL");
  }

  printf("summary: %u/%u failed\n", failures, total);
  return (int)failures;
}
