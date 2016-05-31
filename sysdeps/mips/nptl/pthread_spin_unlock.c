/* pthread_spin_unlock -- unlock a spin lock.  Generic version.
   Copyright (C) 2003 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Paul Mackerras <paulus@au.ibm.com>, 2003.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include "pthreadP.h"
#include <atomic.h>

int
__pthread_spin_unlock (pthread_spinlock_t *lock)
{
  /* atomic_full_barrier (); */
  /* *lock = 0; */
  unsigned int tmp;
  asm volatile (".set mips64 \n\t"
		"1:	\n\t"
		"sync	\n\t"
		"ll	%1, %2\n\t"
		"movn	%1, $0, %1\n\t"
		"sc	%1, %0\n\t"
		"beqz	%1, 1b\n\t"
		".set mips0	\n\t"
		: "=m" (*lock), "=r" (tmp)
		: "m" (*lock)
		: "memory");
  return 0;
}
weak_alias (__pthread_spin_unlock, pthread_spin_unlock)
