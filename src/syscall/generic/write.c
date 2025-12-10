#include <sys/syscall.h>  /* 包含 __NR_write */
#include <unistd.h>       /* 包含 ssize_t */

extern long __syscall(long number, ...);

ssize_t write(int fd, const void *buf, size_t count) {
    return (ssize_t)__syscall(__NR_write, fd, buf, count);
}