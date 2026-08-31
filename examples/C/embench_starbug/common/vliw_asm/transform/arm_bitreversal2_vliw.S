# ==============================================================================
# SECTION: Bit-Reversal Swap Kernels
# FREQUENCY: Once per bit-reversal pass
# BIG-O: O(bitRevLen)
# PURPOSE: Walk the packed bit-reversal index table and swap complex elements
#          in place, with specialized routines for 64-bit, 32-bit, and 16-bit
#          data layouts.
# ==============================================================================
# SOURCE: arm_bitreversal2.c
# BENCHMARKS: rfft512_f32 rfft2048_f32 dct4_512_f32 dct4_2048_f32

	.file	"arm_bitreversal2.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_c2p0_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16

	.text
	.align	1
	.globl	arm_bitreversal_64
	.type	arm_bitreversal_64, @function
arm_bitreversal_64:
	# Initialize the 64-bit swap loop bounds and detect odd-length alignment work.
	# BIG-O: O(1)
	beq	a1,zero,.L1

	c.li x0,3
	addi	t1,a1,-1
	slli	t2,t0,2
	addi	a3,a2,4

	srli	t0,t1,1

	add	t1,t2,a3

	sub	a5,t1,a2

	addi	a1,a5,-4

	srli	a4,a1,2

	andi	a6,a4,1

	bne	a6,zero,.L3
	# Optional one-off swap to align the packed table before the steady-state loop.
	# BIG-O: O(1)

	c.li x0,2
	lhu	a7,2(a2)
	mv	a2,a3

	c.li x0,2
	lhu	t3,0(a2)
	srli	t4,a7,2

	c.li x0,2
	slli	t5,t4,3
	srli	t6,t3,2

	c.li x0,2
	add	t2,a0,t5
	slli	t0,t6,3

	lw	a3,0(t2)

	c.li x0,4
	lw	a4,4(t2)
	add	a1,a0,t0
	add	t5,a0,t5
	add	t6,a0,t0

	lw	a6,0(a1)
	lw	a7,4(a1)
	sw	a3,0(a1)
	sw	a4,4(a1)
	sw	a6,0(t2)
	sw	a7,4(t2)
	lw	t2,12(t5)
	lw	t0,8(t5)
	lw	a3,8(t6)
	lw	t4,12(t6)
	sw	t0,8(t6)
	sw	t2,12(t6)
	sw	a3,8(t5)
	sw	t4,12(t5)
	beq	t1,a2,.L14
.L3:
	# Main 64-bit swap loop: consume two table entries and swap two complex pairs.
	# BIG-O: O(bitRevLen)
	lhu	a4,2(a2)

	c.li x0,2
	lhu	a1,0(a2)
	srli	a6,a4,2

	c.li x0,3
	lhu	a5,6(a2)
	srli	a7,a1,2
	slli	t0,a6,3

	c.li x0,3
	lw	a4,0(t2)
	slli	t4,a7,3
	add	t2,a0,t0

	c.li x0,2
	lw	a1,4(t2)
	add	t3,a0,t4

	lw	t5,0(t3)
	lw	t6,4(t3)
	sw	a4,0(t3)
	sw	a1,4(t3)
	sw	t5,0(t2)

	c.li x0,2
	sw	t6,4(t2)
	add	t0,a0,t0

	lhu	a4,4(a2)
	lw	a1,8(t0)

	c.li x0,2
	lw	a7,12(t0)
	add	t2,a0,t4

	lw	t3,8(t2)

	c.li x0,2
	lw	t4,12(t2)
	srli	a5,a5,2

	sw	a1,8(t2)

	c.li x0,3
	sw	a7,12(t2)
	slli	t5,a5,3
	srli	t6,a4,2

	sw	t3,8(t0)

	c.li x0,2
	sw	t4,12(t0)
	add	a3,a0,t5

	c.li x0,2
	lw	a6,0(a3)
	slli	t0,t6,3

	c.li x0,2
	lw	t2,4(a3)
	add	a1,a0,t0

	lw	a7,0(a1)
	lw	t3,4(a1)
	sw	a6,0(a1)

	c.li x0,2
	sw	t2,4(a1)
	add	a5,a0,t5

	sw	a7,0(a3)

	c.li x0,2
	sw	t3,4(a3)
	add	t5,a0,t0

	lw	a3,12(a5)
	lw	t6,8(a5)
	lw	t0,8(t5)
	lw	a6,12(t5)
	sw	t6,8(t5)

	c.li x0,2
	sw	a3,12(t5)
	addi	a2,a2,8

	sw	t0,8(a5)
	sw	a6,12(a5)
	bne	t1,a2,.L3
.L1:
	# 64-bit bit-reversal exit.
	# BIG-O: O(1)
	ret
.L14:
	# Aligned single-swap completion exit.
	# BIG-O: O(1)
	ret
	.size	arm_bitreversal_64, .-arm_bitreversal_64
	.align	1
	.globl	arm_bitreversal_32
	.type	arm_bitreversal_32, @function
arm_bitreversal_32:
	# Initialize the 32-bit swap loop bounds and detect odd-length alignment work.
	# BIG-O: O(1)
	beq	a1,zero,.L15

	c.li x0,2
	addi	a6,a1,-1
	addi	a3,a2,4

	srli	t0,a6,1

	slli	t1,t0,2

	add	t2,t1,a3

	sub	a5,t2,a2

	addi	a1,a5,-4

	srli	a4,a1,2

	andi	a7,a4,1

	bne	a7,zero,.L17
	# Optional one-off swap to align the packed table before the steady-state loop.
	# BIG-O: O(1)

	lhu	t3,2(a2)

	c.li x0,2
	lhu	t4,0(a2)
	srli	t5,t3,2

	c.li x0,3
	slli	t6,t5,2
	srli	a6,t4,2
	mv	a2,a3

	c.li x0,2
	add	a3,a0,t6
	slli	t0,a6,2

	c.li x0,2
	lw	t1,0(a3)
	add	a1,a0,t0

	c.li x0,2
	lw	a7,0(a1)
	addi	a5,t6,4

	sw	t1,0(a1)

	c.li x0,2
	sw	a7,0(a3)
	add	t3,a0,a5

	c.li x0,2
	lw	t5,0(t3)
	add	t4,a0,t0

	lw	t6,4(t4)
	sw	t5,4(t4)
	sw	t6,0(t3)
	beq	t2,a2,.L27
.L17:
	# Main 32-bit swap loop: consume two table entries and swap two complex pairs.
	# BIG-O: O(bitRevLen)
	lhu	a6,2(a2)
	lhu	t0,0(a2)
	lhu	a5,6(a2)

	# c.li x0,4
	srli	a3,a6,2
	slli	t4,a3,2
	srli	t1,t0,2
	add	a4,a0,t4

	# c.li x0,2
	slli	a1,t1,2
	lw	t3,0(a4)
	add	a7,a0,a1
	lw	t5,0(a7)
	sw	t3,0(a7)
	add	a6,a0,t4
	sw	t5,0(a4)
	addi	t0,a1,4
	lhu	t1,4(a2)
	lw	t4,4(a6)
	add	a3,a0,t0
	lw	a1,0(a3)
	srli	a5,a5,2
	sw	t4,0(a3)
	slli	t3,a5,2
	srli	a4,t1,2
	sw	a1,4(a6)
	add	t5,a0,t3
	slli	t6,a4,2
	lw	a6,0(t5)
	add	t0,a0,t6
	lw	a7,0(t0)
	sw	a6,0(t0)
	add	t4,a0,t3
	sw	a7,0(t5)
	addi	t1,t6,4
	lw	a1,4(t4)
	add	a5,a0,t1
	lw	t3,0(a5)
	sw	a1,0(a5)
	addi	a2,a2,8
	sw	t3,4(t4)
	bne	t2,a2,.L17
.L15:
	# 32-bit bit-reversal exit.
	# BIG-O: O(1)
	ret
.L27:
	# Aligned single-swap completion exit.
	# BIG-O: O(1)
	ret
	.size	arm_bitreversal_32, .-arm_bitreversal_32
	.align	1
	.globl	arm_bitreversal_16
	.type	arm_bitreversal_16, @function
arm_bitreversal_16:
	# Initialize the 16-bit swap loop bounds and detect odd-length alignment work.
	# BIG-O: O(1)
	beq	a1,zero,.L28

	addi	a3,a1,-1

	c.li x0,2
	srli	t0,a3,1
	addi	a1,a2,4

	slli	t1,t0,2

	add	t2,t1,a1

	sub	a5,t2,a2

	addi	a4,a5,-4

	srli	a6,a4,2

	andi	a7,a6,1

	bne	a7,zero,.L30
	# Optional one-off swap to align the packed table before the steady-state loop.
	# BIG-O: O(1)

	lhu	t3,2(a2)

	c.li x0,3
	lhu	t4,0(a2)
	srli	t5,t3,2
	mv	a2,a1

	c.li x0,2
	slli	t6,t5,1
	srli	a3,t4,2

	c.li x0,2
	add	a1,a0,t6
	slli	t0,a3,1

	c.li x0,2
	lhu	t1,0(a1)
	add	a4,a0,t0

	lhu	a6,0(a4)

	c.li x0,2
	sh	t1,0(a4)
	add	a7,a0,t6

	sh	a6,0(a1)

	c.li x0,2
	lhu	t5,2(a7)
	add	t4,a0,t0

	lhu	t6,2(t4)
	sh	t5,2(t4)
	sh	t6,2(a7)
	beq	t2,a2,.L40
.L30:
	# Main 16-bit swap loop: consume two table entries and swap two complex pairs.
	# BIG-O: O(bitRevLen)
	lhu	a3,2(a2)

	c.li x0,4
	lhu	t0,0(a2)
	addi	a2,a2,8
	srli	a1,a3,2
	add	t3,a0,a5

	c.li x0,2
	slli	a5,a1,1
	srli	t1,t0,2

	c.li x0,3
	lhu	t4,0(t3)
	slli	a4,t1,1
	add	t6,a0,a5

	c.li x0,3
	sh	a7,0(t3)
	add	a6,a0,a4
	add	t0,a0,a4

	lhu	a7,0(a6)
	sh	t4,0(a6)
	lhu	t1,-2(a2)
	lhu	a5,2(t6)

	c.li x0,2
	lhu	a1,2(t0)
	srli	a4,t1,2

	c.li x0,2
	lhu	t3,-4(a2)
	slli	t4,a4,1

	c.li x0, 2
	sh	a5,2(t0)
	add	t5,a0,t4

	c.li x0, 3
	sh	a1,2(t6)
	srli	a6,t3,2
	slli	t6,a6,1
	
	c.li x0,4
	lhu	a3,0(t5)
	add	t0,a0,t6
	add	t1,a0,t4
	add	t3,a0,t6

	lhu	a7,0(t0)
	sh	a3,0(t0)
	sh	a7,0(t5)
	lhu	a4,2(t1)
	lhu	t4,2(t3)
	sh	a4,2(t3)
	sh	t4,2(t1)
	bne	t2,a2,.L30
.L28:
	# 16-bit bit-reversal exit.
	# BIG-O: O(1)
	ret
.L40:
	# Aligned single-swap completion exit.
	# BIG-O: O(1)
	ret
	.size	arm_bitreversal_16, .-arm_bitreversal_16
	.ident	"GCC: (g04696df09) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
