#ifndef _SYS_SYSCALL_H
#define _SYS_SYSCALL_H

#include <bits/syscall.h>  /* 从 sysroot 包含编号定义 */

/* 可选：为你的内核定义别名前缀 */
#define HNX_SYSCALL_WRITE __NR_write
#define HNX_SYSCALL_READ  __NR_read
#define HNX_SYSCALL_OPEN  __NR_open
#define HNX_SYSCALL_CLOSE __NR_close
/* ... 其他别名 */

#endif