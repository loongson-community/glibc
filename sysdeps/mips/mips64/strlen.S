/* Copyright 2016 Loongson Technology Corporation Limited  */

/* Author: Huang Pei huangpei@loongson.cn */

/*
 * ISA: MIPS64R2
 * ABI: N64
 */
/*
algorithm:

	#.	use ld/ldr to access word/partial word in the string

	#.	use (x - 0x0101010101010101) & (~(x | 0x7f7f7f7f7f7f7f7f) != 0 to
	judge if x has zero byte

	#.	use dctz((x - 0x0101010101010101) & (~(x | 0x7f7f7f7f7f7f7f7f) >> 3
		to get the index of first rightmost zero byte in dword x;

	#.	use dctz(x) = 64 - dclz(~x & (x-1));

	#.	use pointer to the last non zero byte  minus pointer to the start
	of the string to get the length of string

*/

#ifdef _LIBC
#include <sysdep.h>
#include <regdef.h>
#include <sys/asm.h>
#else
#include <regdef.h>
#include <sys/asm.h>
#endif

#define L_ADDIU   PTR_ADDIU
#define L_ADDU   PTR_ADDU
#define L_SUBU   PTR_SUBU

#ifdef LOONGSON_TEST
#define STRLEN	_strlen
#else
#define STRLEN	strlen
#endif


/* size_t strlen (const char *s1); */

LEAF(STRLEN)

	.set	noat
	.set 	push
	.set	mips64r2
	.set	noreorder
	.align	4


	nor	a1, zero, zero
	lui	a2, 0x0101
	andi	v1, a0, 0x7
	lb	zero, 0(a0)

	ldr	a1, 0(a0)
	ori	a2, a2, 0x0101
	nor	t1, a1, zero
	li	a4, 8

	lb	zero, 32(a0)
	dins	a2, a2, 32, 32
	subu	a5, a4, v1
	move	v1, a0

	dsubu	t0, a1, a2
	dsll	a3, a2, 7
	nor	a3, zero, a3
	nor	t1, a1, a3

	and	t0, t0, t1
	bnez	t0, L(_count)	/* instead of use bnel with daddu a0, a0, a5 in branch slot */
	lb	zero, 64(a0)
	L_ADDU	a0, a0, a5

L(_loop):
	ld	a1, 0(a0)
	dsubu	t0, a1, a2
	nor	t1, a1, a3
	and	t0, t0, t1

	beqzl	t0, L(_loop)
	L_ADDIU	a0, a0, 8
L(_count):
/*	if has dctz */
/*	dctz	t1, t0 */
	daddiu	t1, t0, -1
	nor	t2, t0, zero

	and	t1, t2, t1
	li	t3, 64
	dclz	t1, t1
	L_SUBU	v0, a0, v1

	subu	t1, t3, t1
	srl	t1, t1, 3
	jr	ra
	L_ADDU	v0, v0, t1
END(STRLEN)
	.set	pop
#ifndef ANDROID_CHANGES
#ifdef _LIBC
libc_hidden_builtin_def (strlen)
#endif
#endif
