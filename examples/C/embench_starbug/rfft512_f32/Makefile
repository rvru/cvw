BENCH_FAST_MATH = -fno-fast-math

VLIW_OVERRIDE_C_SRCS = \
	$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_bitreversal2.c \
	$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_cfft_f32.c \
	$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_rfft_fast_f32.c
VLIW_ASM_SRCS = \
	$(VLIW_TRANSFORM_ASM_DIR)/arm_bitreversal2_vliw.S \
	$(VLIW_TRANSFORM_ASM_DIR)/arm_cfft_f32_vliw.S \
	$(VLIW_TRANSFORM_ASM_DIR)/arm_rfft_fast_f32_vliw.S

include ../common/bench_common.mk

$(eval $(call REGISTER_VLIW_SEED,$(VLIW_TRANSFORM_ASM_DIR)/arm_bitreversal2_vliw.S,$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_bitreversal2.c,rfft512_f32 rfft2048_f32 dct4_512_f32 dct4_2048_f32))
$(eval $(call REGISTER_VLIW_SEED,$(VLIW_TRANSFORM_ASM_DIR)/arm_cfft_f32_vliw.S,$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_cfft_f32.c,rfft512_f32 rfft2048_f32 dct4_512_f32 dct4_2048_f32))
$(eval $(call REGISTER_VLIW_SEED,$(VLIW_TRANSFORM_ASM_DIR)/arm_cfft_radix8_f32_vliw.S,$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_cfft_radix8_f32.c,rfft2048_f32 dct4_2048_f32))
$(eval $(call REGISTER_VLIW_SEED,$(VLIW_TRANSFORM_ASM_DIR)/arm_rfft_fast_f32_vliw.S,$(CMSIS_LIB_DIR)/src/TransformFunctions/arm_rfft_fast_f32.c,rfft512_f32 rfft2048_f32 dct4_512_f32 dct4_2048_f32))
