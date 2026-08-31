# ==============================================================================
# SECTION: Radix-8 Butterfly Engine
# FREQUENCY: Once per arm_radix8_butterfly_f32 call
# BIG-O: O(fftLen log fftLen)
# PURPOSE: Execute the staged radix-8 complex butterflies over the working
#          buffer, starting with the no-twiddle pass and then applying the
#          twiddle-multiplied stages for each remaining stride.
# ==============================================================================
# SOURCE: arm_cfft_radix8_f32.c
# BENCHMARKS: rfft2048_f32 dct4_2048_f32

	.file	"arm_cfft_radix8_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_radix8_butterfly_f32
	.type	arm_radix8_butterfly_f32, @function
arm_radix8_butterfly_f32:
	# Save callee state and seed the stage-control registers.
	# BIG-O: O(1)
	flw	fs3,.LC0,a5
	addi	sp,sp,-112
	addi	a5,a0,8
	sw	s5,88(sp)
	sw	s6,84(sp)
	sw	s7,80(sp)
	sw	s8,76(sp)
	sw	s0,108(sp)
	sw	s1,104(sp)
	sw	s2,100(sp)
	sw	s3,96(sp)
	sw	s4,92(sp)
	sw	s9,72(sp)

	c.li x0,4
	sw	s10,68(sp)
	mv	a4,a0
	mv	s6,a1
	mv	s8,a2

	c.li x0,3
	sw	s11,64(sp)
	mv	s7,a3
	mv	s5,a1

	sw	a5,56(sp)
.L6:
	# Per-stage setup: derive pointer strides for the next radix-8 sweep.
	# BIG-O: O(log fftLen) control overhead across the full transform
	srli	s4,s5,3

	c.li x0,2
	slli	t0,s4,2
	slli	a3,s4,5

	c.li x0,2
	sub	t6,s4,t0
	add	t5,a4,a3

	c.li x0,3
	slli	s2,t6,3
	slli	s10,s4,3
	slli	t1,s4,1

	c.li x0,4
	add	a7,t5,s2
	add	t2,t0,s4
	sub	s0,s10,s4
	add	s1,t1,s4

	c.li x0,4
	add	a6,a7,a3
	slli	s9,t2,3
	slli	s11,s0,3
	slli	t6,s1,4

	c.li x0,4
	add	a0,a6,s2
	slli	t2,s4,4
	mv	t3,t5
	slli	a5,s5,3

	c.li x0,3
	add	a1,a0,a3
	mv	s3,a4
	li	t4,0
	
	add	a2,a1,s2

	add	t0,a2,a3
.L2:
	# First butterfly sweep for this stage, operating over one stride group at a time.
	# BIG-O: O(fftLen) per stage; O(fftLen log fftLen) overall
	
	flw	fa1,0(a2)
	flw	fa0,0(t0)

	c.li x0,2
	flw	ft9,0(s3)
	fadd.s	ft6,fa1,fa0

	flw	fa3,0(t3)
	
	c.li x0,3
	flw	ft0,0(a0)
	fadd.s	fa2,ft9,fa3
	fsub.s	fs4,ft9,fa3

	flw	ft2,0(a1)

	c.li x0,4
	flw	fa5,0(a7)
	fadd.s	fa4,ft0,ft2
	fsub.s	fs5,ft0,ft2
	fsub.s	fs6,ft2,ft0

	c.li x0,4
	flw	ft1,0(a6)
	fadd.s	ft4,fa2,fa4
	fsub.s	fs2,fa2,fa4
	add	t4,t4,s5

	c.li x0,2
	flw	ft11,4(a7)
	fadd.s	ft7,fa5,ft1

	c.li x0,3
	flw	fs9,4(a6)
	fsub.s	ft3,fa5,ft1
	fadd.s	ft5,ft7,ft6

	c.li x0,4
	flw	fs10,4(t3)
	fsub.s	fs0,ft3,fa1
	fsub.s	fs1,ft3,fa0
	fsub.s	fa7,ft4,ft5

	c.li x0,4
	flw	ft9,4(a0)
	fadd.s	fs7,fs0,fa0
	fadd.s	fs8,fs1,fa1
	fadd.s	fa6,ft4,ft5

	c.li x0,3
	flw	ft8,4(s3)
	fsub.s	fs11,ft11,fs9
	fadd.s	ft3,ft11,fs9

	c.li x0,2
	flw	ft0,4(a1)
	fadd.s	fa5,ft8,fs10

	c.li x0,3
	flw	ft10,4(a2)
	fadd.s	ft1,ft9,ft0
	fsub.s	fs9,ft9,ft0

	c.li x0,4
	flw	ft2,4(t0)
	fsub.s	fa1,fs11,ft10
	fsub.s	fa3,fa5,ft1
	fadd.s	fa4,fa5,ft1

	c.li x0,3
	fsw	fa7,0(t3)
	fadd.s	fs0,ft10,ft2
	fsub.s	fa0,fs11,ft2

	c.li x0,4
	fsw	fa6,0(s3)
	fadd.s	fs1,ft3,fs0
	fadd.s	ft11,fa0,ft10
	fsub.s	ft5,fs2,fs0

	c.li x0,4
	fnmsub.s	fa7,fs7,fs3,fs4
	fsub.s	ft8,ft8,fs10
	fsub.s	fa2,fs2,ft3
	fadd.s	fs10,fa1,ft2

	c.li x0,4
	fsub.s	ft4,fa3,ft7
	fsub.s	fs11,ft0,ft9
	fadd.s	fs2,fa4,fs1
	fmadd.s	ft2,ft11,fs3,fs9

	c.li x0,4
	fsw	fs2,4(s3)
	fsub.s	ft0,fa3,ft6
	fsub.s	ft10,fa4,fs1
	fmadd.s	fs4,fs7,fs3,fs4

	c.li x0,4
	fsw	ft10,4(t3)
	fadd.s	fs7,ft5,ft3
	fnmsub.s	ft9,ft11,fs3,fa7
	fnmsub.s	fa6,fs10,fs3,ft8

	c.li x0,4
	fsw	fs7,0(a0)
	fadd.s	ft3,ft4,ft6
	fadd.s	fa5,fa2,fs0
	fmadd.s	fa1,fs8,fs3,fs5

	c.li x0,4
	fsw	fa5,0(a1)
	fmadd.s	fs0,ft11,fs3,fs11
	fmadd.s	fa0,fs10,fs3,ft8
	fadd.s	ft7,ft0,ft7

	c.li x0,4
	fsw	ft3,4(a0)
	fadd.s	ft6,fs4,ft2
	fmadd.s	fs6,fs8,fs3,fs6
	fsub.s	fa4,fs4,ft2

	c.li x0,4
	fsw	ft7,4(a1)
	fadd.s	ft1,fs9,ft9
	fnmsub.s	fs8,fs8,fs3,fa6
	fadd.s	fs1,fa7,fs0

	c.li x0,4
	fsw	ft6,0(a7)
	fsub.s	fa3,fa0,fa1
	fadd.s	ft11,fa1,fa0
	fadd.s	fs9,fa6,fs6

	c.li x0,4
	fsw	fa4,0(t0)
	fadd.s	fs5,fs5,fs8
	add	s3,s3,a5
	add	t3,t3,a5

	fsw	ft1,0(a6)
	fsw	fs1,0(a2)
	fsw	fa3,4(a7)
	fsw	ft11,4(t0)

	c.li x0,4
	fsw	fs9,4(a6)
	add	a0,a0,a5
	add	a1,a1,a5
	add	a7,a7,a5

	c.li x0,4
	fsw	fs5,4(a2)
	add	a6,a6,a5
	add	a2,a2,a5
	add	t0,t0,a5

	bgtu	s6,t4,.L2
	li	a3,7
	bleu	s4,a3,.L1
	# Build the twiddle-pointer lattice for the remaining butterflies in this stage.
	# BIG-O: O(1) per stage
	c.li x0,4
	slli	t1,s7,1
	add	s1,a4,t2
	add	t2,a4,t6
	add	t6,a4,s11

	c.li x0,4
	add	s0,t1,s7
	sub	s2,a4,s2
	add	s10,a4,s10
	addi	t4,t2,8

	c.li x0,4
	sw	t4,48(sp)
	slli	s3,s0,3
	addi	a0,t6,8
	addi	t3,s2,8

	c.li x0,4
	sw	t3,40(sp)
	add	a7,s8,s3
	addi	t5,t5,8
	add	s9,a4,s9

	c.li x0,4
	sw	a0,44(sp)
	addi	s10,s10,8
	addi	s9,s9,8
	addi	s11,s1,8

	c.li x0,4
	sw	t5,52(sp)
	mv	t1,a7
	li	a3,0
	li	a6,1

	li	a1,0
	sw	a4,60(sp)
.L5:
	# Per-twiddle-group setup before walking the twiddled butterflies.
	# BIG-O: O(fftLen / 8) groups per stage
	add	a1,a1,s7

	c.li x0,2
	flw	fs2,0(a7)
	slli	a4,a1,3

	c.li x0,3
	flw	ft0,4(t1)
	add	t3,s8,a4
	slli	s1,a1,4

	c.li x0,3
	flw	ft4,0(t3)
	add	t4,t3,a4
	slli	a2,a1,1
	
	c.li x0,3
	flw	fa7,0(t4)
	add	t5,t4,s1
	add	s0,a2,a1

	c.li x0,3
	flw	fa2,0(t5)
	add	t6,t5,a4
	slli	s2,s0,4
	
	c.li x0,2
	flw	ft8,0(t6)
	add	t0,t6,a4
	
	c.li x0,2
	flw	ft5,0(t0)
	add	t2,t0,a4

	c.li x0,2
	lw	t4,52(sp)
	sub	a2,t2,s2

	c.li x0,2
	lw	t3,56(sp)
	add	s0,a2,a4

	c.li x0,2
	flw	fs7,4(s0)
	add	a0,s0,s1

	c.li x0,2
	flw	fs6,4(a2)
	add	s1,a0,a4
	
	c.li x0,2
	flw	fs5,0(t2)
	add	s2,s1,a4

	c.li x0,4
	lw	t2,48(sp)
	add	a4,s2,a4
	add	t0,t3,a3
	add	t6,t4,a3
	
	lw	a2,40(sp)
	lw	s0,44(sp)
	flw	fs11,4(a4)
	flw	fs10,4(s2)
	flw	fs9,4(s1)
	flw	fs8,4(a0)
	fsw	ft5,36(sp)
	fsw	ft8,32(sp)
	fsw	fa2,28(sp)
	fsw	fa7,20(sp)

	c.li x0,4
	fsw	ft4,16(sp)
	add	t5,s10,a3
	add	t3,s9,a3
	add	s2,s11,a3

	c.li x0,3
	fsw	fs2,24(sp)
	add	a0,t2,a3
	add	t4,a2,a3

	c.li x0,3
	fsw	ft0,12(sp)
	add	a4,s0,a3
	mv	s1,a6
.L4:
	# Main twiddled butterfly loop for the current stage.
	# BIG-O: O(fftLen) per stage; O(fftLen log fftLen) overall
	flw	fa5,0(t5)
	flw	ft3,0(t3)

	c.li x0,4
	flw	fs0,0(t4)
	fadd.s	ft8,fa5,ft3
	fsub.s	fa4,fa5,ft3
	add	s1,s1,s5

	flw	ft7,0(a4)

	c.li x0,3
	flw	fa6,0(s2)
	fadd.s	ft9,fs0,ft7
	fsub.s	fs1,fa4,fs0

	c.li x0,3
	flw	ft10,0(t0)
	fadd.s	fa0,ft8,ft9
	fsub.s	ft11,fa4,ft7

	flw	fs4,0(t6)

	c.li x0,4
	flw	fa3,0(a0)
	fadd.s	fa1,ft10,fs4
	fadd.s	ft3,fs1,ft7
	fadd.s	fa5,ft11,fs0

	c.li x0,3
	flw	ft1,4(t0)
	fadd.s	ft2,fa6,fa3
	fsub.s	ft0,ft10,fs4

	c.li x0,3
	flw	fs2,4(t5)
	fadd.s	ft6,fa1,ft2
	fsub.s	fa2,fa1,ft2

	c.li x0,3	
	flw	fa7,4(t3)
	fadd.s	ft5,ft6,fa0
	fsub.s	ft6,ft6,fa0
	
	fsw	ft5,0(t0)

	c.li x0,3
	flw	ft7,4(s2)
	fsub.s	fa0,fs2,fa7
	fadd.s	ft5,fs2,fa7

	flw	fa4,4(a0)

	c.li x0,3
	flw	fa1,4(t6)
	fadd.s	ft10,ft7,fa4
	fsub.s	fs2,ft7,fa4

	c.li x0,4
	flw	fs4,4(t4)
	fadd.s	ft2,ft1,fa1
	fsub.s	ft1,ft1,fa1
	fsub.s	fa4,fa4,ft7

	c.li x0,4
	flw	fs0,4(a4)
	fsub.s	ft4,fa0,fs4
	fsub.s	fa1,ft2,ft10
	fadd.s	ft2,ft2,ft10

	c.li x0,4
	fadd.s	fa7,fs4,fs0
	fsub.s	fs1,fa0,fs0
	fadd.s	ft4,ft4,fs0
	fsub.s	ft7,fa1,ft8

	c.li x0,4	
	fadd.s	ft11,ft5,fa7
	fadd.s	fa0,fs1,fs4
	fnmsub.s	fs0,ft3,fs3,ft0
	fnmsub.s	fs4,ft4,fs3,ft1

	c.li x0,4
	fsub.s	fs1,fa6,fa3
	fsub.s	fa3,fa3,fa6
	fsub.s	fa6,fa2,fa7
	fsub.s	ft10,ft2,ft11

	c.li x0,4
	fmadd.s	ft4,ft4,fs3,ft1
	fmadd.s	ft3,ft3,fs3,ft0
	fmadd.s	ft1,fa5,fs3,fs1
	fmadd.s	ft0,fa0,fs3,fs2

	c.li x0,4
	fsub.s	fa2,fa2,ft5
	fsub.s	fa1,fa1,ft9
	fmadd.s	fa3,fa5,fs3,fa3
	fadd.s	ft7,ft7,ft9

	c.li x0,4
	fadd.s	fa3,fs4,fa3
	fadd.s	fa6,fa6,ft5
	fnmsub.s	ft9,fa0,fs3,fs0
	fnmsub.s	fa5,fa5,fs3,fs4

	c.li x0,4
	flw	fs4,28(sp)
	fmadd.s	fa4,fa0,fs3,fa4
	fadd.s	fa2,fa7,fa2
	fadd.s	fa7,ft3,ft0

	c.li x0,4
	fsub.s	fa0,ft4,ft1
	fsub.s	ft0,ft3,ft0
	fadd.s	ft1,ft1,ft4
	fmul.s	ft4,fs8,ft10

	c.li x0,4
	fadd.s	fa1,ft8,fa1
	fmul.s	ft3,fs8,ft6
	fadd.s	ft5,ft9,fs2
	fmul.s	ft8,fs7,fa6

	c.li x0,4
	fmul.s	ft9,fs7,ft7
	fmadd.s	ft4,fs4,ft6,ft4
	fmsub.s	ft3,fs4,ft10,ft3
	fadd.s	fa4,fa4,fs0

	c.li x0,4
	flw	fs4,20(sp)
	fmul.s	fs2,fs10,fa2
	fmul.s	fs0,fs10,fa1
	fadd.s	ft2,ft2,ft11

	c.li x0,3
	fsw	ft2,4(t0)
	fmadd.s	ft9,fs4,fa6,ft9
	fmsub.s	ft8,fs4,ft7,ft8

	c.li x0,4
	flw	fs4,36(sp)
	fadd.s	fa5,fs1,fa5
	fmul.s	fs1,fs6,fa0
	fmul.s	ft11,fs6,fa7

	c.li x0,4
	flw	ft2,24(sp)
	fmadd.s	fs0,fs4,fa2,fs0
	fmsub.s	fa1,fs4,fa1,fs2
	fmul.s	ft6,fs11,ft0

	c.li x0,4
	flw	fa2,12(sp)
	fmul.s	ft10,fs11,ft1
	fmul.s	fa6,fs9,fa3
	fmul.s	ft7,fs9,ft5

	c.li x0,4
	flw	fs2,12(sp)
	fmul.s	fa2,fa2,fa5
	fmsub.s	ft1,fs5,ft1,ft6
	fmadd.s	ft0,fs5,ft0,ft10

	c.li x0,2
	flw	fs4,16(sp)
	fmul.s	fs2,fs2,fa4

	c.li x0,3
	fsw	ft4,0(t6)
	fmadd.s	fa7,fs4,fa7,fs1
	fmsub.s	fa0,fs4,fa0,ft11

	c.li x0,3
	flw	fs1,32(sp)
	fmadd.s	fa4,ft2,fa4,fa2
	fmsub.s	fa5,ft2,fa5,fs2

	c.li x0,3
	fsw	ft3,4(t6)
	fmadd.s	ft5,fs1,ft5,fa6
	fmsub.s	fa3,fs1,fa3,ft7

	c.li x0,3
	fsw	ft9,0(s2)
	add	t0,t0,a5
	add	t6,t6,a5

	fsw	ft8,4(s2)
	fsw	fs0,0(a0)
	fsw	fa1,4(a0)
	fsw	fa7,0(t5)
	fsw	fa0,4(t5)

	c.li x0,4
	fsw	ft1,4(a4)
	add	s2,s2,a5
	add	a0,a0,a5
	add	t5,t5,a5

	fsw	ft0,0(a4)
	fsw	ft5,0(t3)
	fsw	fa3,4(t3)
	fsw	fa4,0(t4)
	fsw	fa5,4(t4)

	c.li x0,3
	add	a4,a4,a5
	add	t3,t3,a5
	add	t4,t4,a5

	bgtu	s6,s1,.L4

	c.li x0,4
	addi	a6,a6,1
	add	a7,a7,s3
	add	t1,t1,s3
	addi	a3,a3,8

	bne	s4,a6,.L5
	slli	s7,s7,3

	c.li x0,2
	lw	a4,60(sp)
	slli	s5,s7,16

	c.li x0,2
	srli	s7,s5,16
	mv	s5,s4
	j	.L6
.L1:
	# Restore callee state and return after the final stage.
	# BIG-O: O(1)
	lw	s0,108(sp)
	lw	s1,104(sp)
	lw	s2,100(sp)
	lw	s3,96(sp)
	lw	s4,92(sp)
	lw	s5,88(sp)
	lw	s6,84(sp)
	lw	s7,80(sp)
	lw	s8,76(sp)
	lw	s9,72(sp)
	lw	s10,68(sp)
	lw	s11,64(sp)
	addi	sp,sp,112
	jr	ra
	.size	arm_radix8_butterfly_f32, .-arm_radix8_butterfly_f32
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
.LC0:
	.word	1060439283
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
