# ==============================================================================
# SECTION: Vector Scaling Kernel
# FREQUENCY: Once per arm_scale_f32 call
# BIG-O: O(blockSize)
# PURPOSE: Multiply each source sample by a scalar and store it to the output
#          buffer, using a short remainder path before the unrolled
#          eight-sample steady-state loop.
# ==============================================================================
# SOURCE: arm_scale_f32.c
# BENCHMARKS: dct4_512_f32 dct4_2048_f32

	.file	"arm_scale_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_scale_f32
	.type	arm_scale_f32, @function
arm_scale_f32:
	# Decode the leftover sample count and select the scalar peel or fast loop.
	# BIG-O: O(1)
	fmv.s.x	fa5,a1
	beq	a3,zero,.L1

	c.li x0,2
	andi	a5,a3,7
	addi	a1,a3,-1
	
	beq	a5,zero,.L3
	li	a4,1
	beq	a5,a4,.L28
	li	t0,2
	beq	a5,t0,.L29
	li	t1,3
	beq	a5,t1,.L30
	li	t2,4
	beq	a5,t2,.L31
	li	a6,5
	beq	a5,a6,.L32
	li	a7,6
	bne	a5,a7,.L38
.L33:
	# Consume the 1..6 sample remainder with a fallthrough ladder.
	# BIG-O: O(1)
	c.li x0,3
	flw	ft1,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	addi	a0,a0,4
	fmul.s	ft2,ft1,fa5

	fsw	ft2,-4(a2)
.L32:
	c.li x0,3
	flw	ft3,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	addi	a0,a0,4
	fmul.s	ft4,ft3,fa5

	fsw	ft4,-4(a2)
.L31:
	c.li x0,3
	flw	ft5,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	addi	a0,a0,4
	fmul.s	ft6,ft5,fa5

	fsw	ft6,-4(a2)
.L30:
	c.li x0,3
	flw	ft7,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	addi	a0,a0,4
	fmul.s	fs0,ft7,fa5

	fsw	fs0,-4(a2)
.L29:
	c.li x0,3
	flw	fs1,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	addi	a0,a0,4
	fmul.s	fa0,fs1,fa5

	fsw	fa0,-4(a2)
.L28:
	c.li x0,3
	flw	fa1,0(a0)
	addi	a2,a2,4
	addi	a3,a3,-1

	c.li x0,2
	fmul.s	fa2,fa1,fa5
	addi	a0,a0,4

	fsw	fa2,-4(a2)

	beq	a3,zero,.L39
.L3:
	# Main steady-state body: process eight scaled samples per iteration.
	# BIG-O: O(blockSize)
	c.li x0,3
	flw	fa3,0(a0)
	addi	a2,a2,32
	addi	a3,a3,-8

	c.li x0,2
	fmul.s	fa6,fa3,fa5
	addi	a0,a0,32

	flw	fa7,-28(a0)

	c.li x0,2
	fsw	fa6,-32(a2)
	fmul.s	fs2,fa7,fa5

	flw	fs3,-24(a0)

	c.li x0,2
	fsw	fs2,-28(a2)
	fmul.s	fs4,fs3,fa5
	
	flw	fs5,-20(a0)

	c.li x0,2
	fsw	fs4,-24(a2)
	fmul.s	fs6,fs5,fa5
	
	flw	fs7,-16(a0)

	c.li x0,2
	fsw	fs6,-20(a2)
	fmul.s	fs8,fs7,fa5
	
	flw	fs9,-12(a0)

	c.li x0,2
	fsw	fs8,-16(a2)
	fmul.s	fs10,fs9,fa5
	
	flw	fs11,-8(a0)

	c.li x0,2
	fsw	fs10,-12(a2)
	fmul.s	ft8,fs11,fa5

	flw	ft9,-4(a0)

	c.li x0,2
	fsw	ft8,-8(a2)
	fmul.s	ft10,ft9,fa5

	fsw	ft10,-4(a2)
	bne	a3,zero,.L3
.L1:
	# Empty-input or completed-loop exit.
	# BIG-O: O(1)
	ret
.L38:
	# Special seven-sample entry peels one value, then rejoins the tail ladder.
	# BIG-O: O(1)
	c.li x0,3
	flw	fa4,0(a0)
	mv	a3,a1
	addi	a2,a2,4

	c.li x0,2
	addi	a0,a0,4
	fmul.s	ft0,fa4,fa5

	fsw	ft0,-4(a2)
	j	.L33
.L39:
	# Tail-only completion exit after the remainder ladder drains the counter.
	# BIG-O: O(1)
	ret
	.size	arm_scale_f32, .-arm_scale_f32
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
