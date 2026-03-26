    .option rvc

    .section .bss
    .align 2
probe_word:
    .word 0
probe_pair:
    .word 0
    .word 0
probe_triplet:
    .word 0
    .word 0
    .word 0

    .section .text
    .align 2

    .globl pre_slot0_store_no_gap
    .type pre_slot0_store_no_gap, @function
pre_slot0_store_no_gap:
    la t1, probe_word
    sw zero, 0(t1)
    li t0, 9
    li t2, 6
    add t3, t0, t2
    c.li x0, 3
    sw t3, 0(t1)
    add t5, zero, zero
    add t6, zero, zero
    lw a0, 0(t1)
    ret

    .globl pre_slot0_store_gap_before_hint
    .type pre_slot0_store_gap_before_hint, @function
pre_slot0_store_gap_before_hint:
    la t1, probe_word
    sw zero, 0(t1)
    li t0, 9
    li t2, 6
    add t3, t0, t2
    c.nop
    c.li x0, 3
    sw t3, 0(t1)
    add t5, zero, zero
    add t6, zero, zero
    lw a0, 0(t1)
    ret

    .globl pre_slot0_rs1_no_gap
    .type pre_slot0_rs1_no_gap, @function
pre_slot0_rs1_no_gap:
    li t0, 9
    li t2, 6
    add t3, t0, t2
    c.li x0, 3
    addi a0, t3, 4
    add t5, zero, zero
    add t6, zero, zero
    ret

    .globl pre_slot0_rs1_gap_before_hint
    .type pre_slot0_rs1_gap_before_hint, @function
pre_slot0_rs1_gap_before_hint:
    li t0, 9
    li t2, 6
    add t3, t0, t2
    c.nop
    c.li x0, 3
    addi a0, t3, 4
    add t5, zero, zero
    add t6, zero, zero
    ret

    .globl pre_slot0_rs2_no_gap
    .type pre_slot0_rs2_no_gap, @function
pre_slot0_rs2_no_gap:
    li t0, 9
    li t2, 6
    li t4, 20
    add t3, t0, t2
    c.li x0, 3
    sub a0, t4, t3
    add t5, zero, zero
    add t6, zero, zero
    ret

    .globl pre_slot0_rs2_gap_before_hint
    .type pre_slot0_rs2_gap_before_hint, @function
pre_slot0_rs2_gap_before_hint:
    li t0, 9
    li t2, 6
    li t4, 20
    add t3, t0, t2
    c.nop
    c.li x0, 3
    sub a0, t4, t3
    add t5, zero, zero
    add t6, zero, zero
    ret

    .globl pre_slot0_store_chain_no_gap
    .type pre_slot0_store_chain_no_gap, @function
pre_slot0_store_chain_no_gap:
    la t0, probe_word
    sw zero, 0(t0)
    li a5, 1
    li a6, 2
    li a2, 4
    li t4, 40
    or a0, a5, a6
    add a1, a2, a0
    sub a3, t4, a1
    c.li x0, 3
    sw a3, 0(t0)
    add t5, zero, zero
    add t6, zero, zero
    lw a0, 0(t0)
    ret

    .globl pre_slot0_store_chain_gap_before_hint
    .type pre_slot0_store_chain_gap_before_hint, @function
pre_slot0_store_chain_gap_before_hint:
    la t0, probe_word
    sw zero, 0(t0)
    li a5, 1
    li a6, 2
    li a2, 4
    li t4, 40
    or a0, a5, a6
    add a1, a2, a0
    sub a3, t4, a1
    c.nop
    c.li x0, 3
    sw a3, 0(t0)
    add t5, zero, zero
    add t6, zero, zero
    lw a0, 0(t0)
    ret

    .globl slot1_to_scalar_rs1_no_gap
    .type slot1_to_scalar_rs1_no_gap, @function
slot1_to_scalar_rs1_no_gap:
    c.li x0, 3
    addi t5, zero, 1
    addi t3, zero, 15
    addi t6, zero, 2
    addi a0, t3, 4
    ret

    .globl slot1_to_scalar_rs1_gap_after_bundle
    .type slot1_to_scalar_rs1_gap_after_bundle, @function
slot1_to_scalar_rs1_gap_after_bundle:
    c.li x0, 3
    addi t5, zero, 1
    addi t3, zero, 15
    addi t6, zero, 2
    c.nop
    addi a0, t3, 4
    ret

    .globl lane1_to_scalar_rs1_regreg_no_gap
    .type lane1_to_scalar_rs1_regreg_no_gap, @function
lane1_to_scalar_rs1_regreg_no_gap:
    c.li x0, 3
    addi t5, zero, 1
    addi a3, zero, 13
    addi t6, zero, 2
    add a0, a3, zero
    ret

    .globl lane1_to_scalar_rs1_regreg_gap_after_bundle
    .type lane1_to_scalar_rs1_regreg_gap_after_bundle, @function
lane1_to_scalar_rs1_regreg_gap_after_bundle:
    c.li x0, 3
    addi t5, zero, 1
    addi a3, zero, 13
    addi t6, zero, 2
    c.nop
    add a0, a3, zero
    ret

    .globl lane1_to_scalar_rs2_regreg_no_gap
    .type lane1_to_scalar_rs2_regreg_no_gap, @function
lane1_to_scalar_rs2_regreg_no_gap:
    c.li x0, 3
    addi t5, zero, 1
    addi a3, zero, 13
    addi t6, zero, 2
    add a0, zero, a3
    ret

    .globl lane1_to_scalar_rs2_regreg_gap_after_bundle
    .type lane1_to_scalar_rs2_regreg_gap_after_bundle, @function
lane1_to_scalar_rs2_regreg_gap_after_bundle:
    c.li x0, 3
    addi t5, zero, 1
    addi a3, zero, 13
    addi t6, zero, 2
    c.nop
    add a0, zero, a3
    ret

    .globl slot2_to_scalar_store_no_gap
    .type slot2_to_scalar_store_no_gap, @function
slot2_to_scalar_store_no_gap:
    la t1, probe_word
    sw zero, 0(t1)
    c.li x0, 3
    addi t5, zero, 1
    addi t6, zero, 2
    addi t3, zero, 15
    sw t3, 0(t1)
    lw a0, 0(t1)
    ret

    .globl slot2_to_scalar_store_gap_after_bundle
    .type slot2_to_scalar_store_gap_after_bundle, @function
slot2_to_scalar_store_gap_after_bundle:
    la t1, probe_word
    sw zero, 0(t1)
    c.li x0, 3
    addi t5, zero, 1
    addi t6, zero, 2
    addi t3, zero, 15
    c.nop
    sw t3, 0(t1)
    lw a0, 0(t1)
    ret

    .globl lane2_to_scalar_rs1_regreg_no_gap
    .type lane2_to_scalar_rs1_regreg_no_gap, @function
lane2_to_scalar_rs1_regreg_no_gap:
    li t2, 10
    li a1, 5
    c.li x0, 3
    add t5, zero, zero
    add t3, zero, zero
    sub t6, t2, a1
    add a0, t6, zero
    ret

    .globl lane2_to_scalar_rs1_regreg_gap_after_bundle
    .type lane2_to_scalar_rs1_regreg_gap_after_bundle, @function
lane2_to_scalar_rs1_regreg_gap_after_bundle:
    li t2, 10
    li a1, 5
    c.li x0, 3
    add t5, zero, zero
    add t3, zero, zero
    sub t6, t2, a1
    c.nop
    add a0, t6, zero
    ret

    .globl lane2_to_scalar_rs2_regreg_no_gap
    .type lane2_to_scalar_rs2_regreg_no_gap, @function
lane2_to_scalar_rs2_regreg_no_gap:
    li t2, 10
    li a1, 5
    c.li x0, 3
    add t5, zero, zero
    add t3, zero, zero
    sub t6, t2, a1
    add a0, zero, t6
    ret

    .globl lane2_to_scalar_rs2_regreg_gap_after_bundle
    .type lane2_to_scalar_rs2_regreg_gap_after_bundle, @function
lane2_to_scalar_rs2_regreg_gap_after_bundle:
    li t2, 10
    li a1, 5
    c.li x0, 3
    add t5, zero, zero
    add t3, zero, zero
    sub t6, t2, a1
    c.nop
    add a0, zero, t6
    ret

    .globl post_bundle_two_stores_no_gap
    .type post_bundle_two_stores_no_gap, @function
post_bundle_two_stores_no_gap:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li t4, 8
    li a1, 5
    li t2, 10
    c.li x0, 3
    add t5, zero, zero
    add a3, t4, a1
    sub t6, t2, a1
    sw t6, 0(a7)
    sw a3, 4(a7)
    lw t0, 0(a7)
    lw t1, 4(a7)
    slli t1, t1, 8
    or a0, t0, t1
    ret

    .globl post_bundle_two_stores_gap_after_bundle
    .type post_bundle_two_stores_gap_after_bundle, @function
post_bundle_two_stores_gap_after_bundle:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li t4, 8
    li a1, 5
    li t2, 10
    c.li x0, 3
    add t5, zero, zero
    add a3, t4, a1
    sub t6, t2, a1
    c.nop
    sw t6, 0(a7)
    sw a3, 4(a7)
    lw t0, 0(a7)
    lw t1, 4(a7)
    slli t1, t1, 8
    or a0, t0, t1
    ret

    .globl dual_lane_dual_source_no_gap
    .type dual_lane_dual_source_no_gap, @function
dual_lane_dual_source_no_gap:
    li t4, 8
    li a1, 5
    li t2, 10
    c.li x0, 3
    add t5, zero, zero
    add a3, t4, a1
    sub t6, t2, a1
    add a0, a3, t6
    ret

    .globl dual_lane_dual_source_gap_after_bundle
    .type dual_lane_dual_source_gap_after_bundle, @function
dual_lane_dual_source_gap_after_bundle:
    li t4, 8
    li a1, 5
    li t2, 10
    c.li x0, 3
    add t5, zero, zero
    add a3, t4, a1
    sub t6, t2, a1
    c.nop
    add a0, a3, t6
    ret

    .globl triple_store_path_no_gap
    .type triple_store_path_no_gap, @function
triple_store_path_no_gap:
    la a7, probe_triplet
    sw zero, 0(a7)
    sw zero, 4(a7)
    sw zero, 8(a7)
    li a5, 1
    li a6, 2
    li a3, 4
    li t4, 40
    li t2, 8
    li a1, 5
    li t3, 10
    or a0, a5, a6
    add a2, a3, a0
    sub t0, t4, a2
    c.li x0, 3
    sw t0, 4(a7)
    add a3, t2, a1
    sub a6, t3, a1
    sw a6, 0(a7)
    sw a3, 8(a7)
    lw t0, 0(a7)
    lw t1, 4(a7)
    lw t2, 8(a7)
    slli t1, t1, 8
    slli t2, t2, 16
    or a0, t0, t1
    or a0, a0, t2
    ret

    .globl triple_store_path_gap_before_hint
    .type triple_store_path_gap_before_hint, @function
triple_store_path_gap_before_hint:
    la a7, probe_triplet
    sw zero, 0(a7)
    sw zero, 4(a7)
    sw zero, 8(a7)
    li a5, 1
    li a6, 2
    li a3, 4
    li t4, 40
    li t2, 8
    li a1, 5
    li t3, 10
    or a0, a5, a6
    add a2, a3, a0
    sub t0, t4, a2
    c.nop
    c.li x0, 3
    sw t0, 4(a7)
    add a3, t2, a1
    sub a6, t3, a1
    sw a6, 0(a7)
    sw a3, 8(a7)
    lw t0, 0(a7)
    lw t1, 4(a7)
    lw t2, 8(a7)
    slli t1, t1, 8
    slli t2, t2, 16
    or a0, t0, t1
    or a0, a0, t2
    ret

    .globl snippet_shape_no_gap
    .type snippet_shape_no_gap, @function
snippet_shape_no_gap:
    addi sp, sp, -16
    sw s3, 0(sp)
    sw s4, 4(sp)
    sw s8, 8(sp)
    sw s10, 12(sp)
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li a5, 1
    li t6, 2
    li a3, 4
    li s3, 40
    li t4, 8
    li s8, 5
    li t2, 10
    li a1, 5
    li t3, 1
    li s10, 7
    or a0, a5, t6
    add s4, a3, a0
    sub t0, s3, s4
    c.li x0, 3
    sw t0, 4(a7)
    add a3, t4, s8
    sub t6, t2, a1
    sw t6, 0(a7)
    sltu t4, a3, t4
    add t3, t3, s10
    add s3, s4, s3
    add t2, a1, t2
    lw t0, 0(a7)
    lw t1, 4(a7)
    slli t1, t1, 8
    slli a3, a3, 16
    slli t2, t2, 24
    or a0, t0, t1
    or a0, a0, a3
    or a0, a0, t2
    lw s3, 0(sp)
    lw s4, 4(sp)
    lw s8, 8(sp)
    lw s10, 12(sp)
    addi sp, sp, 16
    ret

    .globl snippet_shape_gap_before_hint
    .type snippet_shape_gap_before_hint, @function
snippet_shape_gap_before_hint:
    addi sp, sp, -16
    sw s3, 0(sp)
    sw s4, 4(sp)
    sw s8, 8(sp)
    sw s10, 12(sp)
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li a5, 1
    li t6, 2
    li a3, 4
    li s3, 40
    li t4, 8
    li s8, 5
    li t2, 10
    li a1, 5
    li t3, 1
    li s10, 7
    or a0, a5, t6
    add s4, a3, a0
    sub t0, s3, s4
    c.nop
    c.li x0, 3
    sw t0, 4(a7)
    add a3, t4, s8
    sub t6, t2, a1
    sw t6, 0(a7)
    sltu t4, a3, t4
    add t3, t3, s10
    add s3, s4, s3
    add t2, a1, t2
    lw t0, 0(a7)
    lw t1, 4(a7)
    slli t1, t1, 8
    slli a3, a3, 16
    slli t2, t2, 24
    or a0, t0, t1
    or a0, a0, a3
    or a0, a0, t2
    lw s3, 0(sp)
    lw s4, 4(sp)
    lw s8, 8(sp)
    lw s10, 12(sp)
    addi sp, sp, 16
    ret

    .globl snippet_shape_loop16_no_gap
    .type snippet_shape_loop16_no_gap, @function
snippet_shape_loop16_no_gap:
    addi sp, sp, -16
    sw s3, 0(sp)
    sw s4, 4(sp)
    sw s8, 8(sp)
    sw s10, 12(sp)
    li t5, 16
    li t4, 0
.L_snippet_loop_no_gap:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li a5, 1
    li t6, 2
    li a3, 4
    li s3, 40
    li t3, 8
    li s8, 5
    li t2, 10
    li a1, 5
    li t1, 1
    li s10, 7
    or a0, a5, t6
    add s4, a3, a0
    sub t0, s3, s4
    c.li x0, 3
    sw t0, 4(a7)
    add a3, t3, s8
    sub t6, t2, a1
    sw t6, 0(a7)
    sltu t3, a3, t3
    add t1, t1, s10
    add s3, s4, s3
    add t2, a1, t2
    lw t0, 0(a7)
    lw t6, 4(a7)
    slli t6, t6, 8
    slli a3, a3, 16
    slli t2, t2, 24
    or t0, t0, t6
    or t0, t0, a3
    or t0, t0, t2
    add t4, t4, t0
    addi t5, t5, -1
    bnez t5, .L_snippet_loop_no_gap
    mv a0, t4
    lw s3, 0(sp)
    lw s4, 4(sp)
    lw s8, 8(sp)
    lw s10, 12(sp)
    addi sp, sp, 16
    ret

    .globl snippet_shape_loop16_gap_before_hint
    .type snippet_shape_loop16_gap_before_hint, @function
snippet_shape_loop16_gap_before_hint:
    addi sp, sp, -16
    sw s3, 0(sp)
    sw s4, 4(sp)
    sw s8, 8(sp)
    sw s10, 12(sp)
    li t5, 16
    li t4, 0
.L_snippet_loop_gap_before_hint:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li a5, 1
    li t6, 2
    li a3, 4
    li s3, 40
    li t3, 8
    li s8, 5
    li t2, 10
    li a1, 5
    li t1, 1
    li s10, 7
    or a0, a5, t6
    add s4, a3, a0
    sub t0, s3, s4
    c.nop
    c.li x0, 3
    sw t0, 4(a7)
    add a3, t3, s8
    sub t6, t2, a1
    sw t6, 0(a7)
    sltu t3, a3, t3
    add t1, t1, s10
    add s3, s4, s3
    add t2, a1, t2
    lw t0, 0(a7)
    lw t6, 4(a7)
    slli t6, t6, 8
    slli a3, a3, 16
    slli t2, t2, 24
    or t0, t0, t6
    or t0, t0, a3
    or t0, t0, t2
    add t4, t4, t0
    addi t5, t5, -1
    bnez t5, .L_snippet_loop_gap_before_hint
    mv a0, t4
    lw s3, 0(sp)
    lw s4, 4(sp)
    lw s8, 8(sp)
    lw s10, 12(sp)
    addi sp, sp, 16
    ret

    .globl two_bundle_dual_consumer_hint
    .type two_bundle_dual_consumer_hint, @function
two_bundle_dual_consumer_hint:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li t4, 8
    li a2, 5
    li t2, 10
    li a1, 5
    li t3, 1
    li a4, 7

    nop

    c.li x0, 4
    add t5, zero, zero
    add a3, t4, a2
    sub t6, t2, a1
    add t3, t3, a4

    nop

    c.li x0, 4
    sw t6, 0(a7)
    sltu t4, a3, t4
    add t2, a1, t2
    add t3, t3, zero

    lw t0, 0(a7)
    slli t4, t4, 8
    slli t2, t2, 16
    slli t3, t3, 24
    or a0, t0, t4
    or a0, a0, t2
    or a0, a0, t3
    ret

    .globl two_bundle_dual_consumer_scalarized
    .type two_bundle_dual_consumer_scalarized, @function
two_bundle_dual_consumer_scalarized:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li t4, 8
    li a2, 5
    li t2, 10
    li a1, 5
    li t3, 1
    li a4, 7
    c.li x0, 4
    add t5, zero, zero
    add a3, t4, a2
    sub t6, t2, a1
    add t3, t3, a4
    c.nop
    sw t6, 0(a7)
    sltu t4, a3, t4
    add t2, a1, t2
    add t3, t3, zero
    lw t0, 0(a7)
    slli t4, t4, 8
    slli t2, t2, 16
    slli t3, t3, 24
    or a0, t0, t4
    or a0, a0, t2
    or a0, a0, t3
    ret

    .globl two_bundle_snippet_hint
    .type two_bundle_snippet_hint, @function
two_bundle_snippet_hint:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li a5, 1
    li t6, 2
    li a3, 4
    li t1, 40
    li t4, 8
    li a2, 5
    li t2, 10
    li a1, 5
    li t3, 1
    li a4, 7
    or a0, a5, t6
    add a6, a3, a0
    sub t0, t1, a6

    nop

    c.li x0, 4
    sw t0, 4(a7)
    add a3, t4, a2
    sub t6, t2, a1
    add t3, t3, a4

    nop

    c.li x0, 4
    sw t6, 0(a7)
    sltu t4, a3, t4
    add t1, a6, t1
    add t2, a1, t2

    lw t0, 0(a7)
    lw t5, 4(a7)
    slli t5, t5, 8
    slli t4, t4, 16
    slli t2, t2, 24
    or a0, t0, t5
    or a0, a0, t4
    or a0, a0, t2
    ret

    .globl two_bundle_snippet_scalarized
    .type two_bundle_snippet_scalarized, @function
two_bundle_snippet_scalarized:
    la a7, probe_pair
    sw zero, 0(a7)
    sw zero, 4(a7)
    li a5, 1
    li t6, 2
    li a3, 4
    li t1, 40
    li t4, 8
    li a2, 5
    li t2, 10
    li a1, 5
    li t3, 1
    li a4, 7
    or a0, a5, t6
    add a6, a3, a0
    sub t0, t1, a6
    c.li x0, 4
    sw t0, 4(a7)
    add a3, t4, a2
    sub t6, t2, a1
    add t3, t3, a4
    c.nop
    sw t6, 0(a7)
    sltu t4, a3, t4
    add t1, a6, t1
    add t2, a1, t2
    lw t0, 0(a7)
    lw t5, 4(a7)
    slli t5, t5, 8
    slli t4, t4, 16
    slli t2, t2, 24
    or a0, t0, t5
    or a0, a0, t4
    or a0, a0, t2
    ret

    .globl two_bundle_branch_hint
    .type two_bundle_branch_hint, @function
two_bundle_branch_hint:
    li t4, 8
    li a2, 5
    li t2, 10
    li a1, 5
    li a4, 7

    nop

    c.li x0, 4
    add t5, zero, zero
    add a3, t4, a2
    sub t6, t2, a1
    add t3, zero, a4

    nop

    c.li x0, 4
    add t0, a3, t6
    add t1, t3, zero
    add t2, a1, t2
    add t4, zero, zero
    
    li a0, 0
    li t5, 18
    beq t0, t5, .L_two_bundle_branch_hint_ok
    ret
.L_two_bundle_branch_hint_ok:
    li a0, 18
    ret

    .globl two_bundle_branch_scalarized
    .type two_bundle_branch_scalarized, @function
two_bundle_branch_scalarized:
    li t4, 8
    li a2, 5
    li t2, 10
    li a1, 5
    li a4, 7
    c.li x0, 4
    add t5, zero, zero
    add a3, t4, a2
    sub t6, t2, a1
    add t3, zero, a4
    c.nop
    add t0, a3, t6
    add t1, t3, zero
    add t2, a1, t2
    add t4, zero, zero
    li a0, 0
    li t5, 18
    beq t0, t5, .L_two_bundle_branch_scalarized_ok
    ret
.L_two_bundle_branch_scalarized_ok:
    li a0, 18
    ret

    .section .note.GNU-stack,"",@progbits
