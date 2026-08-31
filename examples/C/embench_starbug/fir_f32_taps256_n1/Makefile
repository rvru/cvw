VLIW_OVERRIDE_C_SRCS = $(CMSIS_LIB_DIR)/src/FilteringFunctions/arm_fir_f32.c
VLIW_ASM_SRCS = $(VLIW_FILTERING_ASM_DIR)/arm_fir_f32_vliw.S

include ../common/bench_common.mk

$(eval $(call REGISTER_VLIW_SEED,$(VLIW_FILTERING_ASM_DIR)/arm_fir_f32_vliw.S,$(CMSIS_LIB_DIR)/src/FilteringFunctions/arm_fir_f32.c,fir_f32_taps256_n1 fir_f32_taps256_n128))
