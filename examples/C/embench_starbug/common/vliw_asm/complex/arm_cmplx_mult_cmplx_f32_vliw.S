# ==============================================================================
# SECTION: Complex Pairwise Multiply Kernel
# FREQUENCY: Once per arm_cmplx_mult_cmplx_f32 call
# BIG-O: O(numSamples)
# PURPOSE: Compute the complex product of interleaved input pairs and write
#          interleaved real and imaginary results, with remainder handling
#          ahead of the four-complex unrolled fast path.
# ==============================================================================
# SOURCE: arm_cmplx_mult_cmplx_f32.c
# BENCHMARKS: dct4_512_f32 dct4_2048_f32

	.file	"arm_cmplx_mult_cmplx_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_cmplx_mult_cmplx_f32
	.type	arm_cmplx_mult_cmplx_f32, @function
arm_cmplx_mult_cmplx_f32:
	# Decode the leftover complex-pair count and choose the peel or fast path.
	# BIG-O: O(1)
	beq	a3,zero,.L1

	c.li x0,2
	andi	a5,a3,3
	addi	a6,a3,-1

	c.li x0,2
	beq	a5,zero,.L3
	li	a4,1

	c.li x0,2
	beq	a5,a4,.L16
	li	t0,2

	beq	a5,t0,.L17

	c.li x0,4
	flw	fa4,0(a0)
	addi	a0,a0,8
	addi	a2,a2,8
	mv	a3,a6

	c.li x0,2
	flw	fa2,0(a1)
	addi	a1,a1,8

	flw	fa3,-4(a0)

	c.li x0,2
	flw	fa5,-4(a1)
	fmul.s	ft0,fa3,fa2

	fmul.s	fa1,fa3,fa5

	c.li x0,2
	fmadd.s	ft1,fa4,fa5,ft0
	fmsub.s	ft2,fa4,fa2,fa1

	fsw	ft1,-4(a2)
	fsw	ft2,-8(a2)
.L17:
	# Consume the 1..3 leftover complex products with a fallthrough ladder.
	# BIG-O: O(1)

	c.li x0,4
	flw	ft3,0(a0)
	addi	a0,a0,8
	addi	a2,a2,8
	addi	a3,a3,-1

	c.li x0,2
	flw	ft4,0(a1)
	addi	a1,a1,8

	flw	ft5,-4(a0)

	c.li x0,2
	flw	ft6,-4(a1)
	fmul.s	ft7,ft5,ft4

	fmul.s	fs0,ft5,ft6

	c.li x0,2
	fmadd.s	fs1,ft3,ft6,ft7
	fmsub.s	fa0,ft3,ft4,fs0

	fsw	fs1,-4(a2)
	fsw	fa0,-8(a2)
.L16:

	c.li x0,4
	flw	fa6,0(a0)
	addi	a0,a0,8
	addi	a2,a2,8
	addi	a3,a3,-1

	c.li x0,2
	flw	fa7,0(a1)
	addi	a1,a1,8

	flw	fs2,-4(a0)

	c.li x0,2
	flw	fs3,-4(a1)
	fmul.s	fs4,fs2,fa7

	fmul.s	fs5,fs2,fs3

	c.li x0,2
	fmadd.s	fs6,fa6,fs3,fs4
	fmsub.s	fs7,fa6,fa7,fs5

	fsw	fs7,-8(a2)
	fsw	fs6,-4(a2)
	beq	a3,zero,.L22
.L3:
	# Main steady-state body: process four complex products per iteration.
	# BIG-O: O(numSamples)
	# Lane 0 streams one memory op per bundle while the side lanes carry
	# the complex multiply chain for the current and following pairs.
	c.li x0,4
	flw	fs11,0(a0)
	addi	a0,a0,32
	addi	a2,a2,32
	addi	a3,a3,-4

	c.li x0,2
	flw	fs10,0(a1)
	addi	a1,a1,32

	flw	fs8,-28(a0)

	c.li x0,2
	flw	fs9,-28(a1)
	fmul.s	ft9,fs8,fs10

	c.li x0,2
	flw	fa5,-24(a0)
	fmul.s	ft8,fs8,fs9

	c.li x0,3
	flw	fa4,-24(a1)
	fmsub.s	ft10,fs11,fs10,ft8
	fmadd.s	ft11,fs11,fs9,ft9

	flw	fa3,-20(a0)

	c.li x0,2
	flw	fa2,-20(a1)
	fmul.s	ft0,fa3,fa4

	c.li x0,2
	fsw	ft10,-32(a2)
	fmul.s	fa1,fa3,fa2

	c.li x0,3
	fsw	ft11,-28(a2)
	fmsub.s	ft1,fa5,fa4,fa1
	fmadd.s	ft2,fa5,fa2,ft0

	flw	ft6,-16(a0)
	flw	ft5,-16(a1)
	flw	ft3,-12(a0)

	c.li x0,2
	flw	ft4,-12(a1)
	fmul.s	fs0,ft3,ft5

	c.li x0,2
	fsw	ft1,-24(a2)
	fmul.s	ft7,ft3,ft4

	c.li x0,3
	fsw	ft2,-20(a2)
	fmsub.s	fs1,ft6,ft5,ft7
	fmadd.s	fa0,ft6,ft4,fs0

	flw	fa6,-8(a0)

	flw	fa7,-8(a1)

	flw	fs2,-4(a0)

	c.li x0,2
	flw	fs3,-4(a1)
	fmul.s	fs5,fs2,fa7

	c.li x0,2
	fsw	fs1,-16(a2)
	fmul.s	fs4,fs2,fs3

	c.li x0,3
	fsw	fa0,-12(a2)
	fmsub.s	fs7,fa6,fa7,fs4
	fmadd.s	fs6,fa6,fs3,fs5

	fsw	fs7,-8(a2)
	fsw	fs6,-4(a2)
	bne	a3,zero,.L3
.L1:
	# Empty-input or completed-loop exit.
	# BIG-O: O(1)
	ret
.L22:
	# Tail-only completion exit after the remainder ladder drains the counter.
	# BIG-O: O(1)
	ret
	.size	arm_cmplx_mult_cmplx_f32, .-arm_cmplx_mult_cmplx_f32
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
