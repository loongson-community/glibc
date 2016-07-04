/* Copyright 2016 Loongson Technology Corporation Limited  */

/* Author: Huang Pei huangpei@loongson.cn */

/*
 * ISA: MIPS64R2
 * ABI: N64
 */

/* basic algorithm :

	+.	use ldr for the first 8 bytes or less;

	+.	build a1 with 8c with dins;

	+.	use xor from a1 and v0 to check if is found;

	+.	if (v0 - 0x0101010101010101) & (~(v0 | 0x7f7f7f7f7f7f7f7f)!= 0, v0 has
		one byte is \0, else has no \0

*/

#ifdef _LIBC
#include <sysdep.h>
#include <regdef.h>
#include <sys/asm.h>
#else
#include <sys/asm.h>
#include <sys/regdef.h>
#endif

#define L_ADDIU   PTR_ADDIU
#define L_ADDU   PTR_ADDU
#define L_SUBU   PTR_SUBU

#ifdef LOONGSON_TEST
#define STRCHRNUL	___strchrnul
#else
#define STRCHRNUL	__strchrnul
#endif

/* char * strchrnul (const char *s1, int c); */

LEAF(STRCHRNUL)
	.set	noat
	.set 	push
	.set	mips64r2
	.set	noreorder
	.align	6

	lui	a2, 0x0101
	dins	a1, a1, 8, 8
	ldr	v0, 0(a0)
	andi	t0, a0, 0x7

	ori	a2, 0x0101
	nor	t8, zero, zero
	dins	a1, a1, 16, 16
	sll	t1, t0, 3

	lb	zero, 32(a0)
	dins	a1, a1, 32, 32
	dins	a2, a2, 32, 32
	dsrlv	a7, t8, t1

	nor	t8, a7, zero
	dsll	a3, a2, 7
	or	v1, t8, v0
	and	t3, a7, a1

	nor	a3, a3, zero
	xor	t2, v1, t3
	dsubu	a7, v1, a2
	nor	a6, v1, a3

	dsubu	a5, t2, a2
	nor	a4, t2, a3
	and	a7, a7, a6
	li	t1, 8

	and	a5, a5, a4
	move	a6, a7
	movn	a7, a5, a5
	bnez	a7, L(_mc8_a)

	subu	t1, t1, t0
	L_ADDU	a0, a0, t1
L(_aloop):
	ld	v0, 0(a0)
	L_ADDIU	a0, a0, 8

	xor	t2, v0, a1
	dsubu	a7, v0, a2
	nor	a6, v0, a3
	dsubu	a5, t2, a2

	nor	a4, t2, a3
	and	a7, a7, a6
	and	a5, a5, a4
	move	a6, a7

	movn	a7, a5, a5
	beqz	a7, L(_aloop)
	nop

	L_ADDIU	a0, a0, -8
L(_mc8_a):
	li	a4, 64
	daddiu	t0, a5, -1
	daddiu	t2, a6, -1

	nor	t1, a5, zero
	nor	t3, a6, zero
	and	t0, t0, t1
	and	t2, t2, t3

	dclz	t0, t0
	dclz	t2, t2
	subu	t0, a4, t0
	subu	t2, a4, t2

	srl	t0, t0, 3
	srl	t2, t2, 3
	slt	t1, t0, t2
	movz	t0, t2, t1

	jr	ra
	L_ADDU	v0, a0, t0

END(STRCHRNUL)
	.set	pop

#ifndef ANDROID_CHANGES
#ifdef _LIBC
weak_alias(__strchrnul, strchrnul)
libc_hidden_builtin_def (__strchrnul)
#endif
#endif
