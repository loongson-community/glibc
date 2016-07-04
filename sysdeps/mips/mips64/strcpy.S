/* Copyright 2016 Loongson Technology Corporation Limited  */

/* Author: Huang Pei huangpei@loongson.cn */

/*
 * ISA: MIPS64R2
 * ABI: N64
 */

/*
   for n64 abi

algorithm:

	*.	use (x-0x0101010101010101) & (~(x | 0x7f7f7f7f7f7f7f7f)) != 0 to judge
	if x has zero byte

	*.	adjust a1 to be aligned, and use sdr/sdl 0(a0)/7(a0) to copy data;

	*.	use sb to handle partial dword copy
*/

#ifdef _LIBC
#include <sysdep.h>
#include <regdef.h>
#include <sys/asm.h>
#else
#include <sys/regdef.h>
#include <sys/asm.h>
#endif

#define L_ADDIU   PTR_ADDIU
#define L_ADDU   PTR_ADDU
#define L_SUBU   PTR_SUBU

#ifdef LOONGSON_TEST
#define STRCPY	_strcpy
#else
#define STRCPY	strcpy
#endif

/* char * strcpy (char *s0, const char *s1); */

LEAF(STRCPY)
	.set	noat
	.set 	push
	.set	mips64r2
	.set	noreorder
	.align	4

	andi	v1, a1, 0x7
	nor	t2, zero, zero
	lui	a2, 0x0101
	move	v0, a0

	ldr	t2, 0(a1)
	ori	a2, 0x0101
	li	t3, 8
	dins	a2, a2, 32, 32


	dsll	a3, a2, 7			/* a2 = 0x0101010101010101 */
	beq	v1, zero, L(_a1_aligned)
	nor	a3, a3, zero			/* a3 = 0x7f7f7f7f7f7f7f7f */
	subu	a7, t3, v1

	dsubu	a4, t2, a2
	nor	a5, t2, a3
	and	a4, a5, a4
	L_ADDU	a5, a0, a7

	bne	a4, zero, L(_copy_partial)
	L_ADDU	a1, a1, a7
L(_make_a1_aligned):
	sb	t2, 0(a0)
	L_ADDIU	a0, a0, 1

	bne	a0, a5, L(_make_a1_aligned)
	dsra	t2, t2, 8
L(_a1_aligned):
	ld	t2, 0(a1)
	dsubu	a4, t2, a2

	nor	a5, t2, a3
	and	a4, a4, a5
	bne	a4, zero, L(_copy_partial)
	L_ADDIU	a1, a1, 8

	sdr	t2, 0(a0)
	sdl	t2, 7(a0)
	b	L(_a1_aligned)
	L_ADDIU	a0, a0, 8

L(_copy_partial):
	daddiu	a5, a4, -1
	nor	a7, a4, zero
	and	a5, a7, a5
	li	v1, 64

	dclz	a7, a5
	L_ADDIU	a5, a0, 1
	subu	v1, v1, a7
	srl	v1, v1, 3

	L_ADDU	a5, a5, v1
L(_mloop):
	sb	t2, 0(a0)
	L_ADDIU	a0, a0, 1
	nop

	bne	a0, a5, L(_mloop)
	dsra	t2, t2, 8
	jr	ra
	nop
END(STRCPY)
	.set	pop

#ifndef ANDROID_CHANGES
#ifdef _LIBC
libc_hidden_builtin_def(strcpy)
#endif
#endif
