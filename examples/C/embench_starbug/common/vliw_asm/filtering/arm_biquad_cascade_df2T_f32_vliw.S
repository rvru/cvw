# ==============================================================================
# SECTION: Cascaded DF2T Biquad Stage Processing
# FREQUENCY: Once per arm_biquad_cascade_df2T_f32 call
# BIG-O: O(numStages * blockSize)
# PURPOSE: Load one stage's coefficients and delay elements, filter the block
#          in place with a four-sample unrolled loop, then write the updated
#          d1 and d2 state back before moving to the next stage.
# ==============================================================================
# SOURCE: arm_biquad_cascade_df2T_f32.c
# BENCHMARKS: biquad_cascade_df2T_f32_sos3_n1 biquad_cascade_df2T_f32_sos3_n128

	.file	"arm_biquad_cascade_df2T_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_biquad_cascade_df2T_f32
	.type	arm_biquad_cascade_df2T_f32, @function
arm_biquad_cascade_df2T_f32:
	lw	a7,4(a0)
	lw	a6,8(a0)
	lbu	a0,0(a0)
.L4:
	# Outer stage loop: reload one biquad's coefficients and saved state.
	# BIG-O: O(numStages) control overhead; each pass feeds O(blockSize) work.
	flw	ft2,0(a6)
	flw	ft1,4(a6)
	flw	fa1,8(a6)
	flw	fa0,12(a6)
	flw	ft0,16(a6)

	c.li x0,2
	flw	fa7,0(a7)
	addi	a6,a6,20

	flw	fs2,4(a7)

	beq	a3,zero,.L2

	c.li x0,4
	andi	t1,a3,3
	mv	a4,a3
	mv	a5,a2
	addi	t4,a3,-1

	c.li x0,3
	beq	t1,zero,.L3
	li	t3,1
	li	t0,2

	beq	t1,t3,.L18
	beq	t1,t0,.L19
	# Consume the 1..3 sample remainder for this stage before the unrolled loop.
	# BIG-O: O(1) per stage

	c.li x0,3
	flw	fa3,0(a1)
	addi	a5,a2,4
	addi	a1,a1,4

	c.li x0,3
	fmadd.s	fa2,ft2,fa3,fa7
	fmadd.s	fa4,ft1,fa3,fs2
	mv	a4,t4

	c.li x0,2
	fmul.s	ft3,ft0,fa2
	fmadd.s	fa7,fa0,fa2,fa4

	c.li x0,2
	fsw	fa2,0(a2)
	fmadd.s	fs2,fa1,fa3,ft3
.L19:
	c.li x0,3
	flw	ft4,0(a1)
	addi	a4,a4,-1
	addi	a1,a1,4

	c.li x0,3
	fmadd.s	ft5,ft2,ft4,fa7
	fmadd.s	ft6,ft1,ft4,fs2
	addi	a5,a5,4

	c.li x0,3
	fsw	ft5,-4(a5)
	fmul.s	ft7,ft0,ft5
	fmadd.s	fa7,fa0,ft5,ft6

	fmadd.s	fs2,fa1,ft4,ft7
.L18:
	c.li x0,3
	flw	fs0,0(a1)
	addi	a5,a5,4
	addi	a4,a4,-1

	c.li x0,3
	fmadd.s	fa5,ft2,fs0,fa7
	fmadd.s	fs1,ft1,fs0,fs2
	addi	a1,a1,4

	c.li x0,2
	fsw	fa5,-4(a5)
	fmul.s	fa6,ft0,fa5

	c.li x0,2
	fmadd.s	fa7,fa0,fa5,fs1
	fmadd.s	fs2,fa1,fs0,fa6

	beq	a4,zero,.L2
.L3:
	# Main stage body: filter four samples and advance the DF2T state.
	# BIG-O: O(blockSize) per stage; O(numStages * blockSize) overall
	
	c.li x0,4
	flw	fs3,0(a1)
	addi	a1,a1,16
	addi	a5,a5,16
	addi	a4,a4,-4

	c.li x0,2
	fmadd.s	fs4,ft2,fs3,fa7
	fmadd.s	fs5,ft1,fs3,fs2

	c.li x0,3
	flw	fs8,-12(a1)
	fmul.s	fs6,ft0,fs4
	fmadd.s	fs7,fa0,fs4,fs5


	c.li x0,3
	fsw	fs4,-16(a5)
	fmadd.s	fs9,fa1,fs3,fs6
	fmadd.s	fs10,ft2,fs8,fs7

	c.li x0,3
	flw	ft9,-8(a1)
	fmadd.s	fs11,ft1,fs8,fs9
	fmul.s	ft8,ft0,fs10

	c.li x0,3
	fsw	fs10,-12(a5)
	fmadd.s	ft10,fa0,fs10,fs11
	fmadd.s	ft11,fa1,fs8,ft8

	c.li x0,3
	flw	ft4,-4(a1)
	fmadd.s	fa3,ft2,ft9,ft10
	fmadd.s	fa4,ft1,ft9,ft11

	c.li x0,3
	fsw	fa3,-8(a5)
	fmul.s	fa2,ft0,fa3
	fmadd.s	ft3,fa0,fa3,fa4


	c.li x0,2
	fmadd.s	ft5,fa1,ft9,fa2
	fmadd.s	ft6,ft2,ft4,ft3

	c.li x0,2
	fmadd.s	ft7,ft1,ft4,ft5
	fmul.s	fs0,ft0,ft6

	c.li x0,3
	fsw	ft6,-4(a5)
	fmadd.s	fa7,fa0,ft6,ft7
	fmadd.s	fs2,fa1,ft4,fs0

	bne	a4,zero,.L3
.L2:
	# Commit the updated delays and either advance to the next stage or return.
	# BIG-O: O(1) per stage
	fsw	fa7,0(a7)

	c.li x0,3
	fsw	fs2,4(a7)
	addi	a0,a0,-1
	addi	a7,a7,8

	beq	a0,zero,.L24
	mv	a1,a2
	j	.L4
.L24:
	# Final exit after the last stage stores back its state.
	# BIG-O: O(1)
	ret
	.size	arm_biquad_cascade_df2T_f32, .-arm_biquad_cascade_df2T_f32
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
