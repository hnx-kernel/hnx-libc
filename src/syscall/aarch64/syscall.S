// src/syscall/aarch64/syscall.S
.text
.global __syscall
.hidden __syscall

// long __syscall(long number, ...);
// 参数按顺序存放在 x0, x1, x2, x3, x4, x5 寄存器中，系统调用号在 x0。
__syscall:
    svc #0          // 触发系统调用或陷入你的内核
    ret