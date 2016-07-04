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

	+.	set a5 to 0 to flag a2 is shorer than the request load from ldr/ld, and use it as a index(minor 1) to byte in the t2/t3, if a5 is 1, igore it by setting a2 to 9;

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
#define STRNCMP	_strncmp
#define L(x)	x
#else
#define STRNCMP	strncmp
#endif

/* int strncmp (const char *s1, const char *s2, size_t n); */

LEAF(STRNCMP)
	.set	noat
	.set 	push
	.set	mips64r2
	.set	noreorder
	.align	5

	beqz	a2,  L(_out)
	lui	a6, 0x0101
	andi	v0, a0, 0x7
	andi	v1, a1, 0x7

	nor	t2, zero, zero
	nor	t3, zero, zero
	ori	a6, 0x0101
	sltu	a4, v0, v1

	move	t0, a0
	move	t1, a1
	dins	a6, a6, 32, 32
	move	a5, v0

	movn	v0, v1, a4
	dsll	a3, a6, 0x7
	movn	t0, a1,	a4
	subu	t9, zero, v0

	movn	t1, a0, a4
	andi	t9, t9, 0x7
	li	AT, 8
	beqz	v0, L(_aloop)

	nor	a3, a3, zero
	ldr	t2, 0(t0)
	bne	a5, v1, L(_unaligned)
	ldr	t3, 0(t1)

L(_aligned):
	L_ADDU	a1, a1, t9
	L_ADDU	a0, a0, t9
	sltu	a5, t9, a2
	dsubu	v0, t2, a6

	nor	t8, t2, a3
	xor	v1, t2, t3
	xor	a7, t2, t3
	and	t8, t8, v0

	movn	v1, t8, t8
	movz	v1, a6, a5
	bnez	v1, L(_mc8_a)
	nop

	L_SUBU	a2, a2, t9
L(_aloop):
	ld	t2, 0(a0)
	ld	t3, 0(a1)
	L_ADDIU	a0, a0, 8

	L_ADDIU	a1, a1, 8
	sltu	a5, AT, a2
	dsubu	v0, t2, a6
	nor	t8, t2, a3

	xor	v1, t2, t3
	and	t8, t8, v0
	xor	a7, t2, t3
	movn	v1, t8, t8

	movz	v1, a6, a5
	beqzl	v1, L(_aloop)
	L_ADDIU	a2, a2, -8
	b	L(_mc8_a)

L(_unaligned):
	subu	a0, a5, v1
	subu	a1, v1, a5
	dsll	v1, v0, 3
	sltu	a5, t9, a2

	nor	a7, zero, zero
	movz	a0, a1, a4
	L_ADDU	t0, t0, t9
	dsubu	a1, t2, a6

	nor	t8, t2, a3
	dsrlv	v1, a7, v1
	andi	a0, a0, 0x7
	and	t8, t8, a1

	xor	a1, t2, t3
	and	v0, a1, v1
	dsll	AT, a0, 3
	movn	v0, t8, t8

	dsrlv	AT, a7, AT
	movz	v0, a6, a5
	bnez	v0, L(_mc8_a)
	and	a7, a1, v1

	L_ADDU	t1, t1, t9
	nor	t3, zero, zero
	li	v0, 8
	L_SUBU	a2, a2, t9

	subu	a0, v0, a0
L(_a0_aligned):
	ldr	t3, 0(t1)
	ld	t2, 0(t0)
	L_ADDIU	t0, t0, 8

	L_ADDIU	t1, t1, 8
	sltu	a5, a0, a2
	dsubu	a1, t3, a6
	nor	t8, t3, a3

	and	v1, t8, a1
	and	t8, t8, a1
	xor	a1, t2, t3
	movz	v1, a6, a5

	and	a7, a1, AT
	bnez	v1, L(_mc8_a)
	nor	v1, t2, a3
	ldl	t3, -1(t1)

	dsubu	a1, t2, a6
	sltu	a5, v0, a2
	and	t8, v1, a1
	xor	a1, t2, t3

	movn	a1, t8, t8
	movz	a1, a6, a5
	beqzl	a1,  L(_a0_aligned)
	L_ADDIU	a2, a2, -8

	xor	a7, t2, t3
L(_mc8_a):
	li	v1, 64
	daddiu	t1, a7, -1
	nor	a7, a7, zero

	daddiu	t0, t8, -1
	nor	t8, t8, zero
	li	a3, 9
	movn	a2, a3, a5

	and	t0, t0, t8
	and	t1, t1, a7
	L_ADDIU	a2, a2, -1
	dclz	t0, t0

	dclz	t1, t1
	sll	a2, a2, 3
	subu	v0, v1, t0
	subu	t1, v1, t1

	dins	v0, zero, 0, 3
	dins	t1, zero, 0, 3
	sltu	t0, t1, v0
	movn	v0, t1,	t0

	sltu	t0, a2, v0
	movn	v0, a2, t0
	dsrlv	t2, t2, v0
	dsrlv	t3, t3, v0

	andi	t2, t2, 0xff
	andi	t3, t3, 0xff
	subu	v0, t2, t3
	subu	v1, t3, t2

	jr	ra
	movn	v0, v1, a4
L(_out):
	jr	ra
	move	v0, zero

END(STRNCMP)
	.set	pop

#ifndef ANDROID_CHANGES
#ifdef _LIBC
libc_hidden_builtin_def (strncmp)
#endif
#endif
