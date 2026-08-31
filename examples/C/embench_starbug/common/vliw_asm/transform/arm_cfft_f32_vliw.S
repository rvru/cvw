# ==============================================================================
# SECTION: FFT Dispatch And Inverse Postprocessing
# FREQUENCY: Once per arm_cfft_f32 call
# BIG-O: O(fftLen log fftLen)
# PURPOSE: Select the radix-8 butterfly strategy for the configured FFT length,
#          optionally perform bit reversal, and normalize inverse-transform
#          output when the caller requests an IFFT.
# ==============================================================================
# SOURCE: arm_cfft_f32.c
# BENCHMARKS: rfft512_f32 rfft2048_f32 dct4_512_f32 dct4_2048_f32

	.file	"arm_cfft_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_cfft_f32
	.type	arm_cfft_f32, @function
arm_cfft_f32:
	# Save callee state, decode the flags, and branch into forward or inverse setup.
	# BIG-O: O(1)
	addi	sp,sp,-80
	sw	s0,72(sp)
	sw	s2,64(sp)
	sw	s3,60(sp)
	sw	s4,56(sp)
	sw	s5,52(sp)

	c.li x0,3
	sw	ra,76(sp)
	mv	s3,a0
	mv	s4,a2


	c.li x0,4
	lhu	s2,0(a0)
	li	a5,1
	mv	s0,a1
	mv	s5,a3

	beq	a2,a5,.L2
.L16:
	# Forward-path length dispatcher: choose the decomposition for this FFT size.
	# BIG-O: O(1)
	li	a6,256
	beq	s2,a6,.L3
	bgtu	s2,a6,.L4
	li	a3,64
	beq	s2,a3,.L5
	bgtu	s2,a3,.L6
	li	t0,16
	beq	s2,t0,.L7
	li	t6,32
	beq	s2,t6,.L3
	beq	s5,zero,.L21
.L9:
	# Optional bit-reversal pass after the butterfly work completes.
	# BIG-O: O(fftLen)
	lw	a2,8(s3)

	c.li x0,2
	lhu	a1,12(s3)
	mv	a0,s0

	call	arm_bitreversal_32
.L21:
	li	s3,1
	beq	s4,s3,.L22
.L1:
	# Common epilogue when no inverse normalization remains to be done.
	# BIG-O: O(1)
	lw	ra,76(sp)
	lw	s0,72(sp)
	lw	s2,64(sp)
	lw	s3,60(sp)
	lw	s4,56(sp)
	lw	s5,52(sp)
	addi	sp,sp,80
	jr	ra
.L4:
	addi	a7,s2,-2048
	beq	a7,zero,.L3
	li	t3,4096
	addi	t4,t3,-2048
	li	t5,4096
	bgtu	s2,t4,.L12
	li	t6,512
	beq	s2,t6,.L5
	li	a5,1024
	bne	s2,a5,.L96
.L7:
	# Two-way decomposition path for the lengths that split into paired radix-8 calls.
	# BIG-O: O(fftLen log fftLen)

	c.li x0,2
	lw	a2,4(s3)
	srli	t1,s2,3

	c.li x0,2
	sw	s1,68(sp)
	slli	a1,t1,4

	c.li x0,4
	sw	s6,48(sp)
	slli	s1,s2,2
	srli	s6,s2,1
	add	a7,s0,a1

	c.li x0,3
	add	s1,s0,s1
	slli	t2,s6,2
	mv	a6,a2
	
	c.li x0,4
	add	a0,s1,t2
	add	a4,s0,t2
	mv	t4,s1
	mv	t3,s0
.L17:
	# Pre-butterfly packing loop for the two-way decomposition path.
	# BIG-O: O(fftLen)
	flw	fa7,0(t4)

	flw	ft0,0(t3)

	c.li x0,3
	flw	fa6,4(t4)
	fadd.s	fs3,ft0,fa7
	fsub.s	fs8,ft0,fa7

	flw	ft1,4(t3)

	c.li x0,3
	flw	ft6,8(t4)
	fadd.s	fs2,ft1,fa6
	fsub.s	fs9,ft1,fa6

	flw	fa2,8(t3)

	c.li x0,3
	flw	ft7,12(t4)
	fadd.s	fs1,fa2,ft6
	fsub.s	ft6,fa2,ft6

	flw	fs4,12(t3)

	c.li x0,3
	flw	fa0,0(a0)
	fadd.s	fs0,fs4,ft7
	fsub.s	ft11,fs4,ft7

	flw	ft3,0(a4)

	c.li x0,3
	flw	fa1,4(a0)
	fadd.s	fa3,ft3,fa0
	fsub.s	fs10,fa0,ft3
	
	flw	ft2,4(a4)

	c.li x0,3
	flw	fa4,8(a0)
	fadd.s	fs5,ft2,fa1
	fsub.s	fs11,fa1,ft2

	flw	ft4,8(a4)

	c.li x0,3
	flw	fa5,12(a0)
	fadd.s	fs6,ft4,fa4
	fsub.s	ft4,fa4,ft4

	flw	ft5,12(a4)

	c.li x0,3
	fsw	fs3,0(t3)
	fadd.s	fs7,ft5,fa5
	fsub.s	fs3,fa5,ft5

	flw	ft9,4(a6)

	c.li x0,3
	flw	ft10,0(a6)
	fmul.s	ft8,fs8,ft9
	fmul.s	ft0,fs9,ft9

	c.li x0,4
	fsw	fs2,4(t3)
	fmul.s	fa7,fs11,ft10
	fmul.s	fa6,fs10,ft10
	fmsub.s	ft1,fs9,ft10,ft8

	c.li x0,4
	fsw	fs1,8(t3)
	fmadd.s	fa2,fs8,ft10,ft0
	fmsub.s	ft7,fs10,ft9,fa7
	fmadd.s	fs4,fs11,ft9,fa6

	c.li x0,2
	fsw	fs0,12(t3)
	addi	a6,a6,16

	fsw	ft1,4(t4)

	fsw	fa2,0(t4)

	fsw	ft7,0(a0)

	fsw	fs4,4(a0)

	c.li x0,3
	fsw	fa3,0(a4)
	addi	t4,t4,16
	addi	a0,a0,16

	flw	fa0,-8(a6)

	c.li x0,4
	flw	fa1,-4(a6)
	fmul.s	ft3,fs3,fa0
	fmul.s	fa5,ft4,fa0
	addi	t3,t3,16

	c.li x0,4
	fsw	fs5,4(a4)
	fmul.s	ft2,ft11,fa1
	fmul.s	ft5,ft6,fa1
	fmadd.s	fs0,fs3,fa1,fa5

	c.li x0,4
	fsw	fs6,8(a4)
	fmadd.s	fs2,ft6,fa0,ft2
	fmsub.s	fs1,ft11,fa0,ft5
	fmsub.s	fa4,ft4,fa1,ft3

	fsw	fs7,12(a4)
	
	c.li x0,2
	fsw	fs2,-8(t4)
	addi	a4,a4,16

	fsw	fs1,-4(t4)

	fsw	fa4,-8(a0)

	fsw	fs0,-4(a0)

	bne	t3,a7,.L17
	slli	t5,s6,16

	c.li x0,3
	srli	s6,t5,16
	li	a3,2
	mv	a0,s0

	mv	a1,s6
	call	arm_radix8_butterfly_f32

	c.li x0,4
	lw	a2,4(s3)
	mv	a1,s6
	mv	a0,s1
	li	a3,2

	call	arm_radix8_butterfly_f32
	bne	s5,zero,.L117
	li	s5,1
	beq	s4,s5,.L118
	lw	ra,76(sp)
	lw	s0,72(sp)
	lw	s1,68(sp)
	lw	s6,48(sp)
	lw	s2,64(sp)
	lw	s3,60(sp)
	lw	s4,56(sp)
	lw	s5,52(sp)
	addi	sp,sp,80
	jr	ra
.L12:
	bne	s2,t5,.L96
.L5:
	# Direct radix-8 path for sizes that can run in a single butterfly call.
	# BIG-O: O(fftLen log fftLen)

	c.li x0,4
	lw	a2,4(s3)
	li	a3,1
	mv	a1,s2
	mv	a0,s0

	call	arm_radix8_butterfly_f32
	bne	s5,zero,.L9
	li	s3,1
	bne	s4,s3,.L1
.L124:
	fcvt.s.wu	ft10,s2
	flw	ft11,.LC0,a5
	sw	s1,68(sp)

	c.li x0,2
	addi	s1,s0,8
	fdiv.s	ft1,ft11,ft10

	j	.L11
.L2:
	# Inverse-path preconditioning: conjugate the imaginary lanes before dispatch.
	# BIG-O: O(fftLen)
	addi	a1,a1,4
	beq	s2,zero,.L14
	andi	a3,s2,7
	li	a4,0
	beq	a3,zero,.L15
	beq	a3,a2,.L78
	li	a2,2
	beq	a3,a2,.L79
	li	t0,3
	beq	a3,t0,.L80
	li	t1,4
	beq	a3,t1,.L81
	li	t2,5
	beq	a3,t2,.L82
	li	a0,6
	bne	a3,a0,.L119
.L83:
	c.li x0,3
	flw	ft1,0(a1)
	addi	a4,a4,1
	addi	a1,a1,8

	fneg.s	ft2,ft1
	fsw	ft2,-8(a1)
.L82:
	c.li x0,3
	flw	ft3,0(a1)
	addi	a4,a4,1
	addi	a1,a1,8

	fneg.s	ft4,ft3
	fsw	ft4,-8(a1)
.L81:
	c.li x0,3
	flw	ft5,0(a1)
	addi	a4,a4,1
	addi	a1,a1,8

	fneg.s	ft6,ft5
	fsw	ft6,-8(a1)
.L80:
	c.li x0,3
	flw	ft7,0(a1)
	addi	a4,a4,1
	addi	a1,a1,8

	fneg.s	fs0,ft7
	fsw	fs0,-8(a1)
.L79:
	c.li x0,3
	flw	fs1,0(a1)
	addi	a4,a4,1
	addi	a1,a1,8

	fneg.s	fa0,fs1
	fsw	fa0,-8(a1)
.L78:
	c.li x0,3
	flw	fa1,0(a1)
	addi	a4,a4,1
	addi	a1,a1,8

	fneg.s	fa2,fa1
	fsw	fa2,-8(a1)
	beq	s2,a4,.L16
.L15:
	flw	fa6,0(a1)

	c.li x0,2
	flw	fa7,8(a1)
	fneg.s	fs6,fa6

	flw	fs2,16(a1)

	c.li x0,3
	flw	fs3,24(a1)
	fneg.s	fs7,fa7
	fneg.s	fs8,fs2

	flw	fs4,32(a1)

	c.li x0,3
	flw	fa3,40(a1)
	fneg.s	fs9,fs3
	fneg.s	fs10,fs4

	flw	fa4,48(a1)

	c.li x0,3
	flw	fs5,56(a1)
	fneg.s	fs11,fa3
	fneg.s	ft8,fa4

	c.li x0,3
	fsw	fs6,0(a1)
	fneg.s	ft9,fs5
	addi	a4,a4,8

	fsw	fs7,8(a1)
	fsw	fs8,16(a1)
	fsw	fs9,24(a1)
	fsw	fs10,32(a1)
	fsw	fs11,40(a1)
	fsw	ft8,48(a1)
	fsw	ft9,56(a1)
	addi	a1,a1,64
	bne	s2,a4,.L15
	j	.L16
.L3:
	# Four-way decomposition path for the largest split-radix style FFT sizes.
	# BIG-O: O(fftLen log fftLen)
	srli	t1,s2,1
	slli	a5,t1,2
	sw	s6,48(sp)
	add	s6,s0,a5
	sw	s8,40(sp)
	add	s8,s6,a5
	flw	fs6,0(s8)
	flw	fs7,0(s0)
	sw	s7,44(sp)
	add	s7,s8,a5
	fadd.s	fs9,fs7,fs6
	flw	fs8,0(s7)
	flw	fs10,0(s6)
	flw	fs11,4(s8)
	flw	ft9,4(s0)
	fadd.s	ft11,fs9,fs8
	sw	s1,68(sp)
	sw	s9,36(sp)
	sw	s10,32(sp)
	sw	s11,28(sp)
	fadd.s	ft6,ft11,fs10
	fadd.s	ft8,ft9,fs11
	lw	a2,4(s3)
	flw	fa7,4(s7)
	flw	fa6,4(s6)
	fsub.s	ft10,fs7,fs6
	fsw	ft6,0(s0)
	fsub.s	ft7,ft9,fs11
	flw	fa2,4(s7)
	flw	fa0,4(s6)
	fadd.s	fs4,ft10,fa6
	fadd.s	fa1,ft8,fa2
	fadd.s	ft1,ft7,fs8
	fsub.s	fs3,fs9,fs10
	fsub.s	ft0,ft8,fa6
	fadd.s	ft4,ft10,fa7
	fadd.s	ft3,ft7,fs10
	fadd.s	fs2,fa1,fa0
	fsub.s	ft2,fs4,fa7
	fsub.s	ft5,ft1,fs10
	fsub.s	fs1,fs3,fs8
	fsub.s	fs0,ft0,fa7
	fsub.s	fa4,ft4,fa6
	fsub.s	fa5,ft3,fs8
	fsw	fs2,4(s0)
	fsw	ft2,0(s6)
	fsw	ft5,4(s6)
	srli	a0,t1,1
	fsw	fs1,0(s8)
	fsw	fs0,4(s8)
	srli	s11,t1,2
	addi	a7,s7,-4
	addi	a6,s7,8
	addi	s9,s8,8
	addi	t2,s6,8
	addi	s10,a2,8
	addi	a3,a2,16
	addi	s1,s0,8
	sw	a0,8(sp)
	sw	a6,12(sp)
	fsw	fa4,0(s7)
	fsw	fa5,4(s7)
	add	a5,a7,a5
	mv	t4,s9
	addi	a1,s8,-4
	mv	a4,t2
	addi	t3,s6,-4
	mv	t0,s10
	mv	t6,a3
	addi	a0,s11,-1
	addi	t5,a2,24
	mv	t1,s1
.L19:
	flw	fs8,0(a6)
	flw	fs7,0(a4)

	c.li x0,2
	flw	fs6,0(t4)
	fadd.s	fs11,fs7,fs8

	flw	fs5,0(t1)

	c.li x0,3
	flw	fs10,4(t4)
	fadd.s	fs9,fs5,fs6
	fsub.s	ft10,fs5,fs6

	c.li x0,2
	flw	fa3,4(t1)
	fadd.s	ft11,fs11,fs9

	c.li x0,4
	flw	ft8,4(a6)
	fadd.s	fa7,fa3,fs10
	fsub.s	fa6,fa3,fs10
	addi	t1,t1,8

	c.li x0,4
	flw	ft9,4(a4)
	fsub.s	ft7,fs9,fs7
	fsub.s	ft6,ft10,ft8
	fsub.s	ft0,fa6,fs7

	c.li x0,4
	flw	fs3,4(a6)
	fsub.s	ft1,fa7,ft9
	fsub.s	ft2,ft7,fs8
	fadd.s	fs5,ft6,ft9

	c.li x0,4
	flw	fs4,4(a4)
	fadd.s	ft5,ft0,fs8
	fsub.s	fa0,fa6,fs8
	fsub.s	fs8,ft10,ft9

	c.li x0,3
	flw	fa5,0(a7)
	fadd.s	fa2,fs4,fs3
	addi	t3,t3,-8

	c.li x0,3
	flw	ft3,0(a1)
	fadd.s	fa1,fa2,fa7
	fsub.s	fs6,ft1,ft8

	flw	fs10,0(a5)

	c.li x0,3
	flw	fs9,8(t3)
	fadd.s	ft4,ft3,fs10
	fsub.s	fa4,ft3,fs10

	c.li x0,3
	fsw	ft11,-8(t1)
	fadd.s	fs1,fs9,fa5
	addi	t0,t0,8

	c.li x0,4	
	flw	fs0,-4(a7)
	fadd.s	ft9,fs1,ft4
	addi	a4,a4,8
	fadd.s	ft8,fs8,ft8

	flw	ft11,4(t3)

	c.li x0,4
	fsw	fa1,-4(t1)
	fadd.s	ft10,ft11,fs0
	fsub.s	fa6,fa4,fs0
	fsub.s	fa7,fs1,ft3

	flw	fs11,-4(a5)

	c.li x0,4
	flw	fs2,-4(a1)
	fadd.s	fa3,fs9,fs11
	fadd.s	ft1,fa6,ft11
	fsub.s	fs10,fa7,fs10

	c.li x0,4	
	flw	ft6,-4(a5)
	fsub.s	fs3,ft10,fs2
	fsub.s	fs4,fa3,fa5
	fadd.s	fa5,fa5,fs11

	c.li x0,3
	flw	ft7,-4(a1)
	fsub.s	fa1,fs3,fs11
	fsub.s	ft3,fs4,fs2

	c.li x0,4
	fsw	ft9,8(t3)
	fadd.s	ft0,ft7,ft6
	fsub.s	fs11,fa4,ft11
	fsub.s	ft9,ft4,fs1

	c.li x0,4
	flw	ft11,-8(t0)
	fadd.s	fa2,ft0,ft10
	addi	a1,a1,-8
	addi	t4,t4,8

	c.li x0,3	
	flw	fa4,-4(t0)
	fmul.s	ft4,ft1,ft11
	fmul.s	ft10,ft3,ft11

	c.li x0,4
	fsw	fa2,4(t3)
	fmul.s	fs1,ft5,fa4
	fmul.s	fa3,fs5,fa4
	fmsub.s	fa7,ft3,fa4,ft4

	c.li x0,4
	flw	ft7,0(t6)
	fmadd.s	fa6,ft1,fa4,ft10
	fmadd.s	fs5,fs5,ft11,fs1
	fmsub.s	ft5,ft5,ft11,fa3

	c.li x0,4
	fsw	fs5,-8(a4)
	fadd.s	fs8,fs11,fs0
	fadd.s	fs7,fa0,fs7
	fsub.s	fs2,fa5,fs2

	flw	fs0,4(t6)

	c.li x0,4
	fsw	ft5,-4(a4)
	fmul.s	ft6,fs6,fs0
	fmul.s	fs4,ft2,fs0
	fmul.s	fa0,fa1,fs0

	c.li x0,4
	fsw	fa7,8(a1)
	fmul.s	ft0,fs10,fs0
	addi	a7,a7,-8
	fmadd.s	ft2,ft2,ft7,ft6

	c.li x0,4
	fsw	fa6,4(a1)
	fmsub.s	fs6,fs6,ft7,fs4
	fmsub.s	ft1,ft7,ft9,fa0
	fnmsub.s	fs3,fa1,ft7,ft0

	c.li x0,3
	flw	fs10,4(t5)
	fsub.s	fs9,fs2,fs9
	addi	a6,a6,8

	c.li x0,3
	flw	ft9,0(t5)
	fmul.s	ft3,fs7,fs10
	fmul.s	fa1,ft8,fs10

	c.li x0,4
	fsw	ft2,-8(t4)
	fmul.s	fa5,fs8,ft9
	fmul.s	fs11,fs9,ft9
	addi	a5,a5,-8

	c.li x0,4
	fsw	fs6,-4(t4)
	fmadd.s	fa2,ft8,ft9,ft3
	fmsub.s	ft11,fs7,ft9,fa1
	fmsub.s	ft4,fs9,fs10,fa5

	c.li x0,3
	fsw	ft1,8(a7)
	fmadd.s	fa4,fs8,fs10,fs11
	addi	a0,a0,-1

	c.li x0,3
	fsw	fs3,4(a7)
	addi	t6,t6,16
	addi	t5,t5,24

	fsw	fa2,-8(a6)
	fsw	ft11,-4(a6)
	fsw	ft4,8(a5)
	fsw	fa4,4(a5)

	bne	a0,zero,.L19
	
	c.li x0,2
	lw	a4,12(sp)
	addi	t1,s11,-2

	slli	a0,t1,3

	add	t6,s1,a0

	flw	fs1,8(t6)

	c.li x0,2
	flw	ft5,12(t6)
	addi	t3,a0,8

	add	s9,s9,t3

	c.li x0,3
	flw	ft10,0(s9)
	add	t2,t2,t3
	add	t4,a4,t3
	
	c.li x0,3
	flw	fa6,0(t2)
	fadd.s	fa7,fs1,ft10
	fsub.s	fs0,fs1,ft10

	flw	fs2,0(t4)
	
	c.li x0,4
	flw	fs5,4(s9)
	fadd.s	fs7,fa7,fs2
	fsub.s	ft1,fa7,fa6
	add	a7,s10,a0

	c.li x0,4
	flw	ft8,4(t2)
	fadd.s	fa3,ft5,fs5
	fadd.s	ft7,fs7,fa6
	fsub.s	fs9,ft5,fs5

	c.li x0,4
	flw	fs4,4(t4)
	fadd.s	fs6,fs9,fs2
	fadd.s	ft6,fs0,ft8
	fsub.s	fs3,fa3,ft8
	
	c.li x0,4
	flw	fs8,4(t4)
	fadd.s	ft0,fa3,fs4
	fsub.s	ft3,ft1,fs2
	fsub.s	fs10,fs6,fa6

	c.li x0,4
	flw	ft2,4(t2)
	fsub.s	fa0,ft6,fs8
	fsub.s	fs11,fs3,fs8
	slli	a1,t1,4

	c.li x0,4
	flw	fa1,12(a7)
	fadd.s	ft9,ft0,ft2
	add	t5,a3,a1
	fadd.s	fa5,fs9,fa6

	c.li x0,4
	flw	fa2,8(a7)
	fmul.s	ft11,fs10,fa1
	fmul.s	ft4,fa0,fa1
	fadd.s	fa4,fs0,fs8

	c.li x0,4
	fsw	ft7,8(t6)
	slli	a6,s11,1
	fmsub.s	fs1,fs10,fa2,ft4
	fmadd.s	ft10,fa0,fa2,ft11

	c.li x0,4
	fsw	ft9,12(t6)
	add	s11,a6,s11
	fsub.s	fa7,fa4,ft8
	fsub.s	fs2,fa5,fs2

	c.li x0,4
	flw	fa6,20(t5)
	slli	a5,s11,3
	li	a3,4
	mv	a0,s0

	c.li x0,4
	flw	fs5,16(t5)
	fmul.s	ft5,fs11,fa6
	fmul.s	fs7,ft3,fa6
	add	t1,a2,a5

	c.li x0,3
	fsw	ft10,0(t2)
	fmadd.s	ft8,ft3,fs5,ft5
	fmsub.s	fa3,fs11,fs5,fs7

	fsw	fs1,4(t2)

	lhu	s10,8(sp)

	c.li x0,2
	flw	fs8,4(t1)
	mv	a1,s10

	c.li x0,3
	flw	fs0,0(t1)
	fmul.s	ft7,fs2,fs8
	fmul.s	fs9,fa7,fs8

	c.li x0,3
	fsw	fa3,4(s9)
	fmadd.s	ft6,fa7,fs0,ft7
	fmsub.s	fs4,fs2,fs0,fs9
	
	fsw	ft8,0(s9)
	fsw	ft6,0(t4)
	fsw	fs4,4(t4)
	call	arm_radix8_butterfly_f32

	c.li x0,4
	lw	a2,4(s3)
	mv	a0,s6
	mv	a1,s10
	li	a3,4

	call	arm_radix8_butterfly_f32

	c.li x0,4
	lw	a2,4(s3)
	mv	a0,s8
	mv	a1,s10
	li	a3,4

	call	arm_radix8_butterfly_f32

	c.li x0,4
	lw	a2,4(s3)
	mv	a1,s10
	mv	a0,s7
	li	a3,4

	call	arm_radix8_butterfly_f32
	bne	s5,zero,.L120
	li	a2,1
	beq	s4,a2,.L121
	lw	ra,76(sp)
	lw	s0,72(sp)
	lw	s1,68(sp)
	lw	s6,48(sp)
	lw	s7,44(sp)
	lw	s8,40(sp)
	lw	s9,36(sp)
	lw	s10,32(sp)
	lw	s11,28(sp)
	lw	s2,64(sp)
	lw	s3,60(sp)
	lw	s4,56(sp)
	lw	s5,52(sp)
	addi	sp,sp,80
	jr	ra
.L14:
	beq	a3,zero,.L1
	# Bit-reverse only when the inverse path asked for ordered output.
	# BIG-O: O(fftLen)
	lw	a2,8(a0)

	c.li x0,2
	lhu	a1,12(a0)
	mv	a0,s0

	call	arm_bitreversal_32
.L22:
	fcvt.s.wu	ft0,s2
	flw	fa0,.LC0,a5
	fdiv.s	ft1,fa0,ft0
	beq	s2,zero,.L1
	sw	s1,68(sp)
	addi	s1,s0,8
.L11:
	# Inverse normalization loop scales every complex sample by 1 / fftLen.
	# BIG-O: O(fftLen)
	addi	s4,s2,-1

	c.li x0,2
	andi	s5,s4,7
	li	t4,0

	beq	s5,zero,.L23

	c.li x0,2
	flw	fs3,4(s0)
	li	t4,1

	c.li x0,2
	flw	fs10,0(s0)
	fmul.s	ft9,ft1,fs3

	c.li x0,3
	fsw	ft3,0(s0)
	fmul.s	ft3,fs10,ft1
	fneg.s	fs11,ft9

	fsw	fs11,4(s0)
	mv	s0,s1
	addi	s1,s1,8
	beq	s5,t4,.L23
	li	a0,2
	beq	s5,a0,.L84
	li	t3,3
	beq	s5,t3,.L85
	li	t0,4
	beq	s5,t0,.L86
	li	t6,5
	beq	s5,t6,.L87
	li	a4,6
	bne	s5,a4,.L122
.L88:
	c.li x0,2
	flw	fa4,4(s0)
	addi	t4,t4,1

	c.li x0,2
	flw	ft10,0(s0)
	fmul.s	fs1,ft1,fa4

	fmul.s	fs2,ft10,ft1
	fneg.s	fa7,fs1
	fsw	fs2,0(s0)
	fsw	fa7,4(s0)
	mv	s0,s1
	addi	s1,s1,8
.L87:
	c.li x0,2
	flw	fa6,4(s0)
	addi	t4,t4,1

	c.li x0,2
	flw	fs5,0(s0)
	fmul.s	ft5,ft1,fa6

	fmul.s	fs7,fs5,ft1
	fneg.s	ft8,ft5
	fsw	fs7,0(s0)
	fsw	ft8,4(s0)
	mv	s0,s1
	addi	s1,s1,8
.L86:
	c.li x0,2
	flw	fs8,4(s0)
	addi	t4,t4,1

	c.li x0,2
	flw	fa3,0(s0)
	fmul.s	fs0,ft1,fs8

	fmul.s	ft7,fa3,ft1
	fneg.s	fs9,fs0
	fsw	ft7,0(s0)
	fsw	fs9,4(s0)
	mv	s0,s1
	addi	s1,s1,8
.L85:
	c.li x0,2
	flw	ft6,4(s0)
	addi	t4,t4,1

	c.li x0,2
	flw	fs4,0(s0)
	fmul.s	ft2,ft1,ft6

	fmul.s	fs6,fs4,ft1
	fneg.s	ft0,ft2
	fsw	fs6,0(s0)
	fsw	ft0,4(s0)
	mv	s0,s1
	addi	s1,s1,8
.L84:
	c.li x0,2
	flw	fa0,4(s0)
	addi	t4,t4,1
	
	c.li x0,2
	flw	fs3,0(s0)
	fmul.s	fs10,ft1,fa0

	fmul.s	ft9,fs3,ft1
	fneg.s	ft3,fs10
	fsw	ft9,0(s0)
	fsw	ft3,4(s0)
	mv	s0,s1
	addi	s1,s1,8
	j	.L23
.L123:
	flw	ft10,0(s1)
	flw	fa5,4(s1)

	c.li x0,3
	flw	fs5,12(s1)
	fmul.s	fs2,ft10,ft1
	fmul.s	fa4,ft1,fa5

	flw	fa3,20(s1)
	flw	fs4,28(s1)

	c.li x0,4
	flw	fs3,36(s1)
	fmul.s	ft5,ft1,fs5
	fmul.s	fs0,ft1,fa3
	fmul.s	ft2,ft1,fs4

	flw	fa1,44(s1)
	flw	fs1,8(s1)

	c.li x0,4
	flw	ft10,52(s1)
	fmul.s	fs10,ft1,fs3
	fmul.s	fa2,ft1,fa1
	fmul.s	fa7,fs1,ft1

	flw	ft8,16(s1)
	flw	fs9,24(s1)

	c.li x0,4
	flw	ft0,32(s1)
	fmul.s	fs1,ft1,ft10
	fmul.s	fs8,ft8,ft1
	fmul.s	ft6,fs9,ft1

	flw	ft3,40(s1)

	c.li x0,3
	flw	ft4,48(s1)
	fmul.s	fa0,ft0,ft1
	fmul.s	fs11,ft3,ft1

	c.li x0,4
	fsw	fs2,0(s1)
	fmul.s	fa5,ft4,ft1
	fneg.s	fa6,fa4
	fneg.s	fs7,ft5

	c.li x0,4
	fsw	fa7,8(s1)
	fneg.s	ft7,fs0
	fneg.s	fs6,ft2
	fneg.s	ft9,fs10

	c.li x0,4
	fsw	fa6,4(s1)
	fneg.s	ft11,fa2
	fneg.s	fa4,fs1
	addi	s0,s1,56

	fsw	fs7,12(s1)
	fsw	fs8,16(s1)
	fsw	ft7,20(s1)
	fsw	ft6,24(s1)
	fsw	fs6,28(s1)
	fsw	fa0,32(s1)
	fsw	ft9,36(s1)
	fsw	fs11,40(s1)
	fsw	ft11,44(s1)
	fsw	fa5,48(s1)

	c.li x0,2
	fsw	fa4,4(t2)
	addi	s1,s1,64
.L23:
	# Continue the inverse normalization loop in eight-sample chunks.
	# BIG-O: O(fftLen)
	flw	fs11,4(s0)

	c.li x0,3
	flw	fa1,0(s0)
	addi	a7,t4,1
	fmul.s	fa2,ft1,fs11

	fmul.s	ft11,fa1,ft1

	c.li x0,4
	fsw	ft11,0(s0)
	addi	t2,s1,48
	addi	t4,t4,8
	fneg.s	ft4,fa2

	fsw	ft4,4(s0)
	bne	s2,a7,.L123
	lw	s1,68(sp)
	j	.L1
.L120:
	lw	s1,68(sp)
	lw	s6,48(sp)
	lw	s7,44(sp)
	lw	s8,40(sp)
	lw	s9,36(sp)
	lw	s10,32(sp)
	lw	s11,28(sp)
	j	.L9
.L117:
	lw	s1,68(sp)
	lw	s6,48(sp)
	j	.L9
.L6:
	li	a2,128
	beq	s2,a2,.L7
.L96:
	bne	s5,zero,.L9
	li	s3,1
	bne	s4,s3,.L1
	j	.L124
.L121:
	fcvt.s.wu	ft2,s2
	flw	fs6,.LC0,a5
	lw	s6,48(sp)

	c.li x0,2
	lw	s7,44(sp)
	fdiv.s	ft1,fs6,ft2

	lw	s8,40(sp)
	lw	s9,36(sp)
	lw	s10,32(sp)
	lw	s11,28(sp)
	j	.L11
.L118:
	fcvt.s.wu	fa3,s2
	flw	fs5,.LC0,a5

	c.li x0,3
	lw	s6,48(sp)
	addi	s1,s0,8
	fdiv.s	ft1,fs5,fa3

	j	.L11
.L122:
	flw	fa1,4(s0)

	c.li x0,3
	flw	fa2,0(s0)
	mv	t4,a0
	fmul.s	ft11,ft1,fa1

	c.li x0,2
	fmul.s	ft4,fa2,ft1
	fneg.s	fa5,ft11

	fsw	ft4,0(s0)
	fsw	fa5,4(s0)
	mv	s0,s1
	addi	s1,s1,8
	j	.L88
.L119:
	flw	fa5,0(a1)
	mv	a4,s4
	fneg.s	ft0,fa5
	fsw	ft0,0(a1)
	addi	a1,s0,12
	j	.L83
	.size	arm_cfft_f32, .-arm_cfft_f32
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
.LC0:
	.word	1065353216
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
