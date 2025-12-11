/* System call entry point - aarch64 */
.text
.global __syscall
.hidden __syscall

/* long __syscall(long number, ...); */
__syscall:
    mov x8, x0
    mov x0, x1
    mov x1, x2
    mov x2, x3
    mov x3, x4
    mov x4, x5
    svc #0
    ret

.Linvalid_syscall:
    mov x0, #-38
    ret
