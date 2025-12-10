// tests/hello.c
// 包含必要的头文件以获取类型定义
#include <unistd.h>  // 这会提供 ssize_t, size_t 和 write 的声明

// _start 是链接器默认的入口点
void _start() {
    const char msg[] = "Hello from HNX libc!\n";
    
    // 直接调用 write，它会在你的 libhnxc.a 中解析
    write(1, msg, sizeof(msg) - 1);
    
    // 注意：我们还没有实现 exit，所以暂时用死循环
    // 后续实现 exit 后可以改为：exit(0);
    while (1) {
        // 空循环
    }
}