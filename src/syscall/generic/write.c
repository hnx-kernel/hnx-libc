// src/syscall/generic/write.c
#include <sys/syscall.h>
#include <unistd.h>

extern long __syscall(long number, ...);

ssize_t write(int fd, const void *buf, size_t count) {
    // 调用底层通用系统调用函数，传入系统调用号和参数
    return (ssize_t)__syscall(HNX_SYSCALL_WRITE, fd, buf, count);
}