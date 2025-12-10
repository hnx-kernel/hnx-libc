#include <sys/syscall.h>
#include <unistd.h>

extern long __syscall(long number, ...);

ssize_t read(int fd, void *buf, size_t count) {
    return (ssize_t)__syscall(__NR_read, fd, buf, count);
}