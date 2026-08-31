# ==============================================================================
# SECTION: DCT4 Pre/Post Twiddle Pipeline
# FREQUENCY: Once per arm_dct4_f32 call
# BIG-O: O(N log N)
# PURPOSE: Scale and weight the inline buffer, reshape it into the mirrored
#          layout expected by the real FFT, then post-rotate and reconstruct
#          the final DCT4 samples from the transformed state.
# ==============================================================================
# SOURCE: arm_dct4_f32.c
# BENCHMARKS: dct4_512_f32 dct4_2048_f32

	.file	"arm_dct4_f32.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_dct4_f32
	.type	arm_dct4_f32, @function
arm_dct4_f32:
	# Prologue plus helper-kernel setup for the pre-scale and cosine weighting work.
	# BIG-O: O(1) locally; followed by O(N) helper calls
	addi	sp,sp,-32
	lhu	a3,0(a0)
	sw	s3,12(sp)
	mv	s3,a1
	lw	a1,.LC0
	sw	s0,24(sp)
	mv	s0,a0
	mv	a0,a2
	sw	ra,28(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	mv	s1,a2
	sw	s4,8(sp)
	lw	s2,8(s0)
	lw	s4,12(s0)
	# Pre-scale the inline buffer, then multiply by the cosine factors.
	# BIG-O: O(N)
	call	arm_scale_f32
	c.li x0,4
	lhu	a3,0(s0)
	mv	a1,s4
	mv	a2,s1
	mv	a0,s1
	call	arm_mult_f32

	c.li x0,2
	lhu	a6,0(s0)
	mv	a5,s1

	c.li x0,2
	lhu	t6,2(s0)
	slli	a4,a6,2

	c.li x0,3
	addi	t0,a4,-4
	andi	a1,t6,7
	mv	a3,s3

	add	t5,s3,t0

	beq	a1,zero,.L2
	li	a0,1
	beq	a1,a0,.L118
	li	t1,2
	beq	a1,t1,.L119
	li	t2,3
	beq	a1,t2,.L120
	li	a7,4
	beq	a1,a7,.L121
	li	t3,5
	beq	a1,t3,.L122
	li	t4,6
	bne	a1,t4,.L163
.L123:
	# Tail interleave for the mirrored state layout consumed by the RFFT.
	# BIG-O: O(1)
	c.li x0,2
	flw	ft1,0(a5)
	addi	a3,a3,4

	c.li x0,2
	fsw	ft1,-4(a3)
	addi	a5,a5,8

	c.li x0,3
	flw	ft2,-4(a5)
	addi	t6,t6,-1
	addi	t5,t5,-4

	fsw	ft2,4(t5)
.L122:
	c.li x0,2
	flw	ft3,0(a5)
	addi	a3,a3,4

	c.li x0,2
	fsw	ft3,-4(a3)
	addi	a5,a5,8

	c.li x0,3
	flw	ft4,-4(a5)
	addi	t6,t6,-1
	addi	t5,t5,-4

	fsw	ft4,4(t5)
.L121:
	c.li x0,2
	flw	ft5,0(a5)
	addi	a3,a3,4

	c.li x0,2
	fsw	ft5,-4(a3)
	addi	a5,a5,8

	c.li x0,3
	flw	ft6,-4(a5)
	addi	t6,t6,-1
	addi	t5,t5,-4

	fsw	ft6,4(t5)
.L120:
	c.li x0,2
	flw	ft7,0(a5)
	addi	a3,a3,4
	
	c.li x0,2
	fsw	ft7,-4(a3)
	addi	a5,a5,8

	c.li x0,3
	flw	fs0,-4(a5)
	addi	t6,t6,-1
	addi	t5,t5,-4

	fsw	fs0,4(t5)
.L119:
	c.li x0,2
	flw	fs1,0(a5)
	addi	a3,a3,4

	c.li x0,2
	fsw	fs1,-4(a3)
	addi	a5,a5,8

	c.li x0,3
	flw	fa0,-4(a5)
	addi	t6,t6,-1
	addi	t5,t5,-4
	fsw	fa0,4(t5)
.L118:
	flw	fa1,0(a5)

	c.li x0,3
	fsw	fa1,0(a3)
	addi	a5,a5,8
	addi	t5,t5,-4

	c.li x0,3
	flw	fa2,-4(a5)
	addi	t6,t6,-1
	addi	a3,a3,4

	fsw	fa2,4(t5)
	beq	t6,zero,.L160
.L2:
	# Main interleave loop: write the front half forward and the back half backward.
	# BIG-O: O(N)
	c.li x0,3
	flw	fa3,0(a5)
	addi	a3,a3,32
	addi	a5,a5,64

	fsw	fa3,-32(a3)

	c.li x0,3
	flw	fa4,-60(a5)
	addi	t5,t5,-32
	addi	t6,t6,-8

	fsw	fa4,32(t5)
	flw	fa6,-56(a5)
	fsw	fa6,-28(a3)
	flw	fa7,-52(a5)
	fsw	fa7,28(t5)
	flw	fs2,-48(a5)
	fsw	fs2,-24(a3)
	flw	fs3,-44(a5)
	fsw	fs3,24(t5)
	flw	fs4,-40(a5)
	fsw	fs4,-20(a3)
	flw	fs5,-36(a5)
	fsw	fs5,20(t5)
	flw	fs6,-32(a5)
	fsw	fs6,-16(a3)
	flw	fs7,-28(a5)
	fsw	fs7,16(t5)
	flw	fs8,-24(a5)
	fsw	fs8,-12(a3)
	flw	fs9,-20(a5)
	fsw	fs9,12(t5)
	flw	fs10,-16(a5)
	fsw	fs10,-8(a3)
	flw	fs11,-12(a5)
	fsw	fs11,8(t5)
	flw	ft8,-8(a5)
	fsw	ft8,-4(a3)
	flw	ft9,-4(a5)
	fsw	ft9,4(t5)
	bne	t6,zero,.L2
.L160:
	c.li x0,4
	andi	s4,a6,7
	mv	t4,s1
	mv	a4,s3
	addi	t0,a6,-1

	beq	s4,zero,.L3
	li	a1,1
	beq	s4,a1,.L124
	li	a0,2
	beq	s4,a0,.L125
	li	t1,3
	beq	s4,t1,.L126
	li	t2,4
	beq	s4,t2,.L127
	li	a7,5
	beq	s4,a7,.L128
	li	t3,6
	bne	s4,t3,.L164
.L129:
	# Tail copy-back from the state buffer into the contiguous inline buffer.
	# BIG-O: O(1)
	flw	ft11,0(a4)

	c.li x0,4
	fsw	ft11,0(t4)
	addi	t4,t4,4
	addi	a6,a6,-1
	addi	a4,a4,4
.L128:
	c.li x0,3
	flw	fa5,0(a4)
	addi	a6,a6,-1
	addi	a4,a4,4

	c.li x0,2
	fsw	fa5,0(t4)
	addi	t4,t4,4
.L127:
	c.li x0,3
	flw	ft0,0(a4)
	addi	a6,a6,-1
	addi	a4,a4,4

	c.li x0,2
	fsw	ft0,0(t4)
	addi	t4,t4,4
.L126:
	c.li x0,3
	flw	ft1,0(a4)
	addi	a6,a6,-1
	addi	a4,a4,4

	c.li x0,2
	fsw	ft1,0(t4)
	addi	t4,t4,4
.L125:
	c.li x0,3
	flw	ft2,0(a4)
	addi	a6,a6,-1
	addi	a4,a4,4

	c.li x0,2
	fsw	ft2,0(t4)
	addi	t4,t4,4
.L124:
	c.li x0,3
	flw	ft3,0(a4)
	addi	a6,a6,-1
	addi	a4,a4,4

	c.li x0,2
	fsw	ft3,0(t4)
	addi	t4,t4,4
	
	beq	a6,zero,.L159
.L3:
	# Main copy-back loop: stream eight reordered samples per iteration.
	# BIG-O: O(N)
	c.li x0,2
	flw	ft4,0(a4)
	addi	t4,t4,32

	c.li x0,2
	fsw	ft4,-32(t4)
	addi	a4,a4,32

	c.li x0,2
	flw	ft5,-28(a4)
	addi	a6,a6,-8

	fsw	ft5,-28(t4)
	flw	ft6,-24(a4)
	fsw	ft6,-24(t4)
	flw	ft7,-20(a4)
	fsw	ft7,-20(t4)
	flw	fs0,-16(a4)
	fsw	fs0,-16(t4)
	flw	fs1,-12(a4)
	fsw	fs1,-12(t4)
	flw	fa0,-8(a4)
	fsw	fa0,-8(t4)
	flw	fa1,-4(a4)
	fsw	fa1,-4(t4)
	bne	a6,zero,.L3
.L159:
	# Run the real FFT over the reshaped state buffer.
	# BIG-O: O(N log N)
	c.li x0,4
	lw	a0,16(s0)
	li	a3,0
	mv	a2,s3
	mv	a1,s1

	call	arm_rfft_fast_f32

	c.li x0,2
	lhu	a3,0(s0)
	li	t5,2

	slli	a2,a3,2
	add	t6,s3,a2
	bleu	a3,t5,.L4
	
	c.li x0,2
	addi	a5,a3,-3
	addi	a1,t6,-16

	srli	s4,a5,1

	c.li x0,3
	slli	t0,s4,3
	addi	a5,t6,-8
	addi	a4,t6,8

	sub	a0,a1,t0
	
	sub	t1,a5,a0

	addi	t2,t1,-8

	srli	a7,t2,3

	addi	t3,a7,1

	andi	t4,t3,7
	
	beq	t4,zero,.L5
	li	a6,1
	beq	t4,a6,.L130
	beq	t4,t5,.L131
	li	t5,3
	beq	t4,t5,.L132
	li	a2,4
	beq	t4,a2,.L133
	li	s4,5
	beq	t4,s4,.L134
	li	t0,6
	bne	t4,t0,.L165
.L135:
	# Tail pass that mirrors the upper half and negates the imaginary lanes.
	# BIG-O: O(1)
	c.li x0,3
	flw	fa6,0(a5)
	addi	a4,a4,8
	addi	a5,a5,-8

	flw	fa7,12(a5)

	c.li x0,2
	fsw	fa6,-8(a4)
	fneg.s	fs2,fa7

	fsw	fs2,-4(a4)
.L134:
	c.li x0,3
	flw	fs3,0(a5)
	addi	a4,a4,8
	addi	a5,a5,-8

	flw	fs4,12(a5)

	c.li x0,2
	fsw	fs3,-8(a4)
	fneg.s	fs5,fs4

	fsw	fs5,-4(a4)
.L133:
	c.li x0,3
	flw	fs6,0(a5)
	addi	a4,a4,8
	addi	a5,a5,-8

	flw	fs7,12(a5)

	c.li x0,2
	fsw	fs6,-8(a4)
	fneg.s	fs8,fs7

	fsw	fs8,-4(a4)
.L132:
	c.li x0,3
	flw	fs9,0(a5)
	addi	a4,a4,8
	addi	a5,a5,-8

	flw	fs10,12(a5)

	c.li x0,2
	fsw	fs9,-8(a4)
	fneg.s	fs11,fs10

	fsw	fs11,-4(a4)
.L131:
	c.li x0,3
	flw	ft8,0(a5)
	addi	a4,a4,8
	addi	a5,a5,-8

	flw	ft9,12(a5)

	c.li x0,2
	fsw	ft8,-8(a4)
	fneg.s	ft10,ft9

	fsw	ft10,-4(a4)
.L130:
	c.li x0,3
	flw	ft11,0(a5)
	addi	a5,a5,-8
	addi	a4,a4,8

	flw	fa5,12(a5)

	c.li x0,2
	fsw	ft11,-8(a4)
	fneg.s	ft0,fa5

	fsw	ft0,-4(a4)
	beq	a0,a5,.L4
.L5:
	# Main mirror/negate loop for the complex spectrum post-RFFT.
	# BIG-O: O(N)
	c.li x0,3
	flw	ft1,0(a5)
	addi	a5,a5,-64
	addi	a4,a4,64

	fsw	ft1,-64(a4)
	flw	ft2,68(a5)
	flw	ft5,60(a5)

	c.li x0,3
	flw	ft4,56(a5)
	fneg.s	ft6,ft5
	fneg.s	ft3,ft2
	
	fsw	ft3,-60(a4)
	flw	fa4,36(a5)
	flw	fs0,52(a5)
	flw	fs2,28(a5)
	flw	fa1,44(a5)
	fsw	ft4,-56(a4)
	fsw	ft6,-52(a4)
	flw	ft7,48(a5)

	c.li x0,3
	fsw	ft7,-48(a4)
	fneg.s	fs1,fs0
	fneg.s	fa2,fa1

	fsw	fs1,-44(a4)
	flw	fa0,40(a5)
	fsw	fa0,-40(a4)
	fsw	fa2,-36(a4)
	flw	fa3,32(a5)

	c.li x0,3
	fsw	fa3,-32(a4)
	fneg.s	fa6,fa4
	fneg.s	fs3,fs2

	fsw	fa6,-28(a4)
	flw	fa7,24(a5)
	flw	fs5,20(a5)
	fsw	fa7,-24(a4)
	fsw	fs3,-20(a4)
	flw	fs8,12(a5)
	flw	fs4,16(a5)

	c.li x0,3
	fsw	fs4,-16(a4)
	fneg.s	fs6,fs5
	fneg.s	fs9,fs8

	fsw	fs6,-12(a4)
	flw	fs7,8(a5)
	fsw	fs7,-8(a4)
	fsw	fs9,-4(a4)
	bne	a0,a5,.L5
.L4:
	# Patch the DC/Nyquist endpoints, then apply the complex post-rotation weights.
	# BIG-O: O(N)
	flw	fs10,4(s3)

	c.li x0,4
	sw	zero,4(t6)
	mv	a1,s2
	mv	a2,s3
	mv	a0,s3

	fsw	fs10,0(t6)
	sw	zero,4(s3)

	call	arm_cmplx_mult_cmplx_f32
	flw	ft8,.LC1,a5

	flw	fs11,0(s3)
	addi	a5,s1,4

	c.li x0,3
	lhu	s2,0(s0)
	fmul.s	fa5,fs11,ft8
	addi	a3,s3,8

	addi	a6,s2,-1

	c.li x0,4
	fsw	fa5,0(s1)
	andi	t6,a6,7
	mv	t5,a6
	mv	t4,a5

	beq	t6,zero,.L6
	li	a1,1
	beq	t6,a1,.L136
	li	a0,2
	beq	t6,a0,.L137
	li	t1,3
	beq	t6,t1,.L138
	li	t2,4
	beq	t6,t2,.L139
	li	a7,5
	beq	t6,a7,.L140
	li	t3,6
	bne	t6,t3,.L166
.L141:
	# Tail reconstruction pass for the cumulative-difference output scan.
	# BIG-O: O(1)
	c.li x0,2
	flw	ft10,0(a3)
	addi	t5,t5,-1

	c.li x0,3
	addi	a3,a3,8
	fsub.s	fa5,ft10,fa5
	addi	t4,t4,4

	fsw	fa5,-4(t4)
.L140:
	c.li x0,2
	flw	ft11,0(a3)
	addi	t5,t5,-1

	c.li x0,3
	addi	a3,a3,8
	fsub.s	fa5,ft11,fa5
	addi	t4,t4,4

	fsw	fa5,-4(t4)
.L139:
	c.li x0,2
	flw	ft0,0(a3)
	addi	t5,t5,-1

	c.li x0,3
	addi	a3,a3,8
	fsub.s	fa5,ft0,fa5
	addi	t4,t4,4

	fsw	fa5,-4(t4)
.L138:
	c.li x0,2
	flw	ft1,0(a3)
	addi	t5,t5,-1

	c.li x0,3
	addi	a3,a3,8
	fsub.s	fa5,ft1,fa5
	addi	t4,t4,4

	fsw	fa5,-4(t4)
.L137:
	c.li x0,2
	flw	ft2,0(a3)
	addi	t5,t5,-1

	c.li x0,3
	addi	a3,a3,8
	fsub.s	fa5,ft2,fa5
	addi	t4,t4,4

	fsw	fa5,-4(t4)
.L136:
	c.li x0,2
	flw	ft3,0(a3)
	addi	t4,t4,4

	c.li x0,3
	addi	t5,t5,-1
	fsub.s	fa5,ft3,fa5
	addi	a3,a3,8

	c.li x0,2
	fsw	fa5,-4(t4)
	beq	t5,zero,.L158
.L6:
	# Main reconstruction loop: accumulate prefix differences into DCT4 outputs.
	# BIG-O: O(N)
	c.li x0,4
	flw	ft4,0(a3)
	addi	t4,t4,32
	addi	t5,t5,-8
	addi	a3,a3,64

	c.li x0,2
	flw	ft6,-56(a3)
	fsub.s	ft5,ft4,fa5

	fsw	ft5,-32(t4)

	c.li x0,2
	flw	fs0,-48(a3)
	fsub.s	ft7,ft6,ft5

	fsw	ft7,-28(t4)

	c.li x0,2
	flw	fa0,-40(a3)
	fsub.s	fs1,fs0,ft7

	fsw	fs1,-24(t4)
	
	c.li x0,2
	flw	fa2,-32(a3)
	fsub.s	fa1,fa0,fs1

	fsw	fa1,-20(t4)

	c.li x0,2
	flw	fa4,-24(a3)
	fsub.s	fa3,fa2,fa1

	fsw	fa3,-16(t4)

	c.li x0,2
	flw	fa7,-16(a3)
	fsub.s	fa6,fa4,fa3

	fsw	fa6,-12(t4)

	c.li x0,2
	flw	fs3,-8(a3)
	fsub.s	fs2,fa7,fa6

	fsw	fs2,-8(t4)

	fsub.s	fa5,fs3,fs2
	fsw	fa5,-4(t4)

	bne	t5,zero,.L6
.L158:
	# Tail scalar multiply for the final cosine-weight scaling pass.
	# BIG-O: O(1)
	andi	s3,a6,7
	beq	s3,zero,.L7

	c.li x0,3
	flw	fs4,0(s1)
	li	a2,1
	addi	a6,a6,-1

	c.li x0,2
	flw	fs5,4(s0)
	mv	s1,a5

	c.li x0,2
	fmul.s	fs6,fs5,fs4
	addi	a5,a5,4

	fsw	fs6,-8(a5)
	beq	s3,a2,.L7
	li	s4,2
	beq	s3,s4,.L142
	li	t0,3
	beq	s3,t0,.L143
	li	a4,4
	beq	s3,a4,.L144
	li	s2,5
	beq	s3,s2,.L145
	li	t6,6
	bne	s3,t6,.L167
.L146:
	flw	fs10,0(s1)

	c.li x0,3
	flw	fs11,4(s0)
	mv	s1,a5
	addi	a6,a6,-1

	c.li x0,2
	fmul.s	ft8,fs11,fs10
	addi	a5,a5,4

	fsw	ft8,-8(a5)
.L145:
	flw	ft9,0(s1)

	c.li x0,3
	flw	ft10,4(s0)
	mv	s1,a5
	addi	a6,a6,-1

	c.li x0,2
	addi	a5,a5,4
	fmul.s	ft11,ft10,ft9

	fsw	ft11,-8(a5)
.L144:
	flw	ft0,0(s1)

	c.li x0,3
	flw	ft1,4(s0)
	mv	s1,a5
	addi	a6,a6,-1

	c.li x0,2
	fmul.s	ft2,ft1,ft0
	addi	a5,a5,4

	fsw	ft2,-8(a5)
.L143:
	flw	ft3,0(s1)

	c.li x0,3
	flw	fa5,4(s0)
	mv	s1,a5
	addi	a6,a6,-1

	c.li x0,2
	fmul.s	ft4,fa5,ft3
	addi	a5,a5,4

	fsw	ft4,-8(a5)
.L142:
	flw	ft5,0(s1)

	c.li x0,2
	mv	s1,a5
	addi	a6,a6,-1

	c.li x0,2
	flw	ft6,4(s0)
	addi	a5,a5,4

	c.li x0,2
	flw	fs0,0(s1)
	fmul.s	ft7,ft6,ft5

	fsw	ft7,-8(a5)
	flw	fs1,4(s0)

	c.li x0,2
	addi	a1,a5,28
	fmul.s	fa0,fs1,fs0

	c.li x0,2
	fsw	fa0,-4(a5)
	mv	s1,a1

	beq	a6,zero,.L157
.L168:
	# Main final scaling loop over the reconstructed DCT4 output buffer.
	# BIG-O: O(N)
	flw	fa2,4(s0)
	flw	fa1,0(a5)
	flw	fa6,4(a5)

	c.li x0,3
	flw	fa7,8(a5)
	fmul.s	fs2,fa2,fa1
	addi	a6,a6,-8

	flw	fs3,12(a5)
	flw	fs4,16(a5)
	flw	fa3,20(a5)
	flw	fa4,24(a5)
	fsw	fs2,0(a5)
	flw	fs5,4(s0)

	c.li x0,3
	flw	fs7,4(s0)
	addi	a5,a5,32
	fmul.s	fs6,fs5,fa6

	c.li x0,2
	fsw	fs6,-28(a5)
	fmul.s	fs8,fs7,fa7
	
	flw	fs9,4(s0)

	c.li x0,2
	fsw	fs8,-24(a5)
	fmul.s	fs10,fs9,fs3
	
	flw	fs11,4(s0)

	c.li x0,2
	fsw	fs10,-20(a5)
	fmul.s	ft8,fs11,fs4
	
	flw	ft9,4(s0)

	c.li x0,2
	fsw	ft8,-16(a5)
	fmul.s	ft10,ft9,fa3
	
	flw	ft11,4(s0)

	c.li x0,2
	fsw	ft10,-12(a5)
	fmul.s	ft0,ft11,fa4

	fsw	ft0,-4(a1)
.L7:
	c.li x0,2
	flw	fs0,0(s1)
	addi	a1,a5,28

	c.li x0,2
	flw	fs1,4(s0)
	mv	s1,a1

	fmul.s	fa0,fs1,fs0
	fsw	fa0,-4(a5)
	bne	a6,zero,.L168
.L157:
	# Epilogue after the full DCT4 pipeline completes.
	# BIG-O: O(1)
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	addi	sp,sp,32
	jr	ra
.L163:
	c.li x0,3
	flw	fa5,0(s1)
	addi	a2,t6,-1
	addi	a3,s3,4

	fsw	fa5,0(s3)

	c.li x0,3
	flw	ft0,4(s1)
	addi	a5,s1,8
	mv	t6,a2

	fsw	ft0,0(t5)
	addi	t5,t5,-4
	j	.L123
.L166:
	c.li x0,3
	flw	ft9,0(a3)
	addi	t4,s1,8
	addi	t5,s2,-2

	c.li x0,2
	fsub.s	fa5,ft9,fa5
	addi	a3,s3,16

	fsw	fa5,4(s1)
	j	.L141
.L167:
	flw	fs7,0(s1)

	c.li x0,3
	flw	fs8,4(s0)
	mv	s1,a5
	addi	a6,a6,-1

	c.li x0,2
	fmul.s	fs9,fs8,fs7
	addi	a5,a5,4

	fsw	fs9,-8(a5)
	j	.L146
.L164:
	flw	ft10,0(s3)

	c.li x0,3
	addi	a4,s3,4
	addi	t4,s1,4
	mv	a6,t0
	
	fsw	ft10,0(s1)
	j	.L129
.L165:
	flw	fa2,0(a5)
	fsw	fa2,0(a4)
	flw	fa3,4(a5)
	addi	a5,t6,-16
	fneg.s	fa4,fa3
	fsw	fa4,4(a4)
	addi	a4,t6,16
	j	.L135
	.size	arm_dct4_f32, .-arm_dct4_f32
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
.LC0:
	.word	1073741824
	.align	2
.LC1:
	.word	1056964608
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
