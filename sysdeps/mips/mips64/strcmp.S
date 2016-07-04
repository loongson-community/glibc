/* Copyright 2016 Loongson Technology Corporation Limited  */

/* Author: Huang Pei huangpei@loongson.cn */

/*
 * ISA: MIPS64R2
 * ABI: N64
 */

/* basic algorithm :

	+.	let t0, t1 point to a0, a1, if a0 has smaller low 3 bit of a0 and a1,
		set a4 to 1 and let t0 point to the larger of lower 3bit of a0 and a1

	+.	if low 3 bit of a0 equal low 3 bit of a0, use a ldr one time and more ld other times;

	+.	if not,  load partial t2 and t3, check if t2 has \0;

	+.	then use use ld for t0, ldr for t1,

	+.	if partial 8 byte  from t1 has \0, compare partial 8 byte from t1 with 8
		byte from t0 with a mask in a7

	+.	if not, ldl other part of t1, compare  8 byte from t1 with 8 byte from t0

	+.	if (v0 - 0x0101010101010101) & (~v0) & 0x8080808080808080 != 0, v0 has
		one byte is \0, else has no \0

	+.	for partial 8 byte from ldr t3, 0(a0), preload t3 with 0xffffffffffffffff


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
#define STRCMP	_strcmp
#define L(x)	x
#else
#define STRCMP	strcmp
#endif

/* int strcmp (const char *s1, const char *s2); */

LEAF(STRCMP)
	.set	noat
	.set 	push
	.set	mips64r2
	.set	noreorder
	.align	4

	andi	v0, a0, 0x7
	andi	v1, a1, 0x7
	nor	t2, zero, zero
	nor	t3, zero, zero

	slt	a4, v0, v1
	lui	a2, 0x0101
	move	t0, a0
	move	t1, a1

	addiu	a2, 0x0101
	move	a5, v0
	dins	a2, a2, 32, 32
	movn	v0, v1, a4

	dsll	a3, a2, 0x7
	movn	t0, a1,	a4
	beqz	v0, L(_aloop)
	nor	a3, a3, zero

	movn	t1, a0, a4
	ldr	t2, 0(t0)
	bne	a5, v1, L(_unaligned)
	ldr	t3, 0(t1)

L(_aligned):
	dins	a0, zero, 0, 3
	dins	a1, zero, 0, 3
	dsubu	v0, t2, a2
	nor	t8, t2, a3

	xor	v1, t2, t3
	xor	a7, t2, t3
	and	t8, t8, v0
	L_ADDIU	a0, a0, 8


	movn	v1, t8, t8
	L_ADDIU	a1, a1, 8
	bnez	v1, L(_mc8_a)
	nop

L(_aloop):
	ld	t2, 0(a0)
	ld	t3, 0(a1)
	L_ADDIU	a0, a0, 8
	L_ADDIU	a1, a1, 8

	dsubu	v0, t2, a2
	nor	t8, t2, a3
	xor	v1, t2, t3
	and	t8, t8, v0

	movn	v1, t8, t8
	xor	a7, t2, t3
	beqz	v1, L(_aloop)
	nop

	b	L(_mc8_a)
L(_unaligned):
	li	a6, 8
	subu	a0, a5, v1
	subu	a1, v1, a5

	dsll	v1, v0, 3
	nor	a7, zero, zero
	movz	a0, a1, a4
	dsubu	a5, t2, a2

	dsrlv	v1, a7, v1
	nor	t8, t2, a3
	xor	a1, t2, t3
	andi	a0, a0, 0x7

	and	t8, t8, a5
	dsll	a5, a0, 3
	and	a0, a1, v1
	subu	a6, a6, v0

	dsrlv	a5, a7, a5
	movn	a0, t8, t8
	L_ADDU	t0, t0, a6
	L_ADDU	t1, t1, a6

	bnez	a0, L(_mc8_a)
	and	a7, a1, v1
	nor	t3, zero, zero
L(_a0_aligned):
	ldr	t3, 0(t1)

	ld	t2, 0(t0)
	L_ADDIU	t0, t0, 8
	dsubu	a1, t3, a2
	nor	t8, t3, a3

	dsubu	v0, t2, a2
	nor	v1, t2, a3
	and	t8, t8, a1
	xor	a1, t2, t3

	bnez	t8, L(_mc8_a)
	and	a7, a1, a5
	and	t8, v1, v0
	ldl	t3, 7(t1)

	xor	v0, t2, t3
	xor	a7, t2, t3
	movn	v0, t8, t8
	L_ADDIU	t1, t1, 8

	beqz	v0,  L(_a0_aligned)
L(_mc8_a):
	li	v1, 64
	daddiu	a6, t8, -1
	nor	t8, t8, zero

	daddiu	a5, a7, -1
	nor	a7, a7, zero
	and	a6, t8, a6
	and	a5, a5, a7

	dclz	a6, a6
	dclz	a5, a5
	subu	v0, v1, a6
	subu	v1, v1, a5

	dins	v0, zero, 0, 3
	dins	v1, zero, 0, 3
	sltu	a5, v1, v0
	movn	v0, v1,	a5

	dsrlv	t2, t2, v0
	dsrlv	t3, t3, v0
	andi	t2, t2, 0xff
	andi	t3, t3, 0xff

	subu	v0, t2, t3
	subu	v1, t3, t2
	jr	ra
	movn	v0, v1, a4

END(STRCMP)
	.set	pop

#ifndef ANDROID_CHANGES
#ifdef _LIBC
libc_hidden_builtin_def (strcmp)
#endif
#endif
