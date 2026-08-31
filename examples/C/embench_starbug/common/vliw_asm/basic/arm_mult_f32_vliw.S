# ==============================================================================
# SECTION: Elementwise Vector Multiply Kernel
# FREQUENCY: Once per arm_mult_f32 call
# BIG-O: O(blockSize)
# PURPOSE: Multiply matching samples from two input vectors into the output
#          buffer, handling the short tail first and then advancing through an
#          unrolled eight-sample main loop.
# ==============================================================================
# SOURCE: arm_mult_f32.c
# BENCHMARKS: dct4_512_f32 dct4_2048_f32

	.file	"arm_mult_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_mult_f32
	.type	arm_mult_f32, @function
arm_mult_f32:
	# Decode the leftover sample count and branch into the peel or fast path.
	# BIG-O: O(1)
	beq	a3,zero,.L1

	c.li x0,2
	andi	a5,a3,7
	addi	a6,a3,-1

	c.li x0,2
	beq	a5,zero,.L3
	li	a4,1

	c.li x0,2
	beq	a5,a4,.L28
	li	t0,2

	c.li x0,2
	beq	a5,t0,.L29
	li	t1,3

	c.li x0,2
	beq	a5,t1,.L30
	li	t2,4

	c.li x0,2
	beq	a5,t2,.L31
	li	a7,5

	c.li x0,2
	beq	a5,a7,.L32
	li	t3,6

	bne	a5,t3,.L38
.L33:
	# Consume the 1..6 leftover products with a fallthrough scalar ladder.
	# BIG-O: O(1)
	c.li x0,3
	flw	ft1,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	flw	ft2,0(a1)
	addi	a0,a0,4

	c.li x0,2
	addi	a1,a1,4
	fmul.s	ft3,ft1,ft2

	fsw	ft3,-4(a2)
.L32:
	c.li x0,3
	flw	ft4,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	flw	ft5,0(a1)
	addi	a0,a0,4

	c.li x0,2
	addi	a1,a1,4
	fmul.s	ft6,ft4,ft5

	fsw	ft6,-4(a2)
.L31:
	c.li x0,3
	flw	ft7,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	flw	fs0,0(a1)
	addi	a0,a0,4

	c.li x0,2
	addi	a1,a1,4
	fmul.s	fs1,ft7,fs0

	fsw	fs1,-4(a2)
.L30:
	c.li x0,3
	flw	fa0,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	flw	fa1,0(a1)
	addi	a0,a0,4

	c.li x0,2
	addi	a1,a1,4
	fmul.s	fa2,fa0,fa1

	fsw	fa2,-4(a2)
.L29:
	c.li x0,3
	flw	fa3,0(a0)
	addi	a3,a3,-1
	addi	a2,a2,4

	c.li x0,2
	flw	fa6,0(a1)
	addi	a0,a0,4

	c.li x0,2
	addi	a1,a1,4
	fmul.s	fa7,fa3,fa6

	fsw	fa7,-4(a2)
.L28:
	c.li x0,2
	flw	fs2,0(a0)
	addi	a3,a3,-1

	c.li x0,3
	flw	fs3,0(a1)
	addi	a0,a0,4
	addi	a2,a2,4

	c.li x0,2
	fmul.s	fs4,fs2,fs3
	addi	a1,a1,4

	fsw	fs4,-4(a2)
	beq	a3,zero,.L39
.L3:
	# Main steady-state body: multiply eight sample pairs per iteration.
	# BIG-O: O(blockSize)
	flw	fs5,0(a0)

	flw	fs6,0(a1)

	c.li x0,3
	addi	a0,a0,32
	addi	a2,a2,32
	addi	a3,a3,-8

	c.li x0,3
	flw	fs8,-28(a0)
	addi	a1,a1,32
	fmul.s	fs7,fs5,fs6
	
	flw	fs9,-28(a1)

	c.li x0,2
	fsw	fs7,-32(a2)
	fmul.s	fs10,fs8,fs9

	flw	fs11,-24(a0)
	flw	ft8,-24(a1)

	c.li x0,2
	fsw	fs10,-28(a2)
	fmul.s	ft9,fs11,ft8
	
	flw	ft10,-20(a0)
	flw	ft11,-20(a1)

	c.li x0,2
	fsw	ft9,-24(a2)
	fmul.s	fa5,ft10,ft11

	flw	ft0,-16(a0)
	flw	fa4,-16(a1)

	c.li x0,2
	fsw	fa5,-20(a2)
	fmul.s	ft1,ft0,fa4
	
	flw	ft2,-12(a0)
	flw	ft3,-12(a1)

	c.li x0,2
	fsw	ft1,-16(a2)
	fmul.s	ft4,ft2,ft3
	
	flw	ft5,-8(a0)
	flw	ft6,-8(a1)

	c.li x0,2
	fsw	ft4,-12(a2)
	fmul.s	ft7,ft5,ft6
	
	flw	fs0,-4(a0)
	flw	fs1,-4(a1)

	c.li x0,2
	fsw	ft7,-8(a2)
	fmul.s	fa0,fs0,fs1

	fsw	fa0,-4(a2)
	bne	a3,zero,.L3
.L1:
	# Empty-input or completed-loop exit.
	# BIG-O: O(1)
	ret
.L38:
	# Special seven-sample entry peels one pair, then rejoins the tail ladder.
	# BIG-O: O(1)
	c.li x0,2
	flw	fa5,0(a0)
	addi	a2,a2,4

	c.li x0,2
	flw	fa4,0(a1)
	addi	a0,a0,4

	c.li x0,3
	addi	a1,a1,4
	fmul.s	ft0,fa5,fa4
	mv	a3,a6

	fsw	ft0,-4(a2)
	j	.L33
.L39:
	# Tail-only completion exit after the remainder ladder drains the counter.
	# BIG-O: O(1)
	ret
	.size	arm_mult_f32, .-arm_mult_f32
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
