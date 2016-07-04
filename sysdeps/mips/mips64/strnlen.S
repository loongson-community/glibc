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
#define STRNLEN	___strnlen
#else
#define STRNLEN	__strnlen
#endif


/* size_t strnlen (const char *s1, size_t maxlen); */

LEAF(STRNLEN)


	.set	noat
	.set 	push
	.set	mips64r2
	.set	noreorder
	.align	4

	move	v0, a1
	beqz	a1, L(_out)
	nor	a1, zero, zero
	lui	a3, 0x0101

	andi	t0, a0, 0x7
	ldr	a1, 0(a0)
	ori	a3, 0x0101
	li	t1, 8

	dins	a3, a3, 32, 32
	move	a2, zero
	subu	t1, t1, t0
	dsll	a4, a3, 7

	nor	a4, a4, zero
	sltu	v1, t1, v0
	dsubu	t2, a1, a3
	nor	t3, a1, a4

	and	t2, t2, t3
	move	a5, t2
	movz	t2, a3, v1
	bnez	t2, L(_count)

	L_ADDU	a0, a0, t1
	L_ADDU	a2, a2, t1
L(_loop):
	ld	a1, 0(a0)
	L_ADDIU	v1, a2, 8

	dsubu	t2, a1, a3
	nor	t3, a1, a4
	sltu	t0, v1, v0
	and	t2, t2, t3

	move	a5, t2
	L_ADDIU	a0, a0, 8
	movz	t2, a3, t0
	nop

	beqzl	t2, L(_loop)
	L_ADDIU	a2, a2, 8
L(_count):
	daddiu	t2, a5, -1
	nor	t3, a5, zero

	and	t2, t2, t3
	li	t1, 64
	dclz	t2, t2
	subu	t1, t1, t2

	srl	t1, t1, 3
	L_ADDU	a2, a2, t1
	sltiu	t2, t1, 8
	sltu	t3, a2, v0

	movz	t3, zero, t2
	nop
	jr	ra
	movn	v0, a2, t3

L(_out):
	jr	ra
	move	v0, zero

END(STRNLEN)
	.set	pop

#ifndef ANDROID_CHANGES
#ifdef _LIBC
libc_hidden_def (__strnlen)
weak_alias (__strnlen, strnlen)
libc_hidden_def (strnlen)
#endif
#endif
