# ==============================================================================
# SECTION: Real FFT Split And Merge Wrapper
# FREQUENCY: Once per arm_rfft_fast_f32 call
# BIG-O: O(fftLen log fftLen)
# PURPOSE: For forward transforms, run the complex FFT and split mirrored bins
#          into packed real-spectrum output; for inverse transforms, merge the
#          spectrum back into a complex buffer before calling the inverse CFFT.
# ==============================================================================
# SOURCE: arm_rfft_fast_f32.c
# BENCHMARKS: rfft512_f32 rfft2048_f32 dct4_512_f32 dct4_2048_f32

	.file	"arm_rfft_fast_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_rfft_fast_f32
	.type	arm_rfft_fast_f32, @function
arm_rfft_fast_f32:
	# Save state and dispatch between the inverse-merge and forward-split paths.
	# BIG-O: O(1)
	addi	sp,sp,-32
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	s4,8(sp)


	c.li x0,2
	sw	ra,28(sp)
	mv	s3,a2

	c.li x0,4
	mv	s2,a1
	addi	s1,a2,8
	addi	s0,a1,8
	mv	s4,a0

	beq	a3,zero,.L2
	# Inverse path: merge mirrored bins back into a complex buffer before the CFFT.
	# BIG-O: O(fftLen) locally; O(fftLen log fftLen) including arm_cfft_f32
	flw	ft6,0(a1)
	flw	ft7,4(a1)
	flw	fa0,.LC0,a5

	c.li x0,4
	lhu	t3,0(a0)
	fadd.s	fa1,ft6,ft7
	fsub.s	fs0,ft6,ft7
	mv	a2,a3

	c.li x0,4
	lw	t4,20(a0)
	addi	t5,t3,-1
	slli	t6,t3,3
	fmul.s	fs1,fa1,fa0

	c.li x0,4
	fsw	fs1,0(s3)
	fmul.s	fa6,fs0,fa0
	slli	a6,t5,3
	add	a7,a1,t6

	c.li x0,3
	fsw	fa6,4(s3)
	add	a0,a1,a6
	addi	a4,t4,8

	ble	t5,zero,.L5
	sub	a1,a7,s0
	addi	t0,a1,-8
	srli	t2,t0,3
	andi	t1,t2,1
	bne	t1,zero,.L4
	flw	fa7,0(a0)
	flw	fs2,0(s0)
	flw	fs3,0(a4)

	c.li x0,2
	flw	fs6,4(s0)
	fsub.s	fs4,fs2,fa7

	flw	fs5,12(t4)

	c.li x0,4
	flw	fs7,4(a0)
	fsub.s	fs4,fs2,fa7
	addi	s0,s2,16
	addi	a4,t4,16

	c.li x0,4
	fnmsub.s	fs8,fs3,fs4,fa7
	fmadd.s	fs9,fs5,fs4,fs6
	fadd.s	fs10,fs7,fs6
	addi	a0,a0,-8
	
	c.li x0,2
	fadd.s	fs11,fs8,fs2
	fsub.s	ft8,fs9,fs7

	c.li x0,2
	fnmsub.s	ft9,fs5,fs10,fs11
	fnmsub.s	ft10,fs3,fs10,ft8

	c.li x0,2
	fmul.s	ft11,ft9,fa0
	fmul.s	fa4,ft10,fa0

	fsw	ft11,0(s1)

	c.li x0,2
	fsw	fa4,12(s3)
	addi	s1,s3,16

	beq	s0,a7,.L5
.L4:
	# Main inverse merge loop: combine two mirrored bins per iteration.
	# BIG-O: O(fftLen)
	flw	fa2,0(a0)
	flw	ft1,0(s0)
	flw	fa5,0(a4)

	c.li x0,2
	flw	ft3,4(a4)
	fsub.s	fa3,ft1,fa2

	c.li x0,4
	flw	ft2,4(s0)
	addi	a4,a4,16
	addi	s1,s1,16
	fnmsub.s	ft4,fa5,fa3,fa2

	c.li x0,3
	flw	ft0,4(a0)
	fmadd.s	ft5,ft3,fa3,ft2
	addi	s0,s0,16

	c.li x0,4
	flw	fs2,8(a0)
	fadd.s	ft6,ft0,ft2
	fadd.s	ft7,ft4,ft1
	fsub.s	fa1,ft5,ft0

	c.li x0,4
	flw	fs3,-8(s0)
	fnmsub.s	fs0,ft3,ft6,ft7
	fnmsub.s	fs1,fa5,ft6,fa1
	addi	a0,a0,-16

	c.li x0,4
	flw	fs4,-8(a4)
	fmul.s	fa6,fs0,fa0
	fmul.s	fa7,fs1,fa0
	fsub.s	fs5,fs3,fs2

	flw	fs7,-4(a4)
	flw	fs6,-4(s0)

	c.li x0,3
	flw	fs8,12(a0)
	fnmsub.s	fs9,fs4,fs5,fs2
	fmadd.s	fs10,fs7,fs5,fs6

	c.li x0,4
	fsw	fa6,-16(s1)
	fadd.s	fs11,fs8,fs6
	fadd.s	ft8,fs9,fs3
	fsub.s	ft9,fs10,fs8

	c.li x0,3
	fsw	fa7,-12(s1)
	fnmsub.s	ft10,fs7,fs11,ft8
	fnmsub.s	ft11,fs4,fs11,ft9

	c.li x0,2
	fmul.s	fa4,ft10,fa0
	fmul.s	fa2,ft11,fa0

	fsw	fa4,-8(s1)
	fsw	fa2,-4(s1)
	bne	s0,a7,.L4
.L5:
	# Tail-call the inverse complex FFT once the merge buffer is ready.
	# BIG-O: O(fftLen log fftLen)
	lw	s0,24(sp)
	lw	ra,28(sp)
	lw	s1,20(sp)

	c.li x0,4
	lw	s2,16(sp)
	mv	a1,s3
	mv	a0,s4
	li	a3,1

	lw	s3,12(sp)
	lw	s4,8(sp)
	addi	sp,sp,32
	tail	arm_cfft_f32
.L2:
	# Forward path: run the complex FFT first, then split bins into packed real output.
	# BIG-O: O(fftLen log fftLen)

	c.li x0,2
	li	a3,1
	li	a2,0

	call	arm_cfft_f32
	flw	fa4,4(s2)
	lhu	a6,0(s4)
	flw	fa2,.LC1,a5

	c.li x0,3
	flw	fa5,0(s2)
	fadd.s	ft0,fa4,fa4
	addi	a1,a6,-1

	flw	fa0,.LC0,a5

	c.li x0,4
	lw	a7,20(s4)
	slli	t0,a1,3
	fmadd.s	fa3,fa5,fa2,ft0
	fmsub.s	ft1,fa5,fa2,ft0

	c.li x0,4
	flw	ft5,0(s0)
	addi	a5,s3,16
	add	t2,s2,t0
	fmul.s	ft2,fa3,fa0

	c.li x0,4
	flw	ft4,0(t2)
	fmul.s	ft3,ft1,fa0
	addi	a4,a7,16
	addi	a2,a6,-2
	
	c.li x0,2
	flw	fa1,4(s0)
	addi	a3,t2,-8

	c.li x0,4
	flw	ft6,8(a7)
	fsub.s	ft7,ft4,ft5
	andi	t1,a6,1
	addi	a0,s2,16

	c.li x0,2
	flw	fs0,-4(a4)
	fmadd.s	fa6,ft6,ft7,ft4
	
	c.li x0,3
	flw	fs1,4(t2)
	fmadd.s	fa7,fs0,ft7,fa1
	fadd.s	fs3,fa6,ft5

	c.li x0,3
	fsw	ft3,4(s3)
	fadd.s	fs2,fs1,fa1
	fsub.s	fs4,fa7,fs1

	c.li x0,3
	fsw	ft2,0(s3)
	fmadd.s	fs5,fs0,fs2,fs3
	fnmsub.s	fs6,ft6,fs2,fs4

	c.li x0,2
	fmul.s	fs7,fs5,fa0
	fmul.s	fs8,fs6,fa0

	fsw	fs7,0(s1)
	fsw	fs8,-4(a5)
	ble	a2,zero,.L22
	beq	t1,zero,.L6
	# Odd-length peel for the forward split loop.
	# BIG-O: O(1)
	flw	fs9,0(a3)
	flw	fs10,0(a0)

	c.li x0,3
	flw	fs11,0(a4)
	fsub.s	ft8,fs9,fs10
	addi	a2,a6,-3

	c.li x0,3
	flw	ft11,4(a3)
	addi	a4,a7,24
	fmadd.s	fa4,fs11,ft8,fs9

	flw	ft10,4(a0)

	c.li x0,4
	flw	ft9,20(a7)
	fadd.s	ft0,ft11,ft10
	addi	a3,t2,-16
	fadd.s	fa2,fa4,fs10

	c.li x0,3
	fmadd.s	fa5,ft9,ft8,ft10
	addi	a0,s2,24
	fmadd.s	ft1,ft9,ft0,fa2

	c.li x0,2
	fsub.s	fa3,fa5,ft11
	fmul.s	ft3,ft1,fa0

	c.li x0,2
	fsw	ft3,0(a5)
	fnmsub.s	ft2,fs11,ft0,fa3

	fmul.s	ft4,ft2,fa0
	fsw	ft4,20(s3)
	addi	a5,s3,24
	ble	a2,zero,.L22
.L6:
	# Main forward split loop: emit two packed real-spectrum bins per iteration.
	# BIG-O: O(fftLen)
	flw	ft5,0(a3)
	flw	ft6,0(a0)

	c.li x0,4
	flw	ft7,0(a4)
	fsub.s	fs0,ft5,ft6
	addi	a5,a5,16
	addi	a2,a2,-2
	
	flw	fs1,4(a4)
	
	c.li x0,3
	flw	fa1,4(a0)
	fmadd.s	fa7,ft7,fs0,ft5
	addi	a4,a4,16

	c.li x0,4
	flw	fa6,4(a3)
	fmadd.s	fs2,fs1,fs0,fa1
	addi	a0,a0,16
	fadd.s	fs4,fa7,ft6

	c.li x0,4
	flw	fs11,-8(a0)
	fadd.s	fs3,fa6,fa1
	fsub.s	fs5,fs2,fa6
	addi	a3,a3,-16

	c.li x0,3
	flw	fs10,8(a3)
	fmadd.s	fs6,fs1,fs3,fs4
	fnmsub.s	fs7,ft7,fs3,fs5

	c.li x0,4
	flw	ft8,-8(a4)
	fmul.s	fs8,fs6,fa0
	fmul.s	fs9,fs7,fa0
	fsub.s	ft9,fs10,fs11

	flw	ft10,-4(a0)
	flw	ft11,-4(a4)

	c.li x0,3
	flw	fa4,12(a3)
	fmadd.s	fa5,ft8,ft9,fs10
	fmadd.s	ft0,ft11,ft9,ft10

	c.li x0,4
	fsw	fs8,-16(a5)
	fadd.s	ft1,fa4,ft10
	fadd.s	fa2,fa5,fs11
	fsub.s	fa3,ft0,fa4

	c.li x0,3
	fsw	fs9,-12(a5)
	fmadd.s	ft2,ft11,ft1,fa2
	fnmsub.s	ft3,ft8,ft1,fa3

	c.li x0,2
	fmul.s	ft4,ft2,fa0
	fmul.s	ft5,ft3,fa0

	fsw	ft4,-8(a5)
	fsw	ft5,-4(a5)
	bgt	a2,zero,.L6
.L22:
	# Restore state after the forward split completes.
	# BIG-O: O(1)
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	addi	sp,sp,32
	jr	ra
	.size	arm_rfft_fast_f32, .-arm_rfft_fast_f32
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
.LC0:
	.word	1056964608
	.align	2
.LC1:
	.word	1073741824
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
