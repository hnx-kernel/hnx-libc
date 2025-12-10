#include <unistd.h>

void _start() {
    const char msg[] = "Hello from HNX libc!\n";
    write(1, msg, sizeof(msg) - 1);
    
    // TODO: Replace with exit() once implemented
    while (1) {}
}
