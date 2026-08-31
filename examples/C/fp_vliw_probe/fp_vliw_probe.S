    .option rvc

    # ------------------------------------------------------------------
    # Data
    # ------------------------------------------------------------------

    .section .rodata
    .align 2
fp_probe_values:
    .word 0x3f800000
    .word 0x40000000
    .word 0x40800000

    .section .bss
    .align 2
fp_probe_scratch:
    .word 0

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    .section .text
    .align 2

    .macro BEGIN_FN name
    .globl \name
    .type \name, @function
\name:
    .endm

    .macro END_FN name
    .size \name, .-\name
    .endm

    .macro LOAD_1_2_4
    la t0, fp_probe_values
    flw ft0, 0(t0)
    flw ft1, 4(t0)
    flw ft3, 8(t0)
    .endm

    .macro CLEAR_SCRATCH
    la t4, fp_probe_scratch
    sw zero, 0(t4)
    .endm

    .macro DRAIN_PIPE
    nop
    nop
    nop
    nop
    .endm

    .macro DRAIN_LONG
    DRAIN_PIPE
    DRAIN_PIPE
    DRAIN_PIPE
    DRAIN_PIPE
    .endm

    .macro RET_FREG freg
    fmv.x.w a0, \freg
    ret
    .endm

    # ------------------------------------------------------------------
    # Baselines
    # ------------------------------------------------------------------

BEGIN_FN scalar_fadd_baseline
    LOAD_1_2_4
    fadd.s ft2, ft0, ft1
    RET_FREG ft2
END_FN scalar_fadd_baseline

BEGIN_FN scalar_fmul_baseline
    LOAD_1_2_4
    fmul.s ft2, ft1, ft3
    RET_FREG ft2
END_FN scalar_fmul_baseline

    # ------------------------------------------------------------------
    # Integer bundles followed by scalar FP
    # ------------------------------------------------------------------

BEGIN_FN bundle_int_then_scalar_fadd
    LOAD_1_2_4
    c.li x0, 3
    addi t1, zero, 1
    addi t2, zero, 2
    addi t3, zero, 3
    fadd.s ft2, ft0, ft1
    RET_FREG ft2
END_FN bundle_int_then_scalar_fadd

BEGIN_FN bundle_int_then_scalar_fmul
    LOAD_1_2_4
    c.li x0, 3
    addi t1, zero, 1
    addi t2, zero, 2
    addi t3, zero, 3
    fmul.s ft2, ft1, ft3
    RET_FREG ft2
END_FN bundle_int_then_scalar_fmul

    # ------------------------------------------------------------------
    # Single FP ops in hinted slots
    # ------------------------------------------------------------------

BEGIN_FN slot0_fadd_hint_relaxed
    LOAD_1_2_4
    c.li x0, 1
    fadd.s ft2, ft0, ft1
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot0_fadd_hint_relaxed

BEGIN_FN slot1_fadd_hint_relaxed
    LOAD_1_2_4
    c.li x0, 2
    addi t1, zero, 1
    fadd.s ft2, ft0, ft1
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot1_fadd_hint_relaxed

BEGIN_FN slot2_fadd_hint_relaxed
    LOAD_1_2_4
    c.li x0, 3
    addi t1, zero, 1
    addi t2, zero, 2
    fadd.s ft2, ft0, ft1
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot2_fadd_hint_relaxed

BEGIN_FN slot0_fmul_hint_relaxed
    LOAD_1_2_4
    c.li x0, 1
    fmul.s ft2, ft1, ft3
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot0_fmul_hint_relaxed

BEGIN_FN slot1_fmul_hint_relaxed
    LOAD_1_2_4
    c.li x0, 2
    addi t1, zero, 1
    fmul.s ft2, ft1, ft3
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot1_fmul_hint_relaxed

BEGIN_FN slot2_fmul_hint_relaxed
    LOAD_1_2_4
    c.li x0, 3
    addi t1, zero, 1
    addi t2, zero, 2
    fmul.s ft2, ft1, ft3
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot2_fmul_hint_relaxed

    # ------------------------------------------------------------------
    # Two FP ops in one bundle
    # ------------------------------------------------------------------

BEGIN_FN dual_fp_slot0_fadd_slot1_fmul_ret_slot0
    LOAD_1_2_4
    c.li x0, 2
    fadd.s ft2, ft0, ft1
    fmul.s ft4, ft1, ft3
    DRAIN_PIPE
    RET_FREG ft2
END_FN dual_fp_slot0_fadd_slot1_fmul_ret_slot0

BEGIN_FN dual_fp_slot0_fadd_slot1_fmul_ret_slot1
    LOAD_1_2_4
    c.li x0, 2
    fadd.s ft2, ft0, ft1
    fmul.s ft4, ft1, ft3
    DRAIN_PIPE
    RET_FREG ft4
END_FN dual_fp_slot0_fadd_slot1_fmul_ret_slot1

    # ------------------------------------------------------------------
    # Mixed fsw + FP compute bundles
    # ------------------------------------------------------------------

BEGIN_FN slot0_fsw_slot1_fadd_store
    LOAD_1_2_4
    CLEAR_SCRATCH
    c.li x0, 2
    fsw ft3, 0(t4)
    fadd.s ft2, ft0, ft1
    DRAIN_PIPE
    lw a0, 0(t4)
    ret
END_FN slot0_fsw_slot1_fadd_store

BEGIN_FN slot0_fsw_slot1_fadd_result
    LOAD_1_2_4
    CLEAR_SCRATCH
    c.li x0, 2
    fsw ft3, 0(t4)
    fadd.s ft2, ft0, ft1
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot0_fsw_slot1_fadd_result

BEGIN_FN slot0_fsw_slot1_fmul_store
    LOAD_1_2_4
    CLEAR_SCRATCH
    c.li x0, 2
    fsw ft3, 0(t4)
    fmul.s ft2, ft1, ft3
    DRAIN_PIPE
    lw a0, 0(t4)
    ret
END_FN slot0_fsw_slot1_fmul_store

BEGIN_FN slot0_fsw_slot1_fmul_result
    LOAD_1_2_4
    CLEAR_SCRATCH
    c.li x0, 2
    fsw ft3, 0(t4)
    fmul.s ft2, ft1, ft3
    DRAIN_PIPE
    RET_FREG ft2
END_FN slot0_fsw_slot1_fmul_result

    # ------------------------------------------------------------------
    # FP dependency chains
    # ------------------------------------------------------------------

BEGIN_FN slot1_fadd_then_scalar_fadd_nogap
    LOAD_1_2_4
    c.li x0, 2
    addi t1, zero, 1
    fadd.s ft2, ft0, ft1
    fadd.s ft4, ft2, ft3
    DRAIN_PIPE
    RET_FREG ft4
END_FN slot1_fadd_then_scalar_fadd_nogap

BEGIN_FN slot1_fmul_then_scalar_fadd_nogap
    LOAD_1_2_4
    c.li x0, 2
    addi t1, zero, 1
    fmul.s ft2, ft1, ft3
    fadd.s ft4, ft2, ft0
    DRAIN_PIPE
    RET_FREG ft4
END_FN slot1_fmul_then_scalar_fadd_nogap

BEGIN_FN two_bundle_fadd_chain
    LOAD_1_2_4
    c.li x0, 2
    addi t1, zero, 1
    fadd.s ft2, ft0, ft1
    c.li x0, 2
    addi t2, zero, 2
    fadd.s ft4, ft2, ft3
    DRAIN_PIPE
    RET_FREG ft4
END_FN two_bundle_fadd_chain

BEGIN_FN two_bundle_fmul_chain
    LOAD_1_2_4
    c.li x0, 2
    addi t1, zero, 1
    fmul.s ft2, ft1, ft3
    c.li x0, 2
    addi t2, zero, 2
    fadd.s ft4, ft2, ft0
    DRAIN_PIPE
    RET_FREG ft4
END_FN two_bundle_fmul_chain

    # ------------------------------------------------------------------
    # Benchmark-shaped cases
    # ------------------------------------------------------------------

    .section .rodata
    .align 2
mult_src_a16:
    .float 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
    .float 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0
mult_src_b16:
    .float 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
    .float 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
mult_expected16:
    .float 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0
    .float 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0

    .section .bss
    .align 2
mult_dst16:
    .space 64
bundle_store_window:
    .space 64

    .section .text
    .align 2

check_words:
    li t0, 0
1:
    beq t0, a2, 3f
    lw t1, 0(a0)
    lw t2, 0(a1)
    bne t1, t2, 2f
    addi a0, a0, 4
    addi a1, a1, 4
    addi t0, t0, 1
    j 1b
2:
    addi a0, t0, 1
    ret
3:
    li a0, 0
    ret

BEGIN_FN fp_load_base_from_bundled_addi_highreg
    la a0, mult_src_a16
    c.li x0, 3
    addi a0, a0, 32
    addi t1, zero, 1
    addi t2, zero, 2
    flw f24, -28(a0)
    fmv.x.w a0, f24
    ret
END_FN fp_load_base_from_bundled_addi_highreg

BEGIN_FN fp_store_prev_result_in_hinted_bundle_highreg
    CLEAR_SCRATCH
    la t0, mult_src_a16
    flw f21, 0(t0)
    flw f22, 4(t0)
    fmul.s f23, f21, f22
    c.li x0, 2
    fsw f23, 0(t4)
    fadd.s f24, f21, f21
    DRAIN_PIPE
    lw a0, 0(t4)
    ret
END_FN fp_store_prev_result_in_hinted_bundle_highreg

BEGIN_FN bundle_slot2_counter_fp_gap_value
    la a0, mult_src_a16
    la a1, mult_src_b16
    li a2, 0
    li a3, 8
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    fmul.s ft9, fs11, ft8
    DRAIN_PIPE
    add a0, a3, zero
    ret
END_FN bundle_slot2_counter_fp_gap_value

BEGIN_FN bundle_slot1_fp_store_base_window_flags
    la t0, bundle_store_window
    sw zero, 0(t0)
    sw zero, 4(t0)
    sw zero, 8(t0)
    sw zero, 12(t0)
    sw zero, 16(t0)
    sw zero, 20(t0)
    sw zero, 24(t0)
    sw zero, 28(t0)
    sw zero, 32(t0)
    sw zero, 36(t0)
    sw zero, 40(t0)
    sw zero, 44(t0)
    sw zero, 48(t0)
    sw zero, 52(t0)
    sw zero, 56(t0)
    sw zero, 60(t0)
    la a0, mult_src_a16
    la a1, mult_src_b16
    addi a2, t0, 32
    li a3, 8
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fsw fs7, -32(a2)
    li a0, 0
    lw t1, 0(t0)
    beq t1, zero, 1f
    addi a0, a0, 1
1:
    lw t1, 32(t0)
    beq t1, zero, 2f
    addi a0, a0, 2
2:
    ret
END_FN bundle_slot1_fp_store_base_window_flags

BEGIN_FN arm_mult_style8_scalarized_exact
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 8
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 8
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style8_scalarized_exact

BEGIN_FN arm_mult_style8_addi_hint_only
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 8
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 8
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style8_addi_hint_only

BEGIN_FN arm_mult_style8_store_hint_only
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 8
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    c.li x0, 2
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    c.li x0, 2
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    c.li x0, 2
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    c.li x0, 2
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    c.li x0, 2
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    c.li x0, 2
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    c.li x0, 2
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 8
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style8_store_hint_only

BEGIN_FN arm_mult_style8_all_hints
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 8
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    c.li x0, 2
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    c.li x0, 2
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    c.li x0, 2
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    c.li x0, 2
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    c.li x0, 2
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    c.li x0, 2
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    c.li x0, 2
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 8
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style8_all_hints

BEGIN_FN bundle_slot2_counter_fp_gap_value_drained
    la a0, mult_src_a16
    la a1, mult_src_b16
    li a2, 0
    li a3, 8
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    fmul.s ft9, fs11, ft8
    DRAIN_LONG
    add a0, a3, zero
    ret
END_FN bundle_slot2_counter_fp_gap_value_drained

BEGIN_FN bundle_slot1_fp_store_base_window_flags_drained
    la t0, bundle_store_window
    sw zero, 0(t0)
    sw zero, 4(t0)
    sw zero, 8(t0)
    sw zero, 12(t0)
    sw zero, 16(t0)
    sw zero, 20(t0)
    sw zero, 24(t0)
    sw zero, 28(t0)
    sw zero, 32(t0)
    sw zero, 36(t0)
    sw zero, 40(t0)
    sw zero, 44(t0)
    sw zero, 48(t0)
    sw zero, 52(t0)
    sw zero, 56(t0)
    sw zero, 60(t0)
    la a0, mult_src_a16
    la a1, mult_src_b16
    addi a2, t0, 32
    li a3, 8
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fsw fs7, -32(a2)
    DRAIN_LONG
    li a0, 0
    lw t1, 0(t0)
    beq t1, zero, 1f
    addi a0, a0, 1
1:
    lw t1, 32(t0)
    beq t1, zero, 2f
    addi a0, a0, 2
2:
    ret
END_FN bundle_slot1_fp_store_base_window_flags_drained

BEGIN_FN arm_mult_style8_store_hint_only_shifted
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 8
    c.nop
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    c.li x0, 2
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    c.li x0, 2
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    c.li x0, 2
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    c.li x0, 2
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    c.li x0, 2
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    c.li x0, 2
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    c.li x0, 2
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 8
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style8_store_hint_only_shifted

BEGIN_FN bundle_slot1_a2_readback_drained
    la t0, bundle_store_window
    la a0, mult_src_a16
    la a1, mult_src_b16
    addi a2, t0, 32
    li a3, 8
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fmul.s fs10, fs8, fs9
    DRAIN_LONG
    sub a0, a2, t0
    ret
END_FN bundle_slot1_a2_readback_drained

BEGIN_FN arm_mult_style8_addi_hint_only_shifted
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 8
    c.nop
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 8
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style8_addi_hint_only_shifted

BEGIN_FN bundle_slot1_a2_visible_same_gap
    la t0, bundle_store_window
    la a0, mult_src_a16
    la a1, mult_src_b16
    addi a2, t0, 32
    li a3, 8
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    sub a0, a2, t0
    ret
END_FN bundle_slot1_a2_visible_same_gap

BEGIN_FN bundle_slot1_int_store_base_window_flags_drained
    la t0, bundle_store_window
    sw zero, 0(t0)
    sw zero, 4(t0)
    sw zero, 8(t0)
    sw zero, 12(t0)
    sw zero, 16(t0)
    sw zero, 20(t0)
    sw zero, 24(t0)
    sw zero, 28(t0)
    sw zero, 32(t0)
    sw zero, 36(t0)
    sw zero, 40(t0)
    sw zero, 44(t0)
    sw zero, 48(t0)
    sw zero, 52(t0)
    sw zero, 56(t0)
    sw zero, 60(t0)
    la a0, mult_src_a16
    la a1, mult_src_b16
    addi a2, t0, 32
    li a3, 8
    li t2, 1
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    sw t2, -32(a2)
    DRAIN_LONG
    li a0, 0
    lw t1, 0(t0)
    beq t1, zero, 1f
    addi a0, a0, 1
1:
    lw t1, 32(t0)
    beq t1, zero, 2f
    addi a0, a0, 2
2:
    ret
END_FN bundle_slot1_int_store_base_window_flags_drained

BEGIN_FN bundle_int_3wide_lane_mask
    li t1, 0
    li t2, 0
    li t3, 0
    c.li x0, 3
    addi t1, zero, 1
    addi t2, zero, 2
    addi t3, zero, 4
    DRAIN_LONG
    li a0, 0
    li t0, 1
    bne t1, t0, 1f
    addi a0, a0, 1
1:
    li t0, 2
    bne t2, t0, 2f
    addi a0, a0, 2
2:
    li t0, 4
    bne t3, t0, 3f
    addi a0, a0, 4
3:
    ret
END_FN bundle_int_3wide_lane_mask

BEGIN_FN arm_mult_style16_scalarized_exact
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 16
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 16
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style16_scalarized_exact

BEGIN_FN arm_mult_style16_all_hints
    la a0, mult_src_a16
    la a1, mult_src_b16
    la a2, mult_dst16
    li a3, 16
1:
    flw fs5, 0(a0)
    flw fs6, 0(a1)
    c.li x0, 3
    addi a0, a0, 32
    addi a2, a2, 32
    addi a3, a3, -8
    flw fs8, -28(a0)
    addi a1, a1, 32
    fmul.s fs7, fs5, fs6
    flw fs9, -28(a1)
    c.li x0, 2
    fsw fs7, -32(a2)
    fmul.s fs10, fs8, fs9
    flw fs11, -24(a0)
    flw ft8, -24(a1)
    c.li x0, 2
    fsw fs10, -28(a2)
    fmul.s ft9, fs11, ft8
    flw ft10, -20(a0)
    flw ft11, -20(a1)
    c.li x0, 2
    fsw ft9, -24(a2)
    fmul.s fa5, ft10, ft11
    flw ft0, -16(a0)
    flw fa4, -16(a1)
    c.li x0, 2
    fsw fa5, -20(a2)
    fmul.s ft1, ft0, fa4
    flw ft2, -12(a0)
    flw ft3, -12(a1)
    c.li x0, 2
    fsw ft1, -16(a2)
    fmul.s ft4, ft2, ft3
    flw ft5, -8(a0)
    flw ft6, -8(a1)
    c.li x0, 2
    fsw ft4, -12(a2)
    fmul.s ft7, ft5, ft6
    flw fs0, -4(a0)
    flw fs1, -4(a1)
    c.li x0, 2
    fsw ft7, -8(a2)
    fmul.s fa0, fs0, fs1
    fsw fa0, -4(a2)
    bne a3, zero, 1b
    la a0, mult_dst16
    la a1, mult_expected16
    li a2, 16
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, check_words
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
END_FN arm_mult_style16_all_hints

    .section .note.GNU-stack,"",@progbits
