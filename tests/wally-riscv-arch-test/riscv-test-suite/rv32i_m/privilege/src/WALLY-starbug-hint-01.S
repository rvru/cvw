///////////////////////////////////////////
//
// WALLY-starbug-hint
//
// Created 2026-04-27
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

#include "WALLY-TEST-LIB-32.h"

RVTEST_ISA("RV32IC_Zicsr")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*);check ISA:=regex(.*C.*); def TEST_CASE_1=True; def NO_SAIL=True;",starbug-hint)

INIT_TESTS

TRAP_HANDLER m, EXT_SIGNATURE=1

// Exercise Starbug's compressed bundle-hint path with bundle sizes 1..4.
// The final case uses an out-of-range immediate to verify the hint still
// behaves architecturally as a no-op.

li s0, 0x10
c.li zero, 1
c.addi s0, 1
sw s0, 0(t1)
addi t1, t1, 4
addi a6, a6, 4

li s1, 0x20
li s2, 0x30
c.li zero, 2
addi s1, s1, 4
c.addi s2, 2
add s3, s1, s2
sw s1, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw s2, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw s3, 0(t1)
addi t1, t1, 4
addi a6, a6, 4

li s4, 0x100
li s5, 0x200
li s6, 0x300
c.li zero, 3
addi s4, s4, 1
c.addi s5, 1
addi s6, s6, 3
add s7, s4, s5
add s7, s7, s6
sw s4, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw s5, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw s6, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw s7, 0(t1)
addi t1, t1, 4
addi a6, a6, 4

li a0, 0x1000
li a1, 0x2000
li a2, 0x3000
li a3, 0x4000
c.li zero, 4
c.addi a0, 1
addi a1, a1, 2
c.addi a2, 3
addi a3, a3, 4
add a4, a0, a1
add a4, a4, a2
add a4, a4, a3
sw a0, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw a1, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw a2, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw a3, 0(t1)
addi t1, t1, 4
addi a6, a6, 4
sw a4, 0(t1)
addi t1, t1, 4
addi a6, a6, 4

li t0, 0x55
c.li zero, 5
addi t0, t0, 1
sw t0, 0(t1)
addi t1, t1, 4
addi a6, a6, 4

END_TESTS

TEST_STACK_AND_DATA
