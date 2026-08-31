# ==============================================================================
# SECTION: FIR Accumulate And State Roll Kernel
# FREQUENCY: Once per arm_fir_f32 call
# BIG-O: O(blockSize * numTaps)
# PURPOSE: Append new samples to the state history, accumulate each output as
#          a tap-by-tap dot product with eight-tap unrolling, and compact the
#          trailing state window for the next block.
# ==============================================================================
# SOURCE: arm_fir_f32.c
# BENCHMARKS: fir_f32_taps256_n1 fir_f32_taps256_n128

	.file	"arm_fir_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_fir_f32
	.type	arm_fir_f32, @function
arm_fir_f32:
	# Initialize the tap/state pointers and decide whether there is a block to run.
	# BIG-O: O(1)
	lhu	a7,0(a0)

	c.li x0,2
	lw	t5,4(a0)
	slli	a5,a7,2

	addi	t0,a5,-4
	add	t1,t5,t0
	lw	t0,8(a0)
	beq	a3,zero,.L8

	c.li x0,2
	mv	t3,a3
	mv	t4,t5
.L5:
	# Outer block loop: append one input sample and compute one FIR output.
	# BIG-O: O(blockSize), with O(numTaps) work inside each iteration

	c.li x0,3
	flw	fa5,0(a1)
	addi	a1,a1,4
	addi	t1,t1,4

	fsw	fa5,-4(t1)
	
	beq	a7,zero,.L9

	c.li x0,3
	andi	a6,a7,7
	fmv.s.x	fa6,zero
	mv	a0,a7

	c.li x0,3
	mv	a5,t0
	mv	a4,t4
	addi	t2,a7,-1

	c.li x0,2
	beq	a6,zero,.L4
	li	t6,1

	c.li x0,2
	beq	a6,t6,.L57
	li	t6,2

	c.li x0,2
	beq	a6,t6,.L58
	li	t6,3

	c.li x0,2
	beq	a6,t6,.L59
	li	t6,4

	c.li x0,2
	beq	a6,t6,.L60
	li	t6,5

	c.li x0,2
	beq	a6,t6,.L61
	li	t6,6

	beq	a6,t6,.L62
	# Consume the 1..7 tap remainder before the unrolled dot-product loop.
	# BIG-O: O(1) per output sample
	flw	fa3,0(t4)
	flw	fa4,0(t0)

	c.li x0,4
	addi	a4,t4,4
	addi	a5,t0,4
	fmadd.s	fa6,fa3,fa4,fa6
	mv	a0,t2
.L62:
	flw	ft0,0(a4)
	flw	ft1,0(a5)

	c.li x0,4
	addi	a4,a4,4
	addi	a5,a5,4
	fmadd.s	fa6,ft0,ft1,fa6
	addi	a0,a0,-1
.L61:
	flw	ft2,0(a4)

	c.li x0,2
	flw	ft3,0(a5)
	addi	a4,a4,4

	c.li x0,3
	addi	a5,a5,4
	fmadd.s	fa6,ft2,ft3,fa6
	addi	a0,a0,-1
.L60:
	flw	ft4,0(a4)
	flw	ft5,0(a5)

	c.li x0,4
	addi	a4,a4,4
	addi	a5,a5,4
	fmadd.s	fa6,ft4,ft5,fa6
	addi	a0,a0,-1
.L59:
	flw	ft6,0(a4)
	flw	ft7,0(a5)

	c.li x0,4
	addi	a4,a4,4
	addi	a5,a5,4
	fmadd.s	fa6,ft6,ft7,fa6
	addi	a0,a0,-1
.L58:
	flw	fs0,0(a4)
	flw	fs1,0(a5)

	c.li x0,4
	addi	a4,a4,4
	addi	a5,a5,4
	fmadd.s	fa6,fs0,fs1,fa6
	addi	a0,a0,-1
.L57:
	flw	fa0,0(a4)
	flw	fa1,0(a5)

	c.li x0,4
	addi	a0,a0,-1
	addi	a4,a4,4
	addi	a5,a5,4
	fmadd.s	fa6,fa0,fa1,fa6

	beq	a0,zero,.L3
.L4:
	# Main tap-accumulation loop: fold eight taps into the running dot product.
	# BIG-O: O(numTaps) per output sample; O(blockSize * numTaps) overall
	flw	fa7,0(a4)
	flw	fs2,0(a5)
	flw	fs3,4(a4)

	c.li x0,2
	flw	fa2,4(a5)
	fmadd.s	fs4,fa7,fs2,fa6

	c.li x0,2
	flw	fs5,8(a4)
	fmadd.s	fs9,fs3,fa2,fs4

	flw	fs6,8(a5)

	c.li x0,2
	flw	fs7,12(a4)
	fmadd.s	ft10,fs5,fs6,fs9

	flw	fs8,12(a5)

	c.li x0,2
	flw	fs10,16(a4)
	fmadd.s	fa3,fs7,fs8,ft10

	flw	fs11,16(a5)

	c.li x0,2
	flw	ft8,20(a4)
	fmadd.s	ft1,fs10,fs11,fa3

	flw	ft9,20(a5)

	c.li x0,3
	flw	ft11,24(a4)
	addi	a0,a0,-8
	fmadd.s	ft2,ft8,ft9,ft1

	flw	fa4,24(a5)

	c.li x0,2
	flw	fa5,28(a4)
	fmadd.s	ft3,ft11,fa4,ft2

	c.li x0,2
	flw	ft0,28(a5)
	addi	a4,a4,32

	c.li x0,2
	addi	a5,a5,32
	fmadd.s	fa6,fa5,ft0,ft3

	bne	a0,zero,.L4
.L3:
	# Commit one output sample and advance the rolling state window.
	# BIG-O: O(1) per output sample
	
	c.li x0,3
	fsw	fa6,0(a2)
	addi	t3,t3,-1
	addi	t4,t4,4

	addi	a2,a2,4
	bne	t3,zero,.L5
.L77:
	# Reposition the state pointers for the trailing state-compaction pass.
	# BIG-O: O(1)
	slli	a1,a3,2
	add	a5,t5,a1
.L2:
	# Dispatch the trailing state copy that preserves numTaps - 1 history values.
	# BIG-O: O(numTaps)
	addi	a4,a7,-1
	beq	a4,zero,.L1
	andi	a3,a4,7
	beq	a3,zero,.L7
	li	a2,1
	beq	a3,a2,.L63
	li	t0,2
	beq	a3,t0,.L64
	li	t1,3
	beq	a3,t1,.L65
	li	a6,4
	beq	a3,a6,.L66
	li	t2,5
	beq	a3,t2,.L67
	li	t6,6
	bne	a3,t6,.L75
.L68:
	# Copy the short state remainder one sample at a time.
	# BIG-O: O(1)
	c.li x0,2
	flw	ft5,0(a5)
	addi	a4,a4,-1

	c.li x0,3
	fsw	ft5,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4
.L67:
	c.li x0,2
	flw	ft6,0(a5)
	addi	a4,a4,-1

	c.li x0,3
	fsw	ft6,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4
.L66:
	c.li x0,2
	flw	ft7,0(a5)
	addi	a4,a4,-1

	c.li x0,3
	fsw	ft7,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4
.L65:
	c.li x0,2
	flw	fs0,0(a5)
	addi	a4,a4,-1

	c.li x0,3
	fsw	fs0,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4
.L64:
	c.li x0,2
	flw	fs1,0(a5)
	addi	a4,a4,-1

	c.li x0,3
	fsw	fs1,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4
.L63:
	c.li x0,2
	flw	fa0,0(a5)
	addi	a4,a4,-1

	c.li x0,3
	fsw	fa0,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4

	beq	a4,zero,.L76
.L7:
	# Main state-compaction loop: move eight preserved history samples per trip.
	# BIG-O: O(numTaps)

	c.li x0,2
	flw	fa1,0(a5)
	addi	t5,t5,32

	c.li x0,3
	fsw	fa1,-32(t5)
	addi	a5,a5,32
	addi	a4,a4,-8

	flw	fa6,-28(a5)
	fsw	fa6,-28(t5)
	flw	fa7,-24(a5)
	fsw	fa7,-24(t5)
	flw	fs2,-20(a5)
	fsw	fs2,-20(t5)
	flw	fs3,-16(a5)
	fsw	fs3,-16(t5)
	flw	fa2,-12(a5)
	fsw	fa2,-12(t5)
	flw	fs4,-8(a5)
	fsw	fs4,-8(t5)
	flw	fs5,-4(a5)
	fsw	fs5,-4(t5)
	bne	a4,zero,.L7
.L1:
	# Final exit after state compaction completes.
	# BIG-O: O(1)
	ret
.L9:
	# Degenerate zero-tap path emits zeros while still advancing the block loop.
	# BIG-O: O(blockSize)

	c.li x0,4
	fmv.s.x	fa6,zero
	addi	t3,t3,-1
	addi	a2,a2,4
	addi	t4,t4,4

	fsw	fa6,-4(a2)
	bne	t3,zero,.L5
	j	.L77
.L75:
	c.li x0,2
	flw	ft4,0(a5)
	addi	a4,a7,-2

	c.li x0,3
	fsw	ft4,0(t5)
	addi	a5,a5,4
	addi	t5,t5,4
	j	.L68
.L76:
	# State-copy completion when only the scalar remainder ran.
	# BIG-O: O(1)
	ret
.L8:
	# Zero-length block skips directly to the state-compaction bookkeeping.
	# BIG-O: O(1)
	mv	a5,t5
	j	.L2
	.size	arm_fir_f32, .-arm_fir_f32
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
