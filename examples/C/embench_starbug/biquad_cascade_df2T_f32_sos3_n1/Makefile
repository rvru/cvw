VLIW_OVERRIDE_C_SRCS = $(CMSIS_LIB_DIR)/src/FilteringFunctions/arm_biquad_cascade_df2T_f32.c
VLIW_ASM_SRCS = $(VLIW_FILTERING_ASM_DIR)/arm_biquad_cascade_df2T_f32_vliw.S

include ../common/bench_common.mk

$(eval $(call REGISTER_VLIW_SEED,$(VLIW_FILTERING_ASM_DIR)/arm_biquad_cascade_df2T_f32_vliw.S,$(CMSIS_LIB_DIR)/src/FilteringFunctions/arm_biquad_cascade_df2T_f32.c,biquad_cascade_df2T_f32_sos3_n1 biquad_cascade_df2T_f32_sos3_n128))
