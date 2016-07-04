/* Copyright 2016 Loongson Technology Corporation Limited  */

/* Author: Huang Pei huangpei@loongson.cn */

/*
 * ISA: MIPS64R2
 * ABI: N64
 */

/*
 * algorithm:
 * +.	if both a0 is not 8 bytes aligned and a2 is not long enough to serve a sdr,
 *	jump to _lt8_unaligned;
 *
 * +.	else use sdr to make a0 aligned if a0 is not aligned,
 *
 * +.	if remaining a2 >= 64 bytes, use 64 bytes loop till remaining a2 < 64;
 *
 * +.	if remaining a2 < 64, use sdl from end to start;
 *
 * +.	in _lt8_unaligned, use sb;
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
#define MEMSET	_memset
#define L(x)	x
#else
#define MEMSET	memset
#define L(x)	x
#endif

/* int memset (void * src, int c,  size_t n ); */

LEAF(MEMSET)

	.set	noat
	.set 	push
	.set	arch=mips64r2
	.set	noreorder

	.align	6
	dins	a1, a1, 8, 8
	andi	t1, a0, 0x7
	dins	a1, a1, 16, 16
	subu	t0, zero, t1

	andi	t0, t0, 0x7
	move	v0, a0
	beqz	t1, L(_a0_aligned)
	dins	a1, a1, 32, 32

	sltu	t1, a2, t0
	bnez	t1, L(_lt8_unaligned)
	sltiu	t1, a2, 0x4
	sdr	a1, 0(a0)		/* a2 >= 1 */

	L_ADDU	a0, a0, t0
	L_SUBU	a2, a2, t0
L(_a0_aligned):
	andi	v1, a2, 0x1f
	nop

	beq	v1, a2, L(_lt32_aligned)
	L_SUBU	t0, a2, v1
L(_loop_32B):
	sd	a1, 0(a0)
	sd	a1, 8(a0)

	L_ADDIU	t0, t0, -32
	L_ADDIU	a0, a0, 32
/*
	sd	a1, -48(a0)
	sd	a1, -40(a0)
	sd	a1, -32(a0)
	sd	a1, -24(a0)
*/
	sd	a1, -16(a0)
	bnez	t0, L(_loop_32B)

	sd	a1, -8(a0)
L(_lt32_aligned):
	beqz	v1, L(_out)
	andi	t1, v1, 0x7
	li	t2, 8

	L_ADDU	t0, a0, v1
	movz	t1, t2, t1
L(_loop_8B):
	sdl	a1, -1(t0)
	L_SUBU	t0, t0, t1

	bne	t0, a0, L(_loop_8B)
	li	t1, 8
	jr	ra
	nop

L(_loop_1B):
	beq	a0, v1, L(_out)
	L_ADDIU	a0, a0, 1
	b	L(_loop_1B)
	sb	a1, -1(a0)

L(_lt8_unaligned):
	bnez	t1, L(_loop_1B)
	L_ADDU	v1, a0, a2
	swl	a1, -1(v1)
	swr	a1, 0(a0)
L(_out):
	jr	ra
	nop

END(MEMSET)
	.set	pop

#ifndef ANDROID_CHANGES
#ifdef _LIBC
libc_hidden_builtin_def (memset)
#endif
#endif
