#include <sys/syscall.h>
#include <fcntl.h>

extern long __syscall(long number, ...);

int open(const char *pathname, int flags, ...) {
    // 简化版：忽略可变参数 mode
    return (int)__syscall(__NR_open, pathname, flags, 0);
}