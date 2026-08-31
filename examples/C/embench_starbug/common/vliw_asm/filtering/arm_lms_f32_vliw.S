# ==============================================================================
# SECTION: LMS Output, Error, And Coefficient Update
# FREQUENCY: Once per arm_lms_f32 call
# BIG-O: O(blockSize * numTaps)
# PURPOSE: Push the new input block into state, compute the filter output and
#          error against the reference stream, then adapt each coefficient with
#          the mu * error * state update across unrolled tap loops.
# ==============================================================================
# SOURCE: arm_lms_f32.c
# BENCHMARKS: lms_f32_taps256_n1 lms_f32_taps256_n128

	.file	"arm_lms_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_lms_f32
	.type	arm_lms_f32, @function
arm_lms_f32:
	# Initialize state, coefficient, and adaptation pointers for the block run.
	# BIG-O: O(1)
	lhu	t3,0(a0)
	lw	t2,4(a0)
	addi	sp,sp,-16
	slli	a6,t3,2
	sw	s0,12(sp)
	addi	t0,a6,-4
	lw	s0,8(a0)
	flw	fa0,12(a0)
	add	t5,t2,t0
	beq	a5,zero,.L10
	sw	s1,8(sp)
	sw	s2,4(sp)
	mv	t0,a5
	mv	t6,t2
.L6:
	# Outer block loop: append one input, produce one output/error pair, then adapt.
	# BIG-O: O(blockSize), with O(numTaps) work inside each iteration

	c.li x0,4
	flw	fa5,0(a1)
	addi	a1,a1,4
	addi	t5,t5,4
	mv	a6,t6

	c.li x0,4
	fsw	fa5,-4(t5)
	addi	a2,a2,4
	addi	a3,a3,4
	addi	a4,a4,4
	
	addi	t6,t6,4
	beq	t3,zero,.L3

	c.li x0,4
	li	s1,1
	andi	t4,t3,7
	fmv.s.x	fa4,zero
	mv	t1,t3

	c.li x0,4
	li	s1,2
	mv	a0,s0
	mv	a7,a6
	addi	s2,t3,-1

	beq	t4,zero,.L4
	beq	t4,s1,.L79
	beq	t4,s1,.L80
	li	s1,3
	beq	t4,s1,.L81
	li	s1,4
	beq	t4,s1,.L82
	li	s1,5
	beq	t4,s1,.L83
	li	s1,6
	beq	t4,s1,.L84
	# Consume the 1..7 tap remainder before the unrolled dot-product loop.
	# BIG-O: O(1) per output sample
	flw	fa3,0(a6)

	c.li x0,4
	flw	ft1,0(s0)
	addi	a7,a6,4
	addi	a0,s0,4
	mv	t1,s2

	fmadd.s	fa4,fa3,ft1,fa4
.L84:
	flw	ft2,0(a7)
	flw	ft3,0(a0)

	c.li x0,4
	addi	a7,a7,4
	addi	a0,a0,4
	fmadd.s	fa4,ft2,ft3,fa4
	addi	t1,t1,-1
.L83:
	flw	ft4,0(a7)
	flw	ft5,0(a0)

	c.li x0,4
	addi	a7,a7,4
	addi	a0,a0,4
	fmadd.s	fa4,ft4,ft5,fa4
	addi	t1,t1,-1
.L82:
	flw	ft6,0(a7)
	flw	ft7,0(a0)

	c.li x0,4
	addi	a7,a7,4
	addi	a0,a0,4
	fmadd.s	fa4,ft6,ft7,fa4
	addi	t1,t1,-1
.L81:
	flw	fs0,0(a7)
	flw	fs1,0(a0)

	c.li x0,4
	addi	a7,a7,4
	addi	a0,a0,4
	fmadd.s	fa4,fs0,fs1,fa4
	addi	t1,t1,-1
.L80:
	flw	fa1,0(a7)
	flw	fa2,0(a0)

	c.li x0,4
	addi	a7,a7,4
	addi	a0,a0,4
	fmadd.s	fa4,fa1,fa2,fa4
	addi	t1,t1,-1
.L79:
	flw	fa6,0(a7)
	flw	fa7,0(a0)

	c.li x0,4
	addi	t1,t1,-1
	addi	a7,a7,4
	addi	a0,a0,4
	fmadd.s	fa4,fa6,fa7,fa4

	beq	t1,zero,.L104
.L4:
	# Main dot-product loop: accumulate eight taps into the current output.
	# BIG-O: O(numTaps) per output sample; O(blockSize * numTaps) overall
	flw	fs2,0(a7)
	flw	fs3,0(a0)
	flw	fs4,4(a7)

	c.li x0,3
	flw	fs5,4(a0)
	addi	t1,t1,-8
	fmadd.s	fs6,fs2,fs3,fa4

	c.li x0,2
	flw	fs7,8(a7)
	fmadd.s	fs11,fs4,fs5,fs6

	flw	fs8,8(a0)

	c.li x0,2
	flw	fs9,12(a7)
	fmadd.s	ft0,fs7,fs8,fs11

	flw	fs10,12(a0)

	c.li x0,2
	flw	ft8,16(a7)
	fmadd.s	fa3,fs9,fs10,ft0

	flw	ft9,16(a0)

	c.li x0,2
	flw	ft10,20(a7)
	fmadd.s	ft4,ft8,ft9,fa3

	flw	ft11,20(a0)

	c.li x0,2
	flw	fa5,24(a7)
	fmadd.s	ft5,ft10,ft11,ft4

	flw	ft1,24(a0)

	c.li x0,2
	flw	ft2,28(a7)
	fmadd.s	ft6,fa5,ft1,ft5
	
	flw	ft3,28(a0)

	c.li x0,3
	fmadd.s	fa4,ft2,ft3,ft6
	addi	a7,a7,32
	addi	a0,a0,32

	bne	t1,zero,.L4
.L104:
	# Store the output, form the error term, and derive the adaptation gain.
	# BIG-O: O(1) per output sample
	
	c.li x0,4
	flw	ft7,-4(a2)
	andi	s2,t3,7
	mv	a7,t3
	mv	a0,s0

	c.li x0,3
	fsw	fa4,-4(a3)
	fsub.s	fs0,ft7,fa4
	addi	s1,t3,-1

	c.li x0,2
	fsw	fs0,-4(a4)
	fmul.s	fs1,fa0,fs0

	beq	s2,zero,.L5
	li	t4,1
	beq	s2,t4,.L85
	li	t1,2
	beq	s2,t1,.L86
	li	t4,3
	beq	s2,t4,.L87
	li	t1,4
	beq	s2,t1,.L88
	li	t4,5
	beq	s2,t4,.L89
	li	t1,6
	beq	s2,t1,.L90
	# Consume the 1..7 coefficient-update remainder before the unrolled update loop.
	# BIG-O: O(1) per output sample
	c.li x0,2
	flw	fa1,0(a6)
	mv	a7,s1

	c.li x0,2
	flw	fa2,0(s0)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	fa6,fa1,fs1,fa2
	addi	a0,s0,4

	fsw	fa6,0(s0)
.L90:
	c.li x0,2
	flw	fa7,0(a6)
	addi	a7,a7,-1

	c.li x0,2
	flw	fa4,0(a0)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	fs2,fa7,fs1,fa4
	addi	a0,a0,4

	fsw	fs2,-4(a0)
.L89:
	c.li x0,2
	flw	fs3,0(a6)
	addi	a7,a7,-1

	c.li x0,2
	flw	fs4,0(a0)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	fs5,fs3,fs1,fs4
	addi	a0,a0,4

	fsw	fs5,-4(a0)
.L88:
	c.li x0,2
	flw	fs6,0(a6)
	addi	a7,a7,-1

	c.li x0,2
	flw	fs7,0(a0)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	fs8,fs6,fs1,fs7
	addi	a0,a0,4

	fsw	fs8,-4(a0)
.L87:
	c.li x0,2
	flw	fs9,0(a6)
	addi	a7,a7,-1

	c.li x0,2
	flw	fs10,0(a0)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	fs11,fs9,fs1,fs10
	addi	a0,a0,4

	fsw	fs11,-4(a0)
.L86:
	c.li x0,2
	flw	ft8,0(a6)
	addi	a7,a7,-1

	c.li x0,2
	flw	ft9,0(a0)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	ft10,ft8,fs1,ft9
	addi	a0,a0,4

	fsw	ft10,-4(a0)
.L85:
	c.li x0,2
	flw	ft0,0(a0)
	addi	a7,a7,-1

	c.li x0,2
	flw	ft11,0(a6)
	addi	a6,a6,4

	c.li x0,2
	fmadd.s	fa5,ft11,fs1,ft0
	addi	a0,a0,4

	fsw	fa5,-4(a0)
	beq	a7,zero,.L9
.L5:
	# Main coefficient-update loop: adapt eight taps with mu * error * state.
	# BIG-O: O(numTaps) per output sample; O(blockSize * numTaps) overall
	flw	ft1,0(a6)
	flw	fa3,0(a0)

	c.li x0,2
	flw	ft3,4(a0)
	fmadd.s	ft4,ft1,fs1,fa3

	flw	fa1,4(a6)

	c.li x0,3
	flw	ft2,8(a0)
	addi	a6,a6,32
	fmadd.s	fa6,fa1,fs1,ft3

	flw	fa7,-24(a6)
	flw	ft5,12(a0)
	flw	ft6,16(a0)
	flw	ft7,20(a0)
	flw	fs0,24(a0)
	fsw	ft4,0(a0)
	flw	fa2,28(a0)

	c.li x0,4
	flw	fs2,-20(a6)
	addi	a0,a0,32
	addi	a7,a7,-8
	fmadd.s	fa4,fa7,fs1,ft2

	fsw	fa6,-28(a0)
	fmadd.s	fs3,fs2,fs1,ft5

	flw	fs4,-16(a6)
	fsw	fa4,-24(a0)


	c.li x0,2
	fsw	fs3,-20(a0)
	fmadd.s	fs5,fs4,fs1,ft6

	flw	fs6,-12(a6)

	c.li x0,2
	fsw	fs5,-16(a0)
	fmadd.s	fs7,fs6,fs1,ft7


	flw	fs8,-8(a6)

	c.li x0,2
	fsw	fs7,-12(a0)
	fmadd.s	fs9,fs8,fs1,fs0

	flw	fs10,-4(a6)

	c.li x0,2
	fsw	fs9,-8(a0)
	fmadd.s	fs11,fs10,fs1,fa2

	fsw	fs11,-4(a0)
	bne	a7,zero,.L5
.L9:
	# Advance to the next block element after output, error, and update complete.
	# BIG-O: O(1) per output sample
	addi	t0,t0,-1
	bne	t0,zero,.L6
.L108:
	# Restore saved registers and set up the trailing state-compaction pass.
	# BIG-O: O(1)
	lw	s1,8(sp)
	lw	s2,4(sp)
	slli	a5,a5,2
	add	t1,t2,a5
.L2:
	# Dispatch the trailing state copy that preserves numTaps - 1 history values.
	# BIG-O: O(numTaps)
	addi	a4,t3,-1
	beq	a4,zero,.L1
	andi	a3,a4,7
	beq	a3,zero,.L7
	li	a2,1
	beq	a3,a2,.L92
	li	a1,2
	beq	a3,a1,.L93
	li	s0,3
	beq	a3,s0,.L94
	li	t5,4
	beq	a3,t5,.L95
	li	t6,5
	beq	a3,t6,.L96
	li	t4,6
	bne	a3,t4,.L107
.L97:
	# Copy the short state remainder one sample at a time.
	# BIG-O: O(1)
	c.li x0,2
	flw	fs1,0(t1)
	addi	a4,a4,-1
	
	c.li x0,2
	fsw	fs1,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
.L96:
	c.li x0,2
	flw	ft8,0(t1)
	addi	a4,a4,-1

	c.li x0,2
	fsw	ft8,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
.L95:
	c.li x0,2
	flw	ft9,0(t1)
	addi	a4,a4,-1

	c.li x0,2
	fsw	ft9,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
.L94:
	c.li x0,2
	flw	ft10,0(t1)
	addi	a4,a4,-1

	c.li x0,2
	fsw	ft10,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
.L93:
	c.li x0,2
	flw	ft11,0(t1)
	addi	a4,a4,-1
	
	c.li x0,2
	fsw	ft11,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
.L92:
	c.li x0,2
	flw	ft0,0(t1)
	addi	a4,a4,-1

	c.li x0,2
	fsw	ft0,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
	beq	a4,zero,.L1
.L7:
	# Main state-compaction loop: move eight preserved history samples per trip.
	# BIG-O: O(numTaps)
	c.li x0,2
	flw	fa5,0(t1)
	addi	t2,t2,32

	c.li x0,3
	fsw	fa5,-32(t2)
	addi	t1,t1,32
	addi	a4,a4,-8

	flw	ft1,-28(t1)
	fsw	ft1,-28(t2)
	flw	fa3,-24(t1)
	fsw	fa3,-24(t2)
	flw	ft3,-20(t1)
	fsw	ft3,-20(t2)
	flw	ft2,-16(t1)
	fsw	ft2,-16(t2)
	flw	ft4,-12(t1)
	fsw	ft4,-12(t2)
	flw	ft5,-8(t1)
	fsw	ft5,-8(t2)
	flw	ft6,-4(t1)
	fsw	ft6,-4(t2)
	bne	a4,zero,.L7
.L1:
	# Final exit after state compaction completes.
	# BIG-O: O(1)
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
.L3:
	# Zero-tap path forwards the reference sample into the error buffer unchanged.
	# BIG-O: O(blockSize)
	sw	zero,-4(a3)

	c.li x0,2
	flw	ft0,-4(a2)
	addi	t0,t0,-1

	fsw	ft0,-4(a4)
	bne	t0,zero,.L6
	j	.L108
.L107:
	c.li x0,2
	flw	fa0,0(t1)
	addi	a4,t3,-2

	c.li x0,2
	fsw	fa0,0(t2)
	addi	t1,t1,4

	addi	t2,t2,4
	j	.L97
.L10:
	# Zero-length block skips directly to the state-compaction bookkeeping.
	# BIG-O: O(1)
	mv	t1,t2
	j	.L2
	.size	arm_lms_f32, .-arm_lms_f32
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
