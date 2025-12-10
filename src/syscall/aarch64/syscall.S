/* System call entry point - aarch64 */
.text
.global __syscall
.hidden __syscall

/* long __syscall(long number, ...); */
/* x0=syscall number, x1-x5=arguments */
__syscall:
    /* Validate syscall number (optional) */
    cmp x0, #0
    b.le .Linvalid_syscall
    
    /* Trigger system call */
    svc #0
    ret

.Linvalid_syscall:
    /* Return -ENOSYS */
    mov x0, #-38
    ret